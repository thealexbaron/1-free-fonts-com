package Harvest::Controller::User::Add::Settings;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::User::Add::Settings - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my @fields = qw( account_related newsletter ); 

    foreach my $field (@fields) {
        $c->user->obj->$field($c->req->params->{$field});
        $c->user->obj->update;
        $c->persist_user;
    }

    $c->flash->{settings_updated} = '<b>Success!</b> Your settings have successfully been udpated.';

    #$c->go('/user/settings/index');
    $c->response->redirect("/user/settings", 302);
}

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
