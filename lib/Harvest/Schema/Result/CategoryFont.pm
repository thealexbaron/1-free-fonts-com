use utf8;
package Harvest::Schema::Result::CategoryFont;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Harvest::Schema::Result::CategoryFont

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

=head1 TABLE: C<category_font>

=cut

__PACKAGE__->table("category_font");

=head1 ACCESSORS

=head2 category

  data_type: 'integer'
  is_nullable: 0

=head2 font

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "category",
  { data_type => "integer", is_nullable => 0 },
  "font",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</category>

=item * L</font>

=back

=cut

__PACKAGE__->set_primary_key("category", "font");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-02-12 03:57:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PiMKb0KOtB1Q0B+4263IIA

__PACKAGE__->belongs_to(category => 'Harvest::Schema::Result::Category');
__PACKAGE__->belongs_to(font => 'Harvest::Schema::Result::Font');

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
