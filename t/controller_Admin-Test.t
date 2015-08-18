use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Admin::Test;

ok( request('/admin/test')->is_success, 'Request should succeed' );
done_testing();
