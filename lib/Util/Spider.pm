package Util::Spider;

use strict;
use warnings;
use Digest::MD5 ();

use WWW::Mechanize;
use HTML::TreeBuilder;
use Digest::MD5;
use POSIX;
use Data::Dumper;
use Time::HiRes qw( usleep );

use constant THROTTLE => 1;

sub create_mech_object {
    my $mech = WWW::Mechanize->new( autocheck => 0 );
    $mech->agent_alias( 'Windows IE 6' );
    $mech->stack_depth( 0 );

    return $mech;
}

sub return_only_zip_files {
    my ( $c, $list ) = @_;

    my @zip_list;
    foreach my $item (@$list) {
        if( $item =~ m{\/([A-Za-z0-9]+)\.zip$} ) {
            push @zip_list, $1;
        }
    }

    return \@zip_list;
}

sub uniq {
    my ( $c, $list ) = @_;

    my @list = @$list;

    my %seen = ();
    my @r = ();
    foreach my $a ( @list ) {
        unless ($seen{$a}) {
            push @r, $a;
            $seen{$a} = 1;
        }
    }
    return \@r;
}

sub get_hrefs_from_element {
    my ( $c, $elements ) = @_;
    
    my @link_list;
    foreach my $element (@$elements) {
        my @links = $element->look_down(
            '_tag', 'a',
            sub {
                return unless $_[0]->attr('href');
            }
        );
        foreach my $link (@links) {
            push @link_list, $link->attr('href');
        }
    }

    return \@link_list;
}

sub get_img_src_from_element {
    my ( $c, $elements ) = @_;
    
    my @src_list;
    foreach my $element (@$elements) {
        my @imgs = $element->look_down(
            '_tag', 'img',
            sub {
                return unless $_[0]->attr('src');
            }
        );
        foreach my $img (@imgs) {
            push @src_list, $img->attr('src');
        }
    }

    return \@src_list;
}

sub throttle {
    if(THROTTLE) {
        #my $random = ceil(rand(2) + 1);
        my $random = 500000;
        #sleep $random; 
        #warn("THROTTLED: Waited $random seconds before requesting page.");
        usleep ($random);
        return $random; 
    } 
}

sub get_page_content {

    my ( $cache, $url, $mech, $skip_cache ) = @_;

    my $cache_key = Digest::MD5::md5_hex("visited::${url}");

    my $content = $cache->get($cache_key);

    if(!$content || $skip_cache) {
        throttle();

        warn "Not looking in cache store for request.\n" if $skip_cache;

        $mech->get( $url );
        if ($mech->success) {
            warn "Get content for: $url\n";
       
            $content = $mech->response->decoded_content;
            my $success = $cache->set($cache_key, $content);

        }
        else {
            warn "Mech failure.\n"; 
            warn $mech->status();

            return;
        }
    }
    else {
        warn "$url has already been spidered within the past 3 days. Pulled from cache.\n";
    }

    return $content;
}

=head2

Downloads a file ($download - full url), and puts it into a specified location ($location - full path).
Does basic content header checks for a handful of file types.

=cut

sub download_file {
    my ($mech, $download, $location) = @_;

    throttle();

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
        $mech->save_content( $location.'.'.lc($file_extension) );
        #$c->log->warn('Saved: ' . $location.'.'.lc($file_extension));
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

sub web_encode {

    my ( $c, $web_font_name ) = @_;

    $web_font_name =~ s/\s+//g;
    $web_font_name =~ s/\///g;

    return $web_font_name;
}

1;
