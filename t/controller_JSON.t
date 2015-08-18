use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::JSON;

ok( request('/json')->is_success, 'Request should succeed' );
done_testing();
