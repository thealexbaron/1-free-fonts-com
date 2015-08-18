package Harvest::Controller::Spider::1001FreeFontsCom;
use Moose;
use namespace::autoclean;

use WWW::Mechanize;
use HTML::TreeBuilder;

use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }

my $site = 'http://www.1001freefonts.com';

=head1 NAME

Harvest::Controller::Spider::1001FreeFontsCom - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $mech = $c->forward('/spider/create_mech_object');
    my $content = $c->forward('/spider/get_page_content', [${site}, $mech]);

    my $tree = HTML::TreeBuilder->new_from_content($content);
    $tree->parse($content);

    my @font_table_attrs = (
        class => 'tdclear',
        width => 930,
        height => 140,
        border => '0',
    );

    my @main_table = $tree->look_down(
        class => 'tdclear',
        width => 920,
        align => 'center',
        border => '0',
        cellpadding => '0',
        cellspacing => '0'
    );

    my $main_table_raw = $c->forward('/spider/get_hrefs_from_element', [\@main_table]);
    my $main_table_uniq = $c->forward('/spider/uniq', [$main_table_raw]);

    warn Dumper($main_table_uniq);

    foreach my $category (@$main_table_uniq) {

        my $content = $c->forward('/spider/get_page_content', [${site}.${category}, $mech]);

        my $tree = HTML::TreeBuilder->new_from_content($content);
        $tree->parse($content);

        my @paging_table = $tree->look_down(
            width => 950,
            border => '0',
            cellpadding => 10,
            cellspacing => '0',
            sub {
                $_[0]->as_text =~ m{Back Page}
            }
        );

        my @font_tables = $tree->look_down(@font_table_attrs);

        my $font_tables_raw = $c->forward('/spider/get_hrefs_from_element', [\@font_tables]);
        my $font_tables_uniq = $c->forward('/spider/uniq', [$font_tables_raw]);

        my ($fonts) = $c->forward('/spider/return_only_zip_files', [$font_tables_uniq]);

        warn 'There were ' . scalar(@$fonts) . ' fonts found on ' . ${site}.${category};

        download_and_insert_into_db($fonts, $c, $mech);

        my $page_numbers_raw = $c->forward('/spider/get_hrefs_from_element', [\@paging_table]);
        my $page_numbers_uniq = $c->forward('/spider/uniq', [$page_numbers_raw]);
        
        my @page_numbers_processed;
        foreach my $link (@$page_numbers_uniq) {
            if($link =~ m{-[0-9]+\.php$}) {
                push @page_numbers_processed, $link;
            }
        }

        unless(@page_numbers_processed) {
            warn "${site}/${category} has no pages.\n";
        }

        foreach my $page (@page_numbers_processed) {
            my $content = $c->forward('/spider/get_page_content', [${site}.${page}, $mech]);

            my $tree = HTML::TreeBuilder->new_from_content($content);
            $tree->parse($content);

            my @font_tables = $tree->look_down(@font_table_attrs);
            my $font_tables_raw = $c->forward('/spider/get_hrefs_from_element', [\@font_tables]);
            my $font_tables_uniq = $c->forward('/spider/uniq', [$font_tables_raw]);

            my ($fonts) = $c->forward('/spider/return_only_zip_files', [$font_tables_uniq]);

            warn 'There were ' . scalar(@$fonts) . ' fonts found on ' . ${site}.${page};

            download_and_insert_into_db($fonts, $c, $mech);
        }

    }
}

sub download_and_insert_into_db {

    my ($fonts, $c, $mech ) = @_;

    foreach my $font (@$fonts) {
        my $model = $c->model('DB::Font');
        my $font_exists = $model->check_if_font_exists_by_html_encoded_name($c, $font);

        unless($font_exists) {
            my ($font_category, $font_name) = get_1001_font_com_unencoded_font_name($font, $c, $mech);
           
            $c->forward('/spider/throttle');

            my $uploaddir = $c->path_to(qw[ root static ]) . '/fonts/';
            
            my $gif_file = $font.'.gif';
            $mech->get($site.'/fontdisplay/'.$gif_file);
            $mech->save_content( $uploaddir.$gif_file );
            warn "Couldn't download: $gif_file: ", $mech->response->status_line
            unless $mech->success;

            my $zip_file = $font.'.zip';
            $mech->get($site.'/font/'.$zip_file);
            $mech->save_content( $uploaddir.$zip_file );
            die "Couldn't download: $zip_file: ", $mech->response->status_line
            unless $mech->success;
            
            if($mech->success()) {

            	my $schema = $c->model('DB');
	            my $font_rs = $schema->resultset('Font');

  	            my ($font_insert) = $font_rs->create(
  	                { 
	            	name => $font_name,
		            web_name => $font,
	                },
  	            );

                my $model = $c->model('DB::Category');
                my $font_category_id = $model->get_or_create_category_id_by_category_name($c, $font_category);

                my $id = $font_insert->id;

                my $category_result;
                if($id) {

                    my $category_rs = $schema->resultset('CategoryFont');

                    ($category_result) = $category_rs->create(
                        {
                            category => $font_category_id,
                            font => $id,
                        },
                    );

                    my $other_id = $category_result->id;
                }
            }
            else {
                warn "Couldn't get zip file: ", $mech->response->status_line;
            }
            
            warn "Official Name: $font_name, Encoded Name: $font, Category: $font_category\n";
        }
        else {
            warn "Font already exists in DB. Skip.\n";
        }

    }
}

sub get_1001_font_com_unencoded_font_name {
    my ($font, $c, $mech) = @_;
   
    my $content = $c->forward('/spider/get_page_content', [${site}.'/'.${font}.'.php', $mech]);

    $content =~ m{>([A-Za-z0-9 ]+) Fonts</a>&nbsp;&nbsp;&gt;&nbsp;&nbsp;([A-Za-z0-9 ]+) Font</b>};

    return ($1, $2);
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
