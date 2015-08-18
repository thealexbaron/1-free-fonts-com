use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Spider;

ok( request('/spider')->is_success, 'Request should succeed' );
done_testing();
