use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Fonts::Download;

ok( request('/fonts/download')->is_success, 'Request should succeed' );
done_testing();
