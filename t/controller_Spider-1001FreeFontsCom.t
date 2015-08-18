use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Spider::1001FreeFontsCom;

ok( request('/spider/1001freefontscom')->is_success, 'Request should succeed' );
done_testing();
