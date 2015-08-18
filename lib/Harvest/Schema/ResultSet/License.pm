package Harvest::Schema::ResultSet::License;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::ResultSet';

=head1 NAME

Harvest::Schema::ResultSet::License

=head1 DESCRIPTION

Provide extended methods for the Font DBIC schema.

=head1 METHODS

=cut

=head2 get_or_create_license_id_by_name

Creates a license unless it already exists.

=cut

sub get_or_create_license_id_by_name {
    my ($self, $c, $license_name) = @_;

    my $license_rs = $c->model('DB')->resultset('License');

    my $license_id_row = $license_rs->search(
        { name => { '=' => $license_name } },
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
    )->single;

    my $license_id = $license_id_row->{id};

    unless($license_id) {
        my $license_id_row = $license_rs->create(
            {
                name => $license_name,
            },
            {result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
        );

        $license_id = $license_id_row->id;
        warn "Creating lisence definition for '$license_name'.\n";
    }

    return $license_id;
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;






