package Harvest::Controller::Fonts::Category;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Fonts::Category - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 category_htm

Match requests for fonts/category/[A-Z].

=cut

sub category_htm
    :Regex('^fonts/category/([a-zA-Z])$') {
    my ( $self, $c ) = @_;

    my $letter = $c->req->captures->[0] || 'A';

    $c->stash(
        type => 'category',
        letter => $letter,
    );

    $c->go('/render/list/index');
}

=head2 list_category_htm_pg

Match requests for fonts/category/[A-Z]/pg/[0-9]+.

=cut


sub list_category_pg
    :Regex('^fonts/category/([a-zA-Z])/pg/([0-9]+)$') {
    my ( $self, $c ) = @_;

    $c->stash(
        type => 'category',
        letter => $c->req->captures->[0],
        pg => $c->req->captures->[1],
    );

    $c->detach('/render/list/index');
}

sub base
    :Chained
    :PathPart('fonts')
    :CaptureArgs(0)
    { }

sub category
    :Chained('base')
    :PathPart('category')
    :CaptureArgs(1) {
    my ( $self, $c, $category ) = @_;

    $category =~ tr/+/ /;

    $c->stash(category => $category);
}

sub Category
    :Chained('base')
    :PathPart('Category')
    :CaptureArgs(1) {
    my ( $self, $c, $category ) = @_;

    $category =~ tr/+/ /;

    $c->stash(category => $category);
}

sub Category_endpoint
    :Chained('base')
    :PathPart('Category')
    :Args(1) {
    my ( $self, $c, $category ) = @_;

    $c->stash(category => $category);

    $c->go('/render/searchresult/index');
}

sub category_only
    :Chained('category')
    :PathPart('')
    :Args(0) {
    my ( $self, $c ) = @_;

    $c->go('/render/searchresult/index');
}

sub category_pg
    :Chained('category')
    :PathPart('pg')
    :Args(1) {
    my ( $self, $c, $pgnum ) = @_;


    $c->stash(pg => $pgnum);

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
