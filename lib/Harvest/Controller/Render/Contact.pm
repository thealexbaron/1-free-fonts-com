package Harvest::Controller::Render::Contact;
use Moose;
use namespace::autoclean;

use Email::Valid;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Render::Contact - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base
    :Chained
    :PathPart('contact')
    :CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub index :Path 
    :Chained('base')
    :PathPart('')
    :Args(0) {
    my ( $self, $c ) = @_;

	$c->forward('print_form');
}

sub submit_contact :Path 
    :Chained('base')
    :PathPart('submit')
    :Args() {
    my ( $self, $c ) = @_;

	$c->forward('validate_form');
}

sub print_form : Private {
	
	my ($self, $c) = @_;

	$c->stash(
		template => 'render/contact/index.tt',
	);
}

sub validate_form : Local  {
	my ( $self, $c ) = @_;

	my $message;

	my $captcha = $c->req->param('captcha');
		
	unless ( $c->validate_captcha( $captcha ) ) {
	    $message .= '<li>Invalid characters entered for image.</li>';
	}
	
	# Regular Validator
	my $name = $c->req->param('name');
	my $email = $c->req->param('email') || $c->config->{email};
	my $body = $c->req->param('body');

	$c->stash->{body} = $body;
	$c->stash->{source} = $c->req->param('source');
	$c->stash->{name} = $name;
	$c->stash->{email} = $email;

	if (!$name) {
	    $message .= '<li>Please enter your name.</li>';
	}
	
    if (!$email) {
       $message .= "<li>Please enter your email.</li>";
    }

	if ($email) {
        my $email_check = (Email::Valid->address($email) ? 'yes' : 'no');
        if($email_check eq 'no') {
            $message .= '<li>Please enter a valid email.</li>';
        }
	}
	
	if(!$body) {
	    $message .= '<li>Please enter a message.</li>';
	}

	if($message) {
		$c->stash->{message} = $message;
		$c->stash->{name} = $name;
		$c->stash->{email} = $email;
		$c->stash->{body} = $body;
		$c->forward('print_form');
	}
	
	else {
		$c->forward('send_email');
	}
}


sub send_email : Local {
	my ($self, $c) = @_;

    my $to = $c->config->{email};
    my $subject = $c->config->{site_name} . ' Message';
    my $email = $c->stash->{email};

	$c->stash->{user_email} = $email;

    $c->stash->{email} = {
        to      => $c->config->{email},
        from    => $email,
		'Return-Path' => $email,
        subject => $subject,
		template=> 'render/contact/contact.html.tt',
    };
        
    $c->forward( $c->view('Email::Template') );

	if ( scalar( @{ $c->error } ) ) {
        $c->error(0); # Reset the error condition if you need to
        $c->stash->{message} = 'Message was NOT sent successfully.';
 	} 
	else {
        $c->stash->{message} = 'Message sent successfully.';
    }
		
	$c->forward('print_form');

}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
