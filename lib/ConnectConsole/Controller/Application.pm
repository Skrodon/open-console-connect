# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later
    
package ConnectConsole::Controller::Application;
use Mojo::Base 'ConnectConsole::Controller';
    
use Log::Report 'open-console-connect';

use HTTP::Status  qw/
	HTTP_BAD_REQUEST
	HTTP_EXPECTATION_FAILED
	HTTP_GONE
	HTTP_NOT_ACCEPTABLE
	HTTP_NOT_FOUND
	HTTP_NOT_IMPLEMENTED
	HTTP_OK
	HTTP_UNAUTHORIZED
	HTTP_UPGRADE_REQUIRED
/;

use OpenConsole::Util       qw(:tokens :time);

=chapter NAME
ConnectConsole::Controller::Application - Manage application logins

=chapter DESCRIPTION

=chapter METHODS

=section Constructors
=cut

#--------------
=section Attributes
=cut

=section Action

=method appLogin
First step in the OAuth process: the service provider's application connects
to the OAuth provider (us), and get's a session key.
=cut

# https://github.com/Skrodon/open-console-connect/wiki/Application-Session#logging-in-for-the-application
sub appLogin(%)
{	my ($self, %args) = @_;

	my $request = $self->req;
	my $auth    = $request->headers->authorization || '';
	my ($token) = $auth =~ m/^Bearer (.{0,100})$/
		or return $self->render(json => {
			ErrorCode => HTTP_NOT_ACCEPTABLE,
			Message   => 'No or wrong authentication.',
		}, status => HTTP_NOT_ACCEPTABLE);

	is_valid_token($token) && token_set($token) eq 'service'
		or return $self->render(json => {
			ErrorCode => HTTP_UNAUTHORIZED,
			Message   => 'Invalid token.',
		}, status => HTTP_UNAUTHORIZED);

	my $payload = $request->json;
 	my $jwt     = $payload->{jwt} || 0;
	if($jwt)
	{	return $self->render(json => {
			ErrorCode => HTTP_NOT_IMPLEMENTED,
			Message   => 'JWT not yet supported',
		}, status => HTTP_NOT_IMPLEMENTED);
	}

	my $service = $::app->assets->service($token)
		or return $self->render(json => {
			ErrorCode => HTTP_NOT_FOUND,
			Message   => 'Service unknown',
		}, status => HTTP_NOT_FOUND);

warn "SERVICE $service";
	my $session = ConnectConsole::AppSession->create({
		service => $service,
		
	});
	$session->save;

	my $site   = $self->config('vhost');

	my %reply  = (
		session => {
			bearer  => $session->id,
			created => $session->created,
			expires => $session->expires,
		},
		service => {
			name => $service->name,
		},
		connect => {
			user_login    => "$site/user/login",
 			refresh_login => "$site/user/refresh",
			user_info     => "$site/user/info",
			owner_website => $self->config('ownersite'),
		},
	);

	$self->render(json => \%reply, status => HTTP_OK);
}

# Check whether the request has a valid appsession token.
sub _appIsLoggedIn($)
{	my ($self, $request) = @_;

	my $auth = $request->headers->authorization || '';
	my ($token) = $auth =~ m/^Bearer (.{0,100})$/;
	unless($token)
	{	$self->render(json => {
			ErrorCode => HTTP_UNAUTHORIZED,
			Message   => 'No authentication. Login first.',
		}, status => HTTP_UNAUTHORIZED);
		return undef;
	}

	if(token_set $token ne 'appsession')
	{	$self->render(json => {
			ErrorCode => HTTP_BAD_REQUEST,
			Message   => 'Wrong type of token used to authenticate.',
		}, status => HTTP_BAD_REQUEST);
		return undef;
	}

	my $session = $::app->batch->appSession($token);
	unless($session)
	{	$self->render(json => {
			ErrorCode => HTTP_GONE,
			Message   => 'Session does not exist anymore',
		}, status => HTTP_GONE);
		return undef;
	}

	if($session->hasExpired)
	{	# This probably should become a redirect to login... however, that's
		# pretty hard to handle client-side.
		$self->render(json => {
			ErrorCode => HTTP_UPGRADE_REQUIRED,
			Message   => 'The session has expired',
		}, status => HTTP_UPGRADE_REQUIRED);
		return undef;
	}

warn "SESSION ", Dumper $session;
	$session;

}

=method appLogout %options
REST implementation for application logout.

REST request parameters:
=over 4
=item C<grace> xsd:Duration (optional)
=back

=cut

# https://github.com/Skrodon/open-console-connect/wiki/Application-Session#log-out-for-the-application

sub appLogout(%)
{	my ($self, %args) = @_;
	my $request = $self->req;
	my $session = $self->_appIsLoggedIn($request) or return;  # error already rendered

	my $config  = $self->config('connect');
	my $grace   = $request->param('grace') || $self->config('logout')->{default_grace};
	my $wait    = duration $grace;
	unless(defined $wait)
	{	$self->render(json => {
			ErrorCode => HTTP_BAD_REQUEST,
			Message   => "Illegal grace period format in '$grace'",
		}, status => HTTP_BAD_REQUEST);
		return undef;
	}
	my $end     = now + $wait;

	$session->graceUntil($end);
	$session->save;

	$self->render(json => {
		grace_end => timestamp $end,
	}, status => HTTP_OK);
}

=method userLogin %options
REST implementation for logging-in a user.  Actions work towards a completely
filled-in "Comply" object for this user on this service.

REST request parameters:
=over 4
=item C<response_type> "code" (required constant string)
=item C<client_id> $app_session_id (required)
=item C<redirect_uri> uri (illegal)
=item C<scope> string (optional)
=item C<state> string (required)
=back

=cut

sub userLogin(%)
{	my ($self, %args) = @_;
	my $request = $self->req;

	my $ownersite = $self->config('ownersite') or panic;

	### Understand the login button
	#!! Login buttons are created by (unexperienced?) application builders, therefore
	#!! we check the parameters carefully.

	my $rt    = $request->param('response_type');
	my $state = $request->param('state');
	my $appid = $request->param('client_id');

	#!!! keep these error in sync with core/templates/connect/errors.html.ep
	my $error = ! $rt                       ? 'A01'
	  : $rt ne 'code'                       ? 'A02'
	  : $request->param('redirect_uri')     ? 'A03'
	  : ! defined $state || ! length $state ? 'A04'
	  : ! $appid                            ? 'A05'
	  : ! is_valid_token $appid             ? 'A06'
	  : token_class $appid ne 'appsession'  ? 'A07'
	  : undef;

	# The connect
	if($error)
	{	# The connect server does not produce webpages
		return $self->redirect($ownersite . "/comply/error?error=$error");
	}

	### Check whether the application instance can still be used
	my ($appsession, $comply);
	if($appsession = $self->connect->appSession($appid))
	{	# User may already be logged-in into Open Console
		my $user_id = $self->session('user');
		$comply = $self->connect->getComply(user => $user_id, service => $appsession->serviceId);
	}

	$error = ! $appsession      ? 'U01'
	  : $appsession->hasExpired ? 'U02'
	  : undef;

	! $error
		or return $self->redirect($ownersite . "/comply/error?error=$error");

	my $scope = $request->param('scope');
}

1;
