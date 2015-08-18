use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Admin::Utility;

ok( request('/admin/utility')->is_success, 'Request should succeed' );
done_testing();
