use utf8;
package Harvest::Schema::Result::Font;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Harvest::Schema::Result::Font

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

=head1 TABLE: C<fonts>

=cut

__PACKAGE__->table("fonts");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 web_name

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 date_stored

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 license

  data_type: 'integer'
  is_nullable: 1

=head2 author

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'integer'
  is_nullable: 0

=head2 user

  data_type: 'integer'
  is_nullable: 1

=head2 paid

  data_type: 'tinyint'
  is_nullable: 1

=head2 sku

  data_type: 'char'
  is_nullable: 1
  size: 40

=head2 buy_url

  data_type: 'char'
  is_nullable: 1
  size: 80

=head2 image_url

  data_type: 'char'
  is_nullable: 1
  size: 80

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "char", is_nullable => 0, size => 40 },
  "web_name",
  { data_type => "char", is_nullable => 0, size => 40 },
  "date_stored",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "license",
  { data_type => "integer", is_nullable => 1 },
  "author",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "integer", is_nullable => 0 },
  "user",
  { data_type => "integer", is_nullable => 1 },
  "paid",
  { data_type => "tinyint", is_nullable => 1 },
  "sku",
  { data_type => "char", is_nullable => 1, size => 40 },
  "buy_url",
  { data_type => "char", is_nullable => 1, size => 80 },
  "image_url",
  { data_type => "char", is_nullable => 1, size => 80 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<fonts>

=over 4

=item * L</sku>

=back

=cut

__PACKAGE__->add_unique_constraint("fonts", ["sku"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-02-12 04:28:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yPkLCEMlGrvOZ5Mohk5m8Q

__PACKAGE__->has_many(category_font => 'Harvest::Schema::Result::CategoryFont', 'font');
__PACKAGE__->many_to_many('categories', 'category_font', 'font');
__PACKAGE__->has_many(nlike_dislike => 'Harvest::Schema::Result::NlikeDislike', 'document');
__PACKAGE__->belongs_to(author => 'Harvest::Schema::Result::Author', 'author');

__PACKAGE__->many_to_many('favorites', 'user_favorite', 'document');
__PACKAGE__->has_many(user_favorite => 'Harvest::Schema::Result::UserFavorite', 'document');

__PACKAGE__->belongs_to(user => 'Harvest::Schema::Result::User', 'user');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
