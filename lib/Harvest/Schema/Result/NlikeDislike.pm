use utf8;
package Harvest::Schema::Result::NlikeDislike;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Harvest::Schema::Result::NlikeDislike

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodeColumns>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodeColumns");

=head1 TABLE: C<nlike_dislike>

=cut

__PACKAGE__->table("nlike_dislike");

=head1 ACCESSORS

=head2 type

  data_type: 'integer'
  is_nullable: 0

=head2 document

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 nlike

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 ndislike

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 date_stored

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "type",
  { data_type => "integer", is_nullable => 0 },
  "document",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "nlike",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "ndislike",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "date_stored",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</document>

=back

=cut

__PACKAGE__->set_primary_key("document");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-02-12 03:58:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HwcA1Sg4hO7ixR/2n9KFrg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
