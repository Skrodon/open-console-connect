# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later
    
package OwnerConsole::Controller::Connect;

#XXX This base-class can do much more than needed for connect, so
#XXX maybe useful to spilt this off, when the connector gets daemonized
#XXX by itself.
use Mojo::Base 'OwnerConsole::Controller';
    
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

use constant CONNECT_SITE   => 'https://connect-test.open-console.eu';

=chapter NAME
OwnerConsole::Controller::Connect - OpenID on steriods

=chapter DESCRIPTION

=chapter METHODS
=section Constructors
=cut

#--------------
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
	my ($token) = $auth =~ m/^Bearer (.{,100})$/
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

	my %reply = (
		session => {
			bearer  => $session->id,
			created => $session->created,
			expires => $session->expires,
		},
		service => {
			name => $service->name,
		},
		connect => {
			new_grant     => CONNECT_SITE . '',
			refresh_grant => CONNECT_SITE . '',
			userinfo      => CONNECT_SITE . '',
			owner_website => $self->config('vhost'),
		},
	);

	$self->render(json => \%reply, status => HTTP_OK);
}

=method _isLoggedIn
Check whether the request has a valid appsession token.
=cut

sub _isLoggedIn($)
{	my ($self, $request) = @_;

	my $auth = $request->headers->authorization || '';
	my ($token) = $auth =~ m/^Bearer (.{,100})$/;
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

=method appLogout

Parameter: grace=xsd:Duration
=cut

# https://github.com/Skrodon/open-console-connect/wiki/Application-Session#log-out-for-the-application

sub appLogout(%)
{	my ($self, %args) = @_;
	my $request = $self->req;
	my $session = $self->_isLoggedIn($request) or return;  # error already rendered

	my $config  = $self->config('connect');

	my $grace   = $request->param('grace') || $config->{default_logout_grace};
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

1;
