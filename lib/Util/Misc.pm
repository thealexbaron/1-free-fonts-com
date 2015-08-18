package Util::Misc;

use strict;
use warnings;

sub check_if_file_exists {
    my ($c, $file) = @_;

    return -f $file;
}

1;
