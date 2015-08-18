package Harvest::Schema::ResultSet::Author;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::ResultSet';

=head1 NAME

Harvest::Schema::ResultSet::Author

=head1 DESCRIPTION

Provide extended methods for the Font DBIC schema.

=head1 METHODS

=cut

=head2 get_or_create_author_id_by_first_and_last_name

Creates an author unless it already exists.

=cut

sub get_or_create_author_id_by_first_and_last_name {
    my ($self, $c, $author_email, $first_name, $last_name, $author_website) = @_;

    my $author_rs = $c->model('DB')->resultset('Author');

    my $author_id_row = $author_rs->search(
        { 
            first_name => { '=' => $first_name },
            last_name => { '=' => $last_name } 
        },
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
    )->single;

    my $author_id = $author_id_row->{id};

    unless($author_id) {
        my $author_id_row = $author_rs->create(
            {
                first_name => $first_name,
                last_name => $last_name,
                email => $author_email,
                site => $author_website,
            },
            {result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
        );

        $author_id = $author_id_row->id;
        warn "Creating author row for '$first_name $last_name'.\n";
    }

    return $author_id;
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;





