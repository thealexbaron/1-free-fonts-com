package DBIx::Class::EncodeColumns;

use strict;
use warnings;
use vars qw/$VERSION/;
$VERSION = '0.02';

use base qw/DBIx::Class/;

use Encode;

__PACKAGE__->mk_classdata( decode_columns => 'latin-1' );
__PACKAGE__->mk_classdata( encode_columns => 'latin-1' );

=head1 NAME

DBIx::Class::EncodeColumns - Handle column encodings

=head1 SYNOPSIS

    package Artist;
    __PACKAGE__->load_components(qw/EncodeColumns Core/);
    __PACKAGE__->decode_columns('latin-1');
    __PACKAGE__->encode_columns('utf-8');


=head1 DESCRIPTION

This module allows you to handle column encodings

=head1 CHANGES

=head2 Wed May 18 21:12:05 UTC 2011 eval{} wrappers

Added eval block wrappers around calls to &encode and &decode.

=head1 METHODS

=head2 decode_columns($encoding)

Use this function to set the default encoding of all your columns.
The data of all columns will be decoded to internal encoding of perl.

=cut

=head2 encode_columns($encoding)

Before returning the data form a column, it will be encoded using this
encoding type.

=cut

=head1 EXTENDED METHODS

=head2 get_column

=cut

sub get_column {
    my ( $self, $column ) = @_;
    my $value = $self->next::method($column);

    if( defined $value ) {
        $value = decode( $self->decode_columns, $value )
            if $self->decode_columns;
        $value = encode( $self->encode_columns, $value )
            if $self->encode_columns;
    }

    return $value;
}

=head2 get_columns

=cut

sub get_columns {
    my $self = shift;
    my %data = $self->next::method(@_);

    foreach my $col (keys %data) {
        if(defined(my $value = $data{$col}) ) {
            $value = decode( $self->decode_columns, $value )
                if $self->decode_columns;
            $value = encode( $self->encode_columns, $value )
                if $self->encode_columns;
            $data{$col} = $value;
        }
    }

    return %data;
}

=head2 store_column

Overrides the lowest level DBIx::Class::Row method before values are passed
to storage.

Calls &replace_bad_chars for defined, non-zero length values to replace
characters that do not map to latin1 (ISO-8859-1) with ASCII facsimiles.

Added eval {} wrapper around encode and decode calls to catch exceptions.

=cut

sub store_column {
    my ( $self, $column, $value ) = @_;

    $value = replace_bad_chars($value) if defined($value) && length $value;

    eval {
        $value = decode( $self->encode_columns, $value )
          if $self->encode_columns;
        $value = encode( $self->decode_columns, $value )
          if $self->decode_columns;
    };

    return $self->next::method( $column, $value );
}

=head2 replace_bad_chars

Replace characters that do not map to Latin-1.

=cut

sub replace_bad_chars {
    my ($octets) = @_;

    s/\x{2026}/.../g,           # ellipsis
    s/[\x{201c}\x{201d}]/"/g,   # matching pair double quotes
    s/[\x{2018}\x{2019}]/'/g,   # matching pair single quotes
    s/\x{2013}/-/g,             # en dash
    s/\x{2014}/--/g,            # em dash
    s/\x{2032}/'/g              # single prime (feet, radians, etc.)
        for $octets;

    return $octets;
}

=head1 AUTHOR

Sascha Kiefer <esskar@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;

