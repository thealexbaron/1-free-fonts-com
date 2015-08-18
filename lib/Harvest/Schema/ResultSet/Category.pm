package Harvest::Schema::ResultSet::Category;

use Test::utf8;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::ResultSet';

=head1 NAME

Harvest::Schema::ResultSet::Category

=head1 DESCRIPTION

Provide extended methods for the Font DBIC schema.

=head1 METHODS

=cut

=head2 get_or_create_category_id_by_category_name

Creates a category unless it already exists.

=cut

sub get_or_create_category_id_by_category_name {
    my ($self, $c, $category_name) = @_;

    #$category_name =~ s/[^\p{L}A-Za-z]//g;

unless(is_sane_utf8($category_name)) {
        return;
    }


    my $category_rs = $c->model('DB')->resultset('Category');

    my $category_id = $category_rs->find_or_create(
        { name => $category_name },
        #{result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
    );

    return $category_id->id;
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;




