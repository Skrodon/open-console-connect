# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package ConnectConsole::AppSession;
use Mojo::Base 'OpenConsole::Mango::Object';

use Log::Report 'open-console-connect';

use OpenConsole::Util  qw(new_token timestamp);

=chapter NAME
ConnectConsole::AppSession - temporary access for client applications

=chapter DESCRIPTION
When a client uses Connect to 

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

sub schema()      { '20240224' }

sub serviceId()   { $_[0]->_data->{serviceid} }
sub expires()     { $_[0]->_data->{expires} }

sub set()         { 'appsessions' }
sub element()     { 'appsession'  }

sub graceUntil($) { $_[0]->_data->{expires} = $_[1] }   #XXX couchdb: timestamp $_[1]

#------------------
=section Actions
=cut

sub _load($)  { $::app->batch->appSession($_[1]) }
sub _remove() { $::app->batch->removeAppSession($_[0]) }
sub _save()   { $::app->batch->saveAppSession($_[0]) }

1;
