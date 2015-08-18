package Harvest::Controller::User;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 auto

Make sure user is authenticated.
If not authenticated, stash (flash) his request and forward to login URL.

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    my $reqpath = $c->request->path;

    #$c->log->info("REQUESTED PATH: $reqpath");

    # Allow unauthenticated users to reach the Login page or GetDisplayInfo page
    # or authenticate over XHR:
    if ($reqpath =~ m{^login$}) {
        return 1;
    }

    if($reqpath =~ m{^user/settings$}) {}
    # Allow /user/JoeUser and /getdisplayinfo
    elsif ( $reqpath =~ m{^user/[a-zA-Z0-9+]+$} || $reqpath =~ m{getdisplayinfo$}) {
        return 1;
    }

    my $xrw = $c->req->header('x-requested-with');
    if ($xrw && lc $xrw eq lc 'XMLHttpRequest') {
        unless ($c->user_exists) {

            $c->session->{requested_path} = $reqpath;
            $c->res->status(401);
            $c->res->body('Authentication required');

            $c->detach;
            return 0;
        }
    }

    unless ($c->user_exists) {

        $c->log->info("No user logged in.");

        $c->log->info('User::auto: unauthenticated user, fwd to /login');
        $c->session->{requested_path} = $reqpath;
        $c->res->redirect($c->uri_for('/login'));
        return 0;
    }
    else {
        $c->log->info("User logged in.");
    }

    return 1;
}

=head2 index

=cut

sub index :Path :Args(1) {
    my ( $self, $c, $user_name ) = @_;

    $user_name =~ tr/+/ /;

    if ($c->user_exists && $c->user->uid eq $user_name) {
        $c->stash->{template} = 'user/index.tt';
    }
    else {
        $c->stash->{template} = 'user/index_public.tt';
    }

    my $user = $c->model('DB::User')->get_public_user_data_by_uid($user_name);

    unless ($user) {
        $c->stash->{template} = 'user/nonexistentuser.tt';
        $c->stash->{user_name} = $user_name;
        $c->detach;
    }

    $c->stash->{user} = $user;
    $c->stash->{rs} = $c->model('DB::Font')->get_user_documents($user->id);
    $c->stash->{favorite_result} = $c->model('DB::Font')->get_user_favorites($user->id); 

    $c->response->header('Cache-Control' => 'no-cache,no-store');
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
