package Harvest::Controller::Spider;
use Moose;
use namespace::autoclean;

use WWW::Mechanize;
use HTML::TreeBuilder;
use Digest::MD5;
use POSIX;

use Proc::Daemon;

use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }

use constant THROTTLE => 1;

=head1 NAME

Harvest::Controller::Spider - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    die "You don't want to be in here. Trust me.\n";
    
    my $uploaddir = $c->path_to(qw[ root static ]) . '/fonts/';
    my $mech = $c->forward('/spider/create_mech_object');

    use Data::Dumper;

    my $content = $c->forward('/spider/get_page_content', ['http://www.fontspace.com/', $mech]);

    warn Dumper($mech->res());

    my $download_link = 'http://www.fontspace.com/download/10318/da443a08254c4a12aec27c7d3fb21655/kimberly-geswein_airplanes-in-the-night-sky.zip';
    my $save_as_name = 'AirplanesintheNightSky';

    #http://www.fontspace.com/download/11086/720515c5ebea48b480b202259b953e79/billy-argel_punkbabe.zip

    #$mech->add_header( Referer => 'http://www.fontspace.com/category/futuristic' );
    #$mech->add_header( Host => 'www.fontspace.com' );
    #$mech->add_header( 'user-agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.122 Safari/534.30' );

    $mech->add_header( cookie => '__qca=P0-1369860372-1303591276228; ASP.NET_SessionId=i412rlwwda0vfzygpgeqnrvh; __utma=267227801.1032345197.1303591276.1311524270.1311532282.12; __utmb=267227801.2.10.1311532282; __utmc=267227801; __utmz=267227801.1311532282.12.12.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=fantasy%20font' );

    $mech->get($download_link);
    $mech->save_content( "${uploaddir}${save_as_name}.zip" );
    warn "Couldn't download: '$save_as_name': ", $mech->response->status_line
    unless $mech->success;

    #use Data::Dumper;
    #warn Dumper($mech->res());



    #TODO: when this is running on production, all logging should go to it's own file, and this controller should be run as it's own process
    # and update memcache along the way so we can use another controller to check its status.

=comment
1
    my $daemon = Proc::Daemon->new(
        work_dir => '/tmp/daemon',
    );

    my $Kid_1_PID = $daemon->Init;

    my $pid = $daemon->Status();

    warn $pid;
    return 0;
=cut
    
    # Enough experiments, Now the real program begins...


}

sub create_mech_object : Private {
    my ( $self, $c ) = @_;

    my $mech = WWW::Mechanize->new( autocheck => 1 );

    return $mech;
}


sub return_only_zip_files : Private {
    my ( $self, $c, $list ) = @_;

    my @zip_list;
    foreach my $item (@$list) {
        if( $item =~ m{\/([A-Za-z0-9]+)\.zip$} ) {
            push @zip_list, $1;
        }
    }

    return \@zip_list;
}

sub uniq : Private {
    my ( $self, $c, $list ) = @_;

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

sub get_hrefs_from_element : Private {
    my ( $self, $c, $elements ) = @_;
    
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

sub get_img_src_from_element : Private {
    my ( $self, $c, $elements ) = @_;
    
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

sub throttle : Private {
    my ( $self, $c ) = @_;
    if(THROTTLE) {
        my $random = ceil(rand(5) + 1); 
        sleep $random; 
        #warn("THROTTLED: Waited $random seconds before requesting page.");
        return $random; 
    } 
}

sub get_page_content : Private {

    my ( $self, $c, $url, $mech, $skip_cache ) = @_;

    my $cache_key = "visited::${url}";
    #warn $cache_key;
    $cache_key = Digest::MD5::md5_hex($cache_key);

    my $content = $c->cache->get($cache_key);
    #my $content;

    if(!$content || $skip_cache) {
        $c->forward('/spider/throttle');

        warn "Not looking in cache store for request.\n" if $skip_cache;

        $mech->get( $url );
        if ($mech->success) {
            warn "Get content for: $url\n";
       
            $content = $mech->response->decoded_content;
                my $success = $c->cache->set($cache_key, $content, (60*60*24*3));

        }
        else {
            warn $mech->status_line;
            return;
        }
    }
    else {
        warn "$url has already been spidered within the past 3 days. Pulled from cache.\n";
    }

    return $content;
}

sub web_encode : Private {

    my ( $self, $c, $web_font_name ) = @_;

    $web_font_name =~ s/\s+//g;
    $web_font_name =~ s/\///g;

    return $web_font_name;
}

sub progress : Local {
    my ( $self, $c ) = @_;
    $c->serve_snippet;
}



=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
