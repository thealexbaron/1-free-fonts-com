package Harvest::Schema::ResultSet::DocType;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::ResultSet';

=head1 NAME

Harvest::Schema::ResultSet::DocType

=head1 DESCRIPTION

Provide extended methods for the DocType DBIC schema.

=head1 METHODS

=cut

=head2 get_doc_type_id

Retrieve the id of a row based on the name of the doc.

=cut

sub get_doc_type_id {
    my ($self, $c, $doc_type_name) = @_;

    $doc_type_name =~ tr/+/ /;

    my $cache_key = "doc_type_id:${doc_type_name}";
    $cache_key = Digest::MD5::md5_hex($cache_key);
    $c->stash->{get_doc_type_id_cache_key} = $cache_key;
    my $doc_type_id = $c->cache->get($cache_key);

    unless ($doc_type_id) {
        my $model = $c->model('DB');
        my $doc_type = $model->resultset('DocType')->search(
            { name => $doc_type_name },
        )->single;
        if ($doc_type) {
            $doc_type_id = $doc_type->id;
        }
        $c->cache->set($cache_key, $doc_type_id, 5000);
    }

    return $doc_type_id;
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;


