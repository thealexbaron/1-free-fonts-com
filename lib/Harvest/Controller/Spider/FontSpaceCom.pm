package Harvest::Controller::Spider::FontSpaceCom;
use Moose;
use namespace::autoclean;

use WWW::Mechanize;
use HTML::TreeBuilder;

use IPC::Run;
use Test::utf8;

use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }

my $site = 'http://www.fontspace.com';

=head1 NAME

Harvest::Controller::Spider::FontSpaceCom - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $home = $c->config->{home};

    my @cmd = ( 
        qq|$home/script/harvest_test.pl "/spider/fontspacecom/start_spider"|
    );

    my $progress = 0;
    my $task_id = 10;

    IPC::Run::run(\@cmd, ">", sub {
        my $output = shift;
        $progress++ if ( $output =~ /^THROTTLED/ );

        $c->snippet( progress => $task_id => ++$progress )
            if ( $output =~ /^THROTTLED/  );
    });

}


=head2 start_spider

=cut

sub start_spider :Local {
    my ( $self, $c ) = @_;

    my $mech = $c->forward('/spider/create_mech_object');
    my $content = $c->forward('/spider/get_page_content', [${site}, $mech, 1]);
    if(!$content) { next; }

    my $tree = HTML::TreeBuilder->new_from_content($content);
    $tree->parse($content);

    my ($h4) = $tree->look_down(
        '_tag', 'h4',
        class => 'white main-section-headline',
            sub {
                $_[0]->as_text =~ m{Alphabetically}
            }
    );

    my @main_table = $h4->right();

    my $main_table_raw = $c->forward('/spider/get_hrefs_from_element', [\@main_table]);
    my $main_table_uniq = $c->forward('/spider/uniq', [$main_table_raw]);

    foreach my $letter (@$main_table_uniq) {

        if(
            lc($letter) =~ m{a$} || 
            lc($letter) =~ m{b$} || 
            lc($letter) =~ m{c$} || 
            lc($letter) =~ m{d$} || 
            lc($letter) =~ m{e$} || 
            lc($letter) =~ m{f$} || 
            lc($letter) =~ m{g$} || 
            lc($letter) =~ m{h$} || 
            lc($letter) =~ m{i$} ||
            lc($letter) =~ m{j$} ||
            lc($letter) =~ m{k$} ||
            lc($letter) =~ m{l$} ||
            lc($letter) =~ m{m$} ||
            lc($letter) =~ m{n$} ||
            lc($letter) =~ m{o$} ||
            lc($letter) =~ m{p$} ||
            lc($letter) =~ m{q$} ||
            lc($letter) =~ m{r$} ||
            lc($letter) =~ m{s$} ||
	        lc($letter) =~ m{t$} ||
            lc($letter) =~ m{u$} ||
            lc($letter) =~ m{v$}
        ) 
        
        {
            next;
        }

        my $schema = $c->model('DB');
        
        my $content = $c->forward('/spider/get_page_content', [${site}.${letter}, $mech]);
        if(!$content) { next; }

        my $tree = HTML::TreeBuilder->new_from_content($content);
        $tree->parse($content);

        my $next_page = $tree->look_down(
            '_tag' => 'a',
            class => 'pg-link',
            sub {
                $_[0]->as_text =~ m{Next}
            }
        );

        my $total_pages_tag = $next_page->left();
        my $total_pages = $total_pages_tag->as_text;

        my $start_page;
        if(lc($letter) eq lc('A')) {
            $start_page = 30;
        }
        else {
            $start_page = 2;
        }

        my @page_numbers = ($start_page .. $total_pages);
        my @page_number_links = map("$letter?p=$_", @page_numbers);
        unshift @page_number_links, ${letter};
       
        foreach my $page (@page_number_links) {

            my $content = $c->forward('/spider/get_page_content', [${site}.${page}, $mech]);
            if(!$content) { next; }

            my $tree = HTML::TreeBuilder->new_from_content($content);
            $tree->parse($content);

            my @font_divs_from_search = $tree->look_down(
                '_tag' => 'div',
                class => 'uc-flr fix-float',
            );

            foreach my $div (@font_divs_from_search) {

                my ($main_link) = $div->look_down(
                    '_tag' => 'a',
                    class => 'preview-image',

                    sub {
                        return unless $_[0]->attr('href');
                    }
                );

                my $font_name_raw = $main_link->attr('title');
                $font_name_raw =~ m{^Free (.*) font$};
                my $font_name = $1;

                my $font_page = $main_link->attr('href');

                my ($font_image) = $main_link->look_down(
                    '_tag' => 'img',
                    class => 'preview',
                );

                my $main_font_image = $font_image->attr('src');

                # Get info from actual page
                my $font_page_content = $c->forward('/spider/get_page_content', [${site}.${font_page}, $mech]);
                if(!$font_page_content) { next; }
                my $font_page_tree = HTML::TreeBuilder->new_from_content($font_page_content);
                $font_page_tree->parse($font_page_tree);

                my ($gallery_link) = $font_page_tree->look_down(
                    '_tag' => 'a',
                    title => 'View more images',
                );

                my $second_image_tag = $gallery_link->look_down('_tag' => 'img',);
                my $second_image = $second_image_tag->attr('src');

                my ($downlad_link_tag) = $font_page_tree->look_down(
                    '_tag' => 'a',
                    title => "Download free font $font_name",
                );

                my $download_link;
                if($downlad_link_tag) {
                    $download_link = $downlad_link_tag->attr('href');
                }
                else { 
                    warn "No download link found on page: ${site}${font_page} for font: ${font_name} - skip\n";
                    next;
                }

                my ($category_section) = $font_page_tree->look_down('class', 'inline', '_tag', 'ul');
                my @category_links = $category_section->look_down('_tag', 'a');

                my @categories = map($_->as_text, @category_links);

                my ($author_name_h2) = $font_page_tree->look_down('class', 'inline', '_tag', 'h2');
                my $author_name = $author_name_h2->as_text;

                my ($license_tag) = $font_page_tree->look_down('title', 'See details for this license');
                my $license;
                if($license_tag) {
                    $license = $license_tag->as_text;
                }

                my ($contact_tag) = $font_page_tree->look_down(
                    '_tag' => 'a',
                    class => 'button',

                    sub {
                        return unless $_[0]->as_text() eq 'Contact Designer';
                    }
                );

                my $author_email;
                if($contact_tag) {
                    $contact_tag->attr('href') =~ m{^mailto:(.*)\?};
                    $author_email = $1;
                }

                my ($author_site_section) = $font_page_tree->look_down(
                    '_tag' => 'blockquote',              
                );

                my $author_website;
                if($author_site_section) {
                    my ($author_website_link) = $author_site_section->look_down(
                        '_tag' => 'a',
                        target => '_blank',
                        rel => 'no-follow',
                    );

                    if($author_website_link) {
                        $author_website = $author_website_link->attr('href');
                    }
                }

                my @author_name = split(/ /, $author_name);
                my $last_name = pop @author_name;
                my $first_name = join(' ', @author_name);

                unless(is_within_latin_1(${first_name}.${last_name})) {
                    next;
                }

                my $cache_key_author_id = "author_exists::${first_name}${last_name}";
                $cache_key_author_id = Digest::MD5::md5_hex($cache_key_author_id);

                my $author_id = $c->cache->get($cache_key_author_id);

                unless(defined $author_id) {
                    $author_id = $c->model('DB::Author')->get_or_create_author_id_by_first_and_last_name($c, $author_email, $first_name, $last_name, $author_website);
                    $c->cache->set($cache_key_author_id, $author_id, (60*60*24*3));
                }

                my $web_font_name = $c->forward('/spider/web_encode', [$font_name]);

                my $model = $c->model('DB::Font');

                my $cache_key = "font_exists::${web_font_name}";
                $cache_key = Digest::MD5::md5_hex($cache_key);

                my $font_exists = $c->cache->get($cache_key);

                unless ($font_exists) {

                    $font_exists = $model->check_if_font_exists_by_html_encoded_name_and_author_id($c, $web_font_name, $author_id);
                    $c->cache->set($cache_key, $font_exists, (60*60*24*3));

                }

                if(!$font_exists) {

                    my $license_id;
                    if($license) {
                        $license_id = $c->model('DB::License')->get_or_create_license_id_by_name($c, $license);
                    }

                    my $font_rs = $schema->resultset('Font');
                    my ($font_insert) = $font_rs->create(
                        { 
                            name => $font_name,
                            web_name => $web_font_name,
                            license =>$license_id,
                            author =>$author_id,
                        },
                    );

                    my $id = $font_insert->id;

                    $c->cache->remove($cache_key);

                    my $model = $c->model('DB::Category');
                    foreach my $font_category (@categories) {

                        my $font_category_id = $model->get_or_create_category_id_by_category_name($c, $font_category);

                        if($font_category =~ 'Måns Grebäck') {
                            
                        }

                        my $category_result;
                        if($id && $font_category_id) {

                            my $category_rs = $schema->resultset('CategoryFont');

                            ($category_result) = $category_rs->create(
                                {
                                    category => $font_category_id,
                                    font => $id,
                                },
                            );

                            my $other_id = $category_result->id;
                        }
                        else {
                            warn "One of the INSERT queries failed. (font:$id) && (category:$font_category_id) \n";
                        }
                    }

                    my $uploaddir = $c->path_to(qw[ root static ]) . '/fonts/';
                    mkdir $uploaddir.'/'.$id or die $!;
                    $uploaddir = $uploaddir.$id.'/';

                    download_file(
                        $c,
                        $mech,
                        ${site}.$main_font_image,
                        "${uploaddir}${web_font_name}"
                    );

                    download_file(
                        $c,
                        $mech,
                        ${site}.$second_image,
                        "${uploaddir}${web_font_name}-2"
                    );

                    download_file(
                        $c,
                        $mech,
                        ${site}.$download_link,
                        "${uploaddir}${web_font_name}"
                    );

                    my $category_text = join(', ', @categories); # temp

                    warn "DOWNLOADED FONT: $font_name, $web_font_name\n";

                }
                else {
                    warn "Font already exists in DB. Skip.\n";
                }

            }

        }
    }

}

sub download_file {
    my ($c, $mech, $download, $location) = @_;

    $c->forward('/spider/throttle');

    $mech->get($download);

    my $file_extension;
    if($download =~ m{\.([A-Za-z]+)$}) {
        $file_extension = $1;
    }
    else {
        warn "Coulnd't grab file extension.\n";
    }

    my $content_type = $mech->content_type();

    my %content_type = (
        zip => 'application/zip',
        png => 'image/png',
        jpg => 'image/jpeg',
        jpeg => 'image/jpeg',
        gif => 'image/gif'
    );

    if(lc($content_type{lc($file_extension)}) eq lc($content_type)) {
        $mech->save_content( $location.'.'.$file_extension );
        die "Couldn't download: $download: ", $mech->response->status_line
        unless $mech->success;
    }
    elsif(!$content_type) {
        warn "$download did not have a content type header. - skip download\n";
    }
    else {
        warn "Download cancelled -- File expected to be $content_type{$file_extension} | .$file_extension, but was actually $content_type on $download.\n";
    }
    
    return $mech->success;

}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
