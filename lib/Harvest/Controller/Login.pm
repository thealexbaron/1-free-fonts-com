package Harvest::Controller::Login;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

Index page.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my %error;

    my $xrw = $c->req->header('x-requested-with');

    my $userid = $c->req->params->{userid} || "";
    my $password = $c->req->params->{password} || "";

    if($c->user()) {
        my $user_name = $c->user->uid;
        #my $href = $c->uri_for("/user/$user_name");
        #$c->response->body(qq[You are already logged in as <a href="$href">$user_name</a>.]);
        $c->response->redirect($c->uri_for('/user/' . $user_name));
    }
    elsif ($userid && $password) {
        if ($xrw && lc $xrw eq lc 'XMLHttpRequest') {
            $c->detach('index_xhr');
        }
        else {
            my $authenticated = authenticate_router($c, $userid, $password);
            if ($authenticated) {
                # Path user requested before request was detached or
                # redirected here:
                my $requested = $c->flash->{requested_path};
                if ($requested eq 'login' || $requested eq 'signup') {
                    $c->response->redirect($c->uri_for('/user/' . $c->req->params->{userid}));
                }
                elsif ($requested) {
                    my $msg = "pass-through authentication redirecting back to originally requested resource: $requested";
                    #$c->log->debug($msg);
                    $c->response->redirect($c->uri_for('/' . $requested));
                }
                else {
                    #$c->log->debug('pass-through authentication redirecting to / because no request in flash');
                    $c->response->redirect($c->uri_for('/user/' . $c->req->params->{userid}));
                }
                $c->detach;
            }
            else {
                $c->stash->{error_msg} = "Invalid username or password.";
            }
        }
    }

    $c->detach;
}

=head2 index_xhr

Respond to a request from XMLHttpRequest (AJAX).

=cut

sub index_xhr :Private {
    my ( $self, $c ) = @_;

    my $userid = $c->req->params->{userid} || "";
    my $password = $c->req->params->{password} || "";
    my %error;

    #if ($c->user) {

		#my $user_name = $c->user->uid;
	    #my $href = $c->uri_for("/user/$user_name");
        # XXX this should populate a structure to be sent back as JSON so javascript
        # can display a message
		#$c->response->body(qq[You are already logged in as <a href="$href">$user_name</a>.]);
            #my $string = $c->uri_for('/user/' . $c->req->params->{userid});
            #$error{redirect} = "$string";
            #$error{none} = 1;		

            #}

    my $requested = $c->session->{requested_path} || '';
    if ($userid && $password) {
        my $authenticated = authenticate_router($c, $userid, $password);
        if ($authenticated) {
            
            #warn "REQUESTED PATH-index_xhr: $requested\n";
            if($requested eq 'login' || $requested eq 'signup') {
                $error{redirect} = '/user/' . $c->req->params->{userid};
                $error{none} = 1;
	        }
	        elsif ($requested) {
                $error{redirect} = '/' . $requested;
                $error{none} = 1;
            }
            else {
		        #my $string = $c->uri_for('/user/' . $c->req->params->{userid});
		        my $string = 'reload';
                $error{redirect} = "$string";
                $error{none} = 1;
            }
        }
    else {
		$c->stash->{error} = 'Invalid username or password.';
        $error{login}{error} = $c->stash->{error};
        $error{none} = "error";
    }
    }
    else {
        # what if $userid and $password are false?
    }

    #use Data::Dumper;
    #warn Dumper(\%error);

    $c->stash(data => { error => \%error });
	$c->view('JSON')->expose_stash('data');
    $c->forward($c->view('JSON'));
}

sub authenticate_router {
    my ($c, $userid, $password) = @_;

    my $key_field;

    if($userid  =~ m{@}) {
        $key_field = 'email';
    }
    else {
        $key_field = 'uid';
    }

    $c->authenticate({$key_field => $userid, password => $password});

}


=head2 end


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
