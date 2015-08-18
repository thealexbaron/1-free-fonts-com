package Template::CatalystConfig;

use strict;
use warnings;
use Carp;
use Config::JFDI;
use base 'Template';

my $cat_app_name = $ENV{CATALYST_APP_NAME};
my $cat_cfg_path = $ENV{CFGPATH};

unless ($cat_app_name) {
    croak("Set CATALYST_APP_NAME to the name of your application (e.g. MyApp) so I can find the MyApp.conf files!");
}
unless ($cat_cfg_path) {
    croak("Set CFGPATH to the path to search for MyApp.conf files!");
}

my $jfdi = Config::JFDI->new(
    name => $cat_app_name,
    path => $cat_cfg_path,
);

my $cat_config = $jfdi->get;

#die Data::Dumper->Dump([$cat_config],['cat_config']);

sub process {
    my ($self, $template, $vars, $outstream, @opts) = @_;

    $vars->{c}{config} = $cat_config;

    return $self->SUPER::process($template, $vars, $outstream, @opts);
}


1;
