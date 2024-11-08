# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@open-console.eu>
# SPDX-License-Identifier: EUPL-1.2-or-later

package ConnectConsole::Model::Connect;
use Mojo::Base -base;

use Mango::BSON ':bson';

use ConnectConsole::AppSession  ();
use ConnectConsole::Comply      ();

=chapter NAME
ConnectConsole::Model::Connect - connection administration

=chapter DESCRIPTION
Connect collections: (these should move to a separate database model)
=over 4
=item * 'appsession': connect application sessions
=item * 'comply': use a contract towards an application instance
=back

=chapter METHODS
=cut

has db          => undef;
has appsessions => sub { $_[0]->{OMB_appsess} ||= $_[0]->db->collection('appsession') };
has complies    => sub { $_[0]->{OMB_appsess} ||= $_[0]->db->collection('comply') };

sub upgrade
{	my $self = shift;

	$self->_upgrade_appsessions
		->_upgrade_complies;

	$self;
}

#---------------------
=section Application Session
Keeps track on (connect) logged-in application instances.
=cut

sub _upgrade_appsessions()
{	my $self = shift;
	$self->appsession->ensure_index({ id => 1 }, { unique => bson_true  });
	$self;
}

sub removeAppSession($)
{	my ($self, $id) = @_;
	$self->appsessions->remove({ id => $id });
}

sub saveAppSession($)
{	my ($self, $appsession) = @_;
	$self->appsessions->save($appsession->toDB);
}

sub appSession($)
{	my ($self, $id) = @_;

	my $data = $self->appsessions->find_one({id => $id});
	$data ? ConnectConsole::AppSession->fromDB($data) : undef;
}

#---------------------
=section Comply
Manage
=cut

sub _upgrade_complies()
{	my $self = shift;
	$self->complies->ensure_index({ id => 1 }, { unique => bson_true  });
	$self;
}

sub removeComply($)
{	my ($self, $id) = @_;
	$self->complies->remove({ id => $id });
}

sub saveComply($)
{	my ($self, $comply) = @_;
	$self->complies->save($comply->toDB);
}

sub comply($)
{	my ($self, $id) = @_;

	my $data = $self->complies->find_one({id => $id});
	$data ? ConnectConsole::Comply->fromDB($data) : undef;
}

1;
