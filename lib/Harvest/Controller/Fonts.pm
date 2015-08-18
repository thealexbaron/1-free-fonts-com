package Harvest::Controller::Fonts;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Fonts - Catalyst Controller

=head1 DESCRIPTION

Match the following paths:

  fonts/
  fonts/keyword/

Catalyst Controller.

=head1 METHODS

=cut

=head2 auto

Add default stash buckets.

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    $c->stash(
        doc_type => 'fonts',
    );
}

=head2 letter_only

Handle /fonts/a requests.

=cut

sub letter_only
    :Regex('^fonts/([a-zA-Z])$') {
    my ( $self, $c ) = @_;

    $c->stash->{letter_only} = $c->req->captures->[0];

    $c->go('/render/searchresult/index');
}

=head2 letter_pg

Handle /fonts/a/pg/1 requests.

=cut

sub letter_pg
    :Regex('^fonts/([a-zA-Z])/pg/([0-9]+)$') {
    my ( $self, $c ) = @_;

    $c->stash->{letter_only} = $c->req->captures->[0];
    $c->stash->{pg} = $c->req->captures->[1];

    $c->go('/render/searchresult/index');
}

=head2 base

Base action for chained /fonts actions.

=cut

sub base
    :Chained
    :PathPart('fonts')
    :CaptureArgs(0)
    { }


=head2 keyword_only

Handle /fonts/keyword requests.

=cut

sub keyword_only
    :Chained('base')
    :PathPart('keyword')
    :Args(1) {
    my ( $self, $c, $keyword ) = @_;

    $keyword =~ tr/+/ /;

    $c->stash(keyword => $keyword);
    $c->go('/render/searchresult/index');
}

=head2 keyword

Handle /fonts/keyword requests.

=cut

sub keyword
    :Chained('base')
    :PathPart('keyword')
    :CaptureArgs(1) {
    my ( $self, $c, $keyword ) = @_;

    $keyword =~ tr/+/ /;

    $c->stash(keyword => $keyword);
}

=head2 keyword_pg

Handle /fonts/keyword/*/pg/* requests.

=cut

sub keyword_pg
    :Chained('keyword')
    :PathPart('pg')
    :Args(1) {
    my ( $self, $c, $pg ) = @_;

    $c->stash(pg => $pg);
    $c->go('/render/searchresult/index');
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
