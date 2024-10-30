# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

#### For now, I load this into the OwnerConsole package, until this
#### will run on its own daemons.
#package ConnectConsole;
#use Mojo::Base 'OpenConsole';

package OwnerConsole;

use Log::Report 'open-console-connect';
use ConnectConsole::Model::Connect ();

use feature 'state';

=chapter NAME
ConnectConsole - Open Console login service

=chapter SYNOPSIS

=chapter DESCRIPTION
This module manages Open Console's login service.  For now, it shares the daemons
which run the website, but everything is prepared to run on separate daemons/servers.

=chapter METHODS

=section Constructors
Standard M<Mojo::Base> constructors.

=section Databases

=method connect
Connects to the C<connect> database (M<ConnectConsole::Model::Connect>) which
contains the run-time administration for the connections between external
applications and their users.
=cut

sub connect()
{	my $self = shift;
	state $u = $self->_mango('ConnectConsole::Model::Connect' => 'connectdb');
}

#----------------
=section Running the daemons
=cut

sub _connectRoutes($)
{	my ($self, $r) = @_;
    $r->post('/connect/application/login')->to('connect#appLogin');
    $r->get('/connect/application/logout')->to('connect#appLogout');
	$self;
}

1;
