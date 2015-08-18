package Harvest::Controller::Render::Highlight;
use Moose;
use namespace::autoclean;

use JSON;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Render::Highlight - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $stash = $c->stash;
    my $cache = $c->cache;
	my $model = $c->model('DB::Font');

    my $doc_type = $c->stash->{doc_type};

    $c->stash->{template} = 'render/highlight/'.$doc_type.'.tt';

    my $document_id = $stash->{document_id} || '';
    my $cache_key = Digest::MD5::md5_hex("document_highlight:$document_id");
    my $highlight = $cache->get($cache_key);

    use Data::Dumper;
    warn Dumper($highlight);

    unless ($highlight) {
        warn $document_id;
        $highlight = $model->get_document_for_highlight($document_id);
        $cache->set($cache_key, $highlight, 5000);
    }

    my $document_for_title = $highlight->{name};

    # my $category_uri = uri_escape($highlight->{'Category'});
    my $category_uri = $highlight->{category_name};
    $category_uri and $category_uri =~ tr/ /\+/;

    my $url_first_name = $highlight->{first_name};
    $url_first_name and $url_first_name =~ tr/ /\+/;

    my $url_last_name = $highlight->{last_name};
    $url_last_name and $url_last_name =~ tr/ /\+/;

    my $nwanted = 5;
    $cache_key = Digest::MD5::md5_hex( join '_' => 'popular_documents', map {defined()?$_:''} @{ $highlight }{qw/ first_name last_name /}, $nwanted );

    my $popular_documents = $cache->get($cache_key);
    unless ($popular_documents && @$popular_documents) {
        my @popular_documents = $model->get_author_documents_complete( @{ $highlight->{author} }{qw/ first_name last_name /}, $nwanted );
        $popular_documents = \@popular_documents;
        $cache->set($cache_key, $popular_documents, 5000);
    }
    
    $nwanted = 100;
    $cache_key = Digest::MD5::md5_hex( join '_' => 'all_documents', map {defined()?$_:''} @{ $highlight->{author} }{qw/ first_name last_name /}, $nwanted );
    my $all_documents = $cache->get($cache_key);

    unless ($all_documents) {
        my @all_documents = $model->get_author_documents_minimal(@{ $highlight->{author} }{qw/ first_name last_name /}, $nwanted );
        $all_documents = \@all_documents;
        $cache->set($cache_key, $all_documents, 5000);
    }

    my $popular_documents_count = @$popular_documents;

    $highlight->{$_} .= ' 00:00:00' for qw( birth death );

    $highlight->{url} = "/fonts/download/$highlight->{id}/$highlight->{web_name}.zip";
    
    my $json_results = encode_json([$highlight]);

    $c->stash(
        document_block     => $highlight,
	json_results => $json_results,
    	popular_documents  => $popular_documents,
        popular_documents_count => $popular_documents_count,
    	all_documents  => $all_documents,
    	Category_URI    => $category_uri,
    	document_for_title => $document_for_title,
    	url_last_name   => $url_last_name,
    	url_first_name  => $url_first_name,
    	current_id  => $document_id,
    );
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
