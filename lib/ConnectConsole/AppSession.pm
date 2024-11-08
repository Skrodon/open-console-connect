# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package ConnectConsole::AppSession;
use Mojo::Base 'OpenConsole::Mango::Object';

use Log::Report 'open-console-connect';

use OpenConsole::Util  qw(new_token timestamp);

=chapter NAME
ConnectConsole::AppSession - temporary access for client applications

=chapter DESCRIPTION
When a client uses Connect to login an application instance, that instance gets a
token which is registered by this object. 

=chapter METHODS

=section Constructors
=cut

sub create($%)
{	my ($class, $insert, %args) = @_;
	$insert->{id}      ||= new_token 'T';
	$insert->{expires} ||= '2027-01-01T00:00:00Z';

	my $service          = delete $insert->{service} or panic;
	$insert->{serviceid} = $service->id;

	my $self = $class->SUPER::create($insert, %args);
	$self;
}

#-------------
=section Attributes
=cut

sub schema()      { '20240912' }
sub set()         { 'appsessions' }
sub element()     { 'appsession'  }

sub serviceId()   { $_[0]->_data->{serviceid} }

=method graceUntil $dt
The application promises to stop using this AppSession token, but wants Open Console
to still accept it until the indicated moment.  For instance, the token could still
be visible on a webpage on some user's browser.
=cut

sub graceUntil($) { $_[0]->setData(expires => timestamp $_[1]) }

=method service $serviceId
Returns the related service object (if it still exists).
=cut

sub service()     { $_[0]->{CA_serv} ||= $::app->assets->service($_[0]->serviceId) }

#------------------
=section Actions
=cut

sub _load($)  { $::app->connect->appSession($_[1]) }
sub _remove() { $::app->connect->removeAppSession($_[0]) }
sub _save()   { $::app->connect->saveAppSession($_[0]) }

1;
