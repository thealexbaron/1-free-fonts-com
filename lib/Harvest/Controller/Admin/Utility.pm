package Harvest::Controller::Admin::Utility;
use Moose;
use namespace::autoclean;

use File::Copy;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Harvest::Controller::Admin::Utility - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 move_1001freefontscom_resources_into_folders

=cut

sub move_1001freefontscom_resources_into_folders :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $uploaddir = $c->path_to(qw[ root static ]) . '/fonts/';

    my $font_result = $c->model('DB')->resultset('Font')->search(
        { author => { '=' => undef } },
        #{ result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
    );

    while (my $font = $font_result->next) {

        my $newdir = $uploaddir.$font->id.'/';

        unless( -d $newdir ) {
            mkdir $uploaddir.'/'.$font->id or die $!;

            my $fontzip = $font->web_name.'.zip';
            my $fontgif = $font->web_name.'.gif';
            
            if( -e $uploaddir.$fontgif) {
                move($uploaddir.$fontgif, $newdir.$fontgif) or die "The move operation failed for $fontgif: $!";
            }
            if( -e $uploaddir.$fontzip) {
                move($uploaddir.$fontzip, $newdir.$fontzip) or die "The move operation failed for $fontzip: $!";
            }

        }
    }
}

=head2 test_www_mech_encoding

=cut

sub test_www_mech_encoding :Local :Args(0) {
    my ( $self, $c ) = @_;

    my $mech = $c->forward('/spider/create_mech_object');
    my $font_page_content = $c->forward('/spider/get_page_content', ['http://www.fontspace.com/måns-grebäck/ghang', $mech, 1]);

    my $font_page_tree = HTML::TreeBuilder->new_from_content($font_page_content);
    
    my ($category_section) = $font_page_tree->look_down('class', 'inline', '_tag', 'ul');
    my @category_links = $category_section->look_down('_tag', 'a');

    my @categories = map($_->as_text, @category_links);

    my $model = $c->model('DB::Category');
    foreach my $font_category (@categories) {

        my $font_category_id = $model->get_or_create_category_id_by_category_name($c, $font_category);

    }

    $c->stash->{categories} = \@categories;
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
