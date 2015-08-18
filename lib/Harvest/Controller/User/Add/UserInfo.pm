package Harvest::Controller::User::Add::UserInfo;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::User::Add::UserInfo - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $user_info = {};

    my $bio = $c->req->params->{value};

    if ($bio) {
        $c->user->obj->bio($bio);
        $c->user->obj->update;
        $c->persist_user;
        $user_info->{content} = $bio;
        $user_info->{success} = 1;
    }

    $c->stash(user_info => $user_info);
    $c->view('JSON')->expose_stash('user_info');
    $c->detach('View::JSON');
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
