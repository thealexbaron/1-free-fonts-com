package Harvest::Controller::Font;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Font - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=back

=cut

sub base
    :Chained('/')
    :PathPart('font')
    :CaptureArgs(1) {
    my ( $self, $c, $font_id ) = @_;

    unless ($font_id =~ /^[1-9][0-9]*$/) {
        $c->detach('/default');
    }

    $c->stash(
        document_id => $font_id,
        doc_type => 'fonts',
    );
}

=head2 font_id

Endpoint of: /font/<id>

Detaches to /render/highlight/index action.

=cut

sub number
    :Chained('base')
    :PathPart('')
    :Args(0) {
    my ( $self, $c ) = @_;

    $c->go('/render/highlight/index');
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
