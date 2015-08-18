package Harvest::Controller::Signup;
use Moose;
use namespace::autoclean;

use Digest::SHA qw(sha1_hex);

use Email::Valid;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Signup - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 auto

If user is already authenticated, send them to their profile page.

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    if ($c->user) {
	    my $user_name = $c->user->uid;
        $c->response->redirect($c->uri_for('/user/' . $user_name));
    }

    return 1;
}


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

=head2 submit

Submit user info.

=cut

sub submit :Local {
    my ( $self, $c, @args ) = @_;
	
	validate_signup($self, $c);
	insert_user($self, $c);
    send_email($self, $c);

	my %error;
	$error{error}{none} = 1;
	my $string = $c->uri_for('/user/' . $c->req->params->{username});
	$error{error}{redirect} = "$string";
	$c->stash->{error} = \%error;

	my $userinfo = { 
		uid => $c->req->params->{username}, 
		password => $c->req->params->{password} 
	};

	$c->authenticate($userinfo);

   	$c->view('JSON')->expose_stash('error');

	$c->detach('View::JSON');
	
}

sub validate_signup {
	my ( $self, $c, @args ) = @_;

	my %error;

	# username
	if(!$c->req->params->{username}) {
		$error{error}{username}{empty} = 'Username must not be empty.';
	}
	else {
		if(length($c->req->params->{username}) < 5) {
			$error{error}{username}{'length'} = 'Username must be at least 5 characters.';
		}
		elsif(length($c->req->params->{username}) > 20) {
			$error{error}{username}{'length'} = 'Username must be less than 20 characters.';
		}
		unless($c->req->params->{username} =~ m/^[a-z0-9]+$/) {
			$error{error}{username}{non_alpha_numeric} = 'Username can only be lowercase letters, and numbers.';
		}
		if(search_db_for_user_existence($self, $c, @args)) {
			$error{error}{username}{already_exists} = 'Username already exists.';
		}
		if($c->req->params->{username} =~ m/<(.*?)>/) {
			$error{error}{username}{html} = 'Html is not allowed.';
		}
	}

	# password
	if(!$c->req->params->{password}) {
		$error{error}{password}{empty} = 'Password must not be empty.';
	}
	else {
		if($c->req->params->{password} ne $c->req->params->{retype_password}) {
			$error{error}{retype_password}{password_typo} = 'Passwords are not the same.';
		}		
		if(length($c->req->params->{password}) < 5) {
			$error{error}{password}{'length'} = 'Password must be at least 5 characters.';
		}
		elsif(length($c->req->params->{password}) > 20) {
			$error{error}{password}{'length'} = 'Password must be less than 20 characters.';
		}
	}

	# firstname
	if(!$c->req->params->{firstname}) {
			$error{error}{firstname}{empty} = 'First Name must not be empty.';
	}
	else {
		if($c->req->params->{firstname} =~ m/<(.*?)>/) {
			$error{error}{firstname}{html} = 'Html is not allowed.';
		}
	}

	#lastname
	if(!$c->req->params->{lastname}) {
		$error{error}{lastname}{empty} = 'Last Name must not be empty.';
	}
	else {
		if($c->req->params->{lastname} =~ m/<(.*?)>/) {
			$error{error}{lastname}{html} = 'Html is not allowed.';
		}
	}

	# email
	if(!$c->req->params->{email}) {
			$error{error}{email}{empty} = 'Email must not be empty.';
	}
	else {
		my $email_check = (Email::Valid->address($c->req->params->{email}) ? 'yes' : 'no');
		if($email_check eq 'no') {
				$error{error}{email}{invalid} = 'Email address invalid.';
		}
		if($c->model('DB::User')->check_if_email_exists($c->req->params->{email})) {
			$error{error}{email}{already_exists} = 'Email already exists.';
		}		
	}

	if(keys(%error)) {

		$error{error}{none} = "error";
		$c->stash->{error} = \%error;
    		$c->view('JSON')->expose_stash('error');
		$c->detach('View::JSON');
	}

}

sub insert_user {
	my ( $self, $c, @args ) = @_;

	my $cryptic_password = sha1_hex($c->req->params->{password});
	my $schema = $c->model('DB');

  	my $user_rs = $schema->resultset("User");

  	my ($result) = $user_rs->create(
  	  { 
	   		uid => $c->req->params->{username},
			password => $cryptic_password,
			lastname => $c->req->params->{lastname},
			firstname => $c->req->params->{firstname},
			email => $c->req->params->{email}
	  },
  	);

	unless($result) {
		my %error;
		$error{error}{none} = 'error';
		$error{error}{database}{error} = 'Database error. Please try again.';
		$c->stash->{error} = \%error;

	   	$c->view('JSON')->expose_stash('error');

		$c->detach('View::JSON');
	}
}

sub send_email {
	my ( $self, $c, @args ) = @_;

    my $to = $c->req->params->{email};
    my $subject = $c->req->params->{firstname} . ', Welcome to ' . $c->config->{site_name} . '!';
    my $email = $c->config->{email};

    $c->stash->{email} = {
        to      => $to,
        from    => $email,
		'Return-Path' => $email,
        subject => $subject,
		template=> 'email/welcome.html.tt',
    };
        
    $c->forward( $c->view('Email::Template') );

}

sub check_user_exists :Local {
	my ( $self, $c, @args ) = @_;

	my $user_exists = search_db_for_user_existence($self, $c, @args);

	$c->stash->{data} = {
        user_exists => $user_exists,
    };

    $c->view('JSON')->expose_stash('data');

	$c->forward('View::JSON');

}

sub search_db_for_user_existence {
	my ( $self, $c, @args ) = @_;

	my $schema = $c->model('DB');

	my $uid = $args[0] || $c->req->params->{username};

	my $user_exists = $schema->resultset('User')->single({ uid => $uid });

	if($user_exists) {
		$user_exists = 1;
	}

	return $user_exists;

}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
