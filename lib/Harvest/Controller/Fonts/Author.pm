package Harvest::Controller::Fonts::Author;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Fonts::Author - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 list_authors_htm

Match requests for fonts/author/[A-Z].

=cut


sub list_authors_htm
    :Regex('^fonts/author/([a-zA-Z])$') {
    my ( $self, $c ) = @_;

    $c->stash(
        type => 'author',
        letter => $c->req->captures->[0],
    );

    $c->detach('/render/list/index');
}

=head2 list_authors_htm_pg

Match requests for fonts/author/[A-Z]/pg/[0-9]+.

=cut


sub list_authors_htm_pg
    :Regex('^fonts/author/([a-zA-Z])(?:\.htm)?/pg/([0-9]+)$') {
    my ( $self, $c ) = @_;

    $c->stash(
        type => 'author',
        letter => $c->req->captures->[0],
        pg => $c->req->captures->[1],
    );

    $c->detach('/render/list/index');
}

=head2 base

Base action for chained /fonts actions. Captures font ID (font.id).

Handles requests:

=over

=item /fonts/author/<first name>/<last name>

=back

  fonts/author/([a-zA-Z0-9_',+-]{2,})
  fonts/author/([a-zA-Z_.',+-]{2,})/([a-zA-Z_'.,+-]{2,})
  fonts/author/([a-zA-Z_.',+-]{2,})/([a-zA-Z_'.,+-]{2,})/keyword/([a-zA-Z_'.,+-]{2,})
  fonts/author/([a-zA-Z])\.htm

=cut

sub base
    :Chained
    :PathPart('fonts')
    :CaptureArgs(0)
    { }


=head2 author_full_name_only

Respond to /fonts/author/* requests.

=cut

sub author_full_name_only
    :Chained('base')
    :PathPart('author')
    :Args(2) {
    my ( $self, $c, $fname, $lname ) = @_;

    $fname =~ tr/+/ /;

    $c->stash(
        first_name => $fname,
        last_name => $lname,
    );

    $c->go('/render/searchresult/index');
}

=head2 author_full_name

Respond to /fonts/author/*/*/pg/* requests.

=cut

sub author_full_name
    :Chained('base')
    :PathPart('author')
    :CaptureArgs(2) {
    my ( $self, $c, $fname, $lname ) = @_;

    $fname =~ tr/+/ /;
    $lname =~ tr/+/ /;

    $c->stash(
        first_name => $fname,
        last_name => $lname
    );
}

=head2 author_full_name_keyword

Endpoint action for /fonts/author/*/*/keyword/* requests.

=cut

sub author_full_name_keyword
    :Chained('author_full_name')
    :PathPart('keyword')
    :Args(1) {
    my ( $self, $c, $keyword ) = @_;

    $c->stash(keyword => $keyword);

    $c->go('/render/searchresult/index');
}


=head2 author_full_name_keyword_pg

Capture action for /fonts/author/*/*/keyword/* requests.

=cut

sub author_full_name_keyword_pg
    :Chained('author_full_name')
    :PathPart('keyword')
    :CaptureArgs(1) {
    my ( $self, $c, $keyword ) = @_;

    $c->stash(keyword => $keyword);
}

=head2 author_full_name_keyword_pg_number

Endpoint action for /fonts/author/*/*/keyword/* requests.

=cut

sub author_full_name_keyword_pg_number
    :Chained('author_full_name_keyword_pg')
    :PathPart('pg')
    :Args(1) {
    my ( $self, $c, $pg ) = @_;

    $c->stash(pg => $pg);

    $c->go('/render/searchresult/index');
}

=head2 author_full_name_pg

Endpoint action for /fonts/author/*/*/pg/* requests.

=cut

sub author_full_name_pg
    :Chained('author_full_name')
    :PathPart('pg')
    :Args(1) {
    my ( $self, $c, $pgnum ) = @_;

    $c->stash(pg => $pgnum);

    $c->go('/render/searchresult/index');
}

=head2 sub Author_Last_Name_only_no_param_key

=cut

sub Author_Last_Name_only_no_param_key
    :Chained('base')
    :PathPart('author')
    :CaptureArgs(1) {
    my ( $self, $c, $lname ) = @_;

    $lname =~ tr/+/ /;

    $c->stash(last_name => $lname);
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
