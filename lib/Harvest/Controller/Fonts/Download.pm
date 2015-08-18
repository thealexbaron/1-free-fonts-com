package Harvest::Controller::Fonts::Download;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Fonts::Download - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 auto

Authenticate.

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    # check if authenticated via captcha

}


=head2 index

=cut

sub index :Path :Args(2) {
    my ( $self, $c, @args ) = @_;

    $c->response->redirect( "/static/fonts/$args[0]/$args[1]" );

    #$c->response->body('Matched Harvest::Controller::Fonts::Download in Fonts::Download.');
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
