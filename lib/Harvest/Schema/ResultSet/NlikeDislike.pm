package Harvest::Schema::ResultSet::NlikeDislike;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::ResultSet';

=head1 NAME

Harvest::Schema::ResultSet::NlikeDislike

=head1 DESCRIPTION

Provide extended methods for the NlikeDislike DBIC schema.

=head1 METHODS

=cut

=head2 increment_likes

Increment the document's count of "likes".

=cut

sub increment_likes {
    my ($self, $document_id) = @_;

    my $rv;

    for my $likes ($self->search_rs({ document => $document_id })) {
        if ($likes->count) {
            $rv = $likes->update({ nlike => \'nlike + 1' });
        }
        else {
            $rv = $self->create({ document => $document_id, type => 1, nlike => 1 });
        }
    }

    return $rv;
}

=head2 increment_dislikes

Increment the document's count of "dislikes".

=cut

sub increment_dislikes {
    my ($self, $document_id) = @_;

    my $rv;

    for my $likes ($self->search_rs({ document => $document_id })) {
        if ($likes->count) {
            $rv = $likes->update({ ndislike => \'ndislike + 1' });
        }
        else {
            $rv = $self->create({ document => $document_id, type => 1, ndislike => 1 });
        }
    }

    return $rv;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

