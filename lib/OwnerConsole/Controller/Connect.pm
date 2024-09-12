# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later
    
#XXX Will later be renamed to ConnectConsole::Controller::Connect
package OwnerConsole::Controller::Connect;

#XXX This base-class can do much more than needed for connect, so
#XXX maybe useful to spilt this off, when the connector gets daemonized
#XXX by itself.
use Mojo::Base 'OwnerConsole::Controller';
    
use Log::Report 'open-console-connect';

use OpenConsole::Util       qw(flat :validate new_token true timestamp);

=chapter NAME
OwnerConsole::Controller::Connect - OpenID on steriods

=chapter DESCRIPTION

=chapter METHODS
=section Constructors
=cut

#--------------
=section Action

=method serviceLogin
First step in the OAuth process: the service provider's application connects
to the OAuth provider (us), and get's a session key.
=cut

sub serviceLogin(%)
{	my ($self, %args) = @_;

	#XXX implement REST
}

1;
