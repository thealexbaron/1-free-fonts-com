use utf8;
package Harvest::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Harvest::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 uid

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 password

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 lastname

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 firstname

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 email

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 bio

  data_type: 'char'
  is_nullable: 1
  size: 250

=head2 image

  data_type: 'integer'
  is_nullable: 1

=head2 facebook_id

  data_type: 'integer'
  is_nullable: 1

=head2 account_related

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

emails

=head2 newsletter

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

emails

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "bigint",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "uid",
  { data_type => "char", is_nullable => 0, size => 64 },
  "password",
  { data_type => "char", is_nullable => 0, size => 64 },
  "lastname",
  { data_type => "char", is_nullable => 1, size => 255 },
  "firstname",
  { data_type => "char", is_nullable => 1, size => 255 },
  "email",
  { data_type => "char", is_nullable => 1, size => 255 },
  "bio",
  { data_type => "char", is_nullable => 1, size => 250 },
  "image",
  { data_type => "integer", is_nullable => 1 },
  "facebook_id",
  { data_type => "integer", is_nullable => 1 },
  "account_related",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "newsletter",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<email>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("email", ["email"]);

=head2 C<uid>

=over 4

=item * L</uid>

=back

=cut

__PACKAGE__->add_unique_constraint("uid", ["uid"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-02-12 03:58:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JGM10S6TaG3+d2r9ySMMDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
