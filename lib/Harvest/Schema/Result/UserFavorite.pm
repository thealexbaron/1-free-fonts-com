use utf8;
package Harvest::Schema::Result::UserFavorite;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Harvest::Schema::Result::UserFavorite

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

=head1 TABLE: C<user_favorite>

=cut

__PACKAGE__->table("user_favorite");

=head1 ACCESSORS

=head2 user

  data_type: 'integer'
  is_nullable: 0

=head2 document

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user",
  { data_type => "integer", is_nullable => 0 },
  "document",
  { data_type => "integer", is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<user>

=over 4

=item * L</user>

=back

=cut

__PACKAGE__->add_unique_constraint("user", ["user"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-02-12 03:58:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O/qLdD5iibF8RuaswEed/g

__PACKAGE__->belongs_to(user => 'Harvest::Schema::Result::User');
__PACKAGE__->belongs_to(document => 'Harvest::Schema::Result::Font');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
