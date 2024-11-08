# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package ConnectConsole;
use Mojo::Base 'OpenConsole';

use Log::Report 'open-console-connect';

use ConnectConsole::Controller     ();
use ConnectConsole::Model::Connect ();

use feature 'state';

=chapter NAME
ConnectConsole - Open Console login service

=chapter SYNOPSIS

  morbo script/connect-console &

=chapter DESCRIPTION
This module manages Open Console's login service.  For now, it shares the daemons
which run the website, but everything is prepared to run on separate daemons/servers.

=chapter METHODS

=section Constructors
Standard M<Mojo::Base> constructors.

=section Databases
=cut

#----------------
=section Running the daemons
=cut

sub startup(@)
{	my $self = shift;
	$self->SUPER::startup(@_);

	my $r = $self->routes;
    $r->post('/application/login')->to('application#appLogin');
    $r->get('/application/logout')->to('application#appLogout');

	$self;
}

1;
