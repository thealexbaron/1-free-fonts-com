package Harvest::Controller::JSON;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::JSON - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 like_dislike

Respond to like_dislike request.

=cut

sub like_dislike :Local {
    my ( $self, $c ) = @_;

    my $document_id = $c->req->param('document_id');
    my $vote = $c->req->param('vote');
    my $sess = $c->session;
    my $ld = $c->req->param('like_dislike');
    #my $cache_key = $c->req->param('cache_key');

    my %vars;
    my $row_count;

    if ($sess->{like_dislike}{voted}{$document_id}) {
        $vars{rate_successful} = 0;
        $vars{message_header} = 'Only Vote Once';
        $vars{message_body} = 'You may only vote once per font!';
    }
    else {
		my $schema = $c->model('DB');
		my $like_rs = $schema->resultset("NlikeDislike");

        my $row_count;

		if($vote eq 'like' && $document_id) {
            $row_count = $like_rs->increment_likes($document_id);
        }
        elsif ($vote eq 'dislike' && $document_id) {
            $row_count = $like_rs->increment_dislikes($document_id);
        }
        else {
            $vars{rate_successful} = 0;
            $vars{message_header} = 'Select Rating';
            $vars{message_body} = 'Please either like or dislike.';
        }

        if ($row_count) {

            my $cache_key = "documentblock:$document_id";
			my $delete_status = $c->cache->remove($cache_key);
            # SPHINX index should be refreshed here.
            #warn "Delete Status: $delete_status for key: $cache_key\n";
            $sess->{like_dislike}{voted}{$document_id} = $vote;
            $vars{rate_successful} = 1;
            $vars{message_header} = 'Thank You!';
            $vars{message_body} = 'We appreciate your feedback.';
        }
        else {
            $vars{rate_successful} = 0;
            $vars{message_header} = 'Database Failure';
            $vars{message_body} = 'There was a database error. Try again.';
        }
    }

    my %like_response = (
        rate_successful => $vars{rate_successful},
        message_header => $vars{message_header},
    	message_body => $vars{message_body},
    );

	$c->stash->{like_response} = \%like_response;

	$c->view('JSON')->expose_stash('like_response');
	$c->detach('View::JSON');
}


=head2 favorite

Respond to favorite request.

=cut

sub favorite :Local {
    my ( $self, $c ) = @_;

    my $document_id = $c->req->param('document_id');
	
	my %favorite_response;

	unless($c->user_exists()) {
    	%favorite_response = (
    	    rate_successful => 0,
  	 	    message_header => 'You Must Be logged in.',
 		   	message_body => 'You must be logged in to favorite a font.',
	    );
	}
	else {

    my $cache_key = "documentblock:$document_id";
	my $delete_status = $c->cache->remove($cache_key);

    my %vars;
    my $row_count;

	my $schema = $c->model('DB');
	my $favorite_rs = $schema->resultset("UserFavorite");
	my $user = $c->user->get('id');

  	my ($favorite_result) = $favorite_rs->create(
  	  { 
	   	user => $user,
		document => $document_id,
	  },
  	);

    %favorite_response = (
        rate_successful => 1,
        message_header => 'Font Favorited',
    	message_body => 'This font has been added to your favorites list',
    );

	}

	$c->stash->{like_response} = \%favorite_response;

	$c->view('JSON')->expose_stash('like_response');
	$c->detach('View::JSON');
}

=head2 unfavorite

Respond to unfavorite request.

=cut

sub unfavorite :Local {
    my ( $self, $c ) = @_;

    my $document_id = $c->req->param('document_id');

	my %favorite_response;

	unless($c->user_exists()) {
    	%favorite_response = (
    	    rate_successful => 0,
  	 	    message_header => 'You Must Be logged in.',
 		   	message_body => 'You must be logged in to unfavorite a font.',
	    );
	}
	else {
		my %vars;
	    my $row_count;

        my $cache_key = "documentblock:$document_id";
    	my $delete_status = $c->cache->remove($cache_key);

		my $schema = $c->model('DB');
		my $favorite_rs = $schema->resultset('UserFavorite');
	
		my $user = $c->user->get('id');

  		my $favorite_result = $favorite_rs->search(
  	  		{ 
	   			user => $user,
				document => $document_id,
	  		},
  		);

		my $delete_count = $favorite_result->delete;

		if($delete_count) {
    		%favorite_response = (
    		    rate_successful => 1,
  		 	    message_header => 'Font Unfavorited',
 			   	message_body => 'This font has been removed from your favorites list',
		    );

		}
		else {
    		%favorite_response = (
    	  	  rate_successful => 0,
  	 		  message_header => 'Error',
	   		  message_body => 'Error, please try again.',
		    );
		}

	}

	$c->stash->{like_response} = \%favorite_response;

	$c->view('JSON')->expose_stash('like_response');
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
