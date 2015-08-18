package Harvest::Schema::ResultSet::Font;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::ResultSet';

=head1 NAME

Harvest::Schema::ResultSet::Font

=head1 DESCRIPTION

Provide extended methods for the Font DBIC schema.

=head1 METHODS

=cut

=head2 get_document_for_highlight

Fetch document for use with document highlight page.

=cut

sub get_document_for_highlight {
    my ($self, $document_id ) = @_;

    return $self->search(
        { 'me.id' => $document_id },
        {
            rows => 1,
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            join => ['author',],
            '+select' => [
                'author.first_name',
                'author.last_name',
            ],
        },
    )->single;
}

=head2 get_author_documents_complete

Fetch documents for use in "All Quotes" section of highlight page.

=cut

sub get_author_documents_complete {
    my ($self, $first_name, $last_name, $count) = @_;

    $count ||= 10;

    return $self->search(
        {
            'author.first_name' => $first_name,
            'author.last_name' => $last_name,
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            join => [ 'nlike_dislike', 'author' ],
            '+select' => [
                'nlike_dislike.nlike',
                'nlike_dislike.ndislike',
            ],
            '+as' => [qw(
                nlike
                ndislike
            )],
            order_by => 'CAST(nlike_dislike.nlike - nlike_dislike.ndislike AS SIGNED) DESC',
            rows => $count,
        }
    );
}

=head2 get_author_documents_minimal

Fetch documents for "Top 5" section of document highlight page.

=cut

sub get_author_documents_minimal {
    my ($self, $first_name, $last_name, $count) = @_;

    $count ||= 10;

    return $self->search(
        {
            'author.first_name' => $first_name,
            'author.last_name' => $last_name,
        },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            join => ['nlike_dislike', 'author'],
            select => [qw(
                me.id
                me.name
                nlike_dislike.nlike
                nlike_dislike.ndislike
            )],
            order_by => 'CAST(nlike_dislike.nlike - nlike_dislike.ndislike AS SIGNED) DESC',
            rows => $count,
        }
    );
}

=head2 get_user_documents ($self, $user_id)

Get a result set of documents for user $user_id.

=cut

sub get_user_documents {
    my ($self, $user_id) = @_;

    return $self->search(
        { 'me.user' => $user_id },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            join => 
            [
                'author', 
                'user',
                {
                    category_font => 'category',
                },
            ],
            select => [qw(
                me.id
                me.name
                category.name
            )],
            as => [qw(
                document_id
                document
                category_name
            )],
        }
    );
}

=head2 get_user_favorites($self, $user_id)

Get a result set of user $user_id's favorite documents.

=cut

sub get_user_favorites {
    my ($self, $user_id) = @_;

    return $self->search(
        { 'user_favorite.user' => $user_id },
        {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            join => 
            [
                'author', 
                'user',
                {
                    category_font => 'category',
                
                    user_favorite => 'user'
                },
            ],
            'select' => [qw( me.id me.name category.name author.first_name author.last_name )],
            'group_by' => 'me.id',
        }
    );
}


=head2 check_if_font_exists_by_html_encoded_name_and_author_id

Returns true if font exists in database based on web encoded name and author id.

=cut

sub check_if_font_exists_by_html_encoded_name_and_author_id {
    my ($self, $c, $html_encoded_name, $author_id) = @_;

    my $font_result = $c->model('DB')->resultset('Font')->search(
        { 
            web_name => { '=' => $html_encoded_name },
            author => { '=' => $author_id }
        },
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
    );

    my $count = $font_result->count;

    return $count;
}

=head2 check_if_font_exists_by_html_encoded_name

Returns true if font exists in database based on web encoded name.

=cut

sub check_if_font_exists_by_html_encoded_name {
    my ($self, $c, $html_encoded_name) = @_;

    my $font_result = $c->model('DB')->resultset('Font')->search(
        { web_name => { '=' => $html_encoded_name } },
        {result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
    );

    my $count = $font_result->count;

    return $count;
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
