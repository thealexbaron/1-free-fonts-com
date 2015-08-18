package Harvest::Schema::ResultSet::User;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::ResultSet';

=head1 NAME

Harvest::Schema::ResultSet::User

=head1 DESCRIPTION

Provide extended methods for the User DBIC schema.

=head1 METHODS

=cut

=head2 get_user_id_by_uid

Fetch user id based on textual uid.

=cut

sub get_user_id_by_uid {
    my ($self, $uid ) = @_;

    my $user = $self->find({ uid => $uid });

    return $user ? $user->id : undef;
}

=head2 check_if_email_exists

Check if email exists in user table.

=cut

sub check_if_email_exists {
    my ($self, $email ) = @_;

    my $email_exists = $self->single({ email => $email });

    return $email_exists;
}

=head2 email_disallows_account_related_emails

Check if user's email is allowed to receive account related emails.

=cut

sub email_disallows_account_related_emails {
    my ($self, $email ) = @_;

    my $not_allowed = $self->single({ 
        email => $email,
        account_related => 0,
    });

    return $not_allowed;
}

=head2 get_public_user_data_by_uid($self, $uid)

Get a user row by textual uid.

Security-related data are excluded.

=cut

sub get_public_user_data_by_uid {
    my ($self, $uid) = @_;

    return $self->find(
        { uid => $uid },
        {
            columns => [qw(
                id
                uid
                lastname
                firstname
                email
                bio
                image
                facebook_id
            )],
        }
    );
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

