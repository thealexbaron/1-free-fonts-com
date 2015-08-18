use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::User::Settings;

ok( request('/user/settings')->is_success, 'Request should succeed' );
done_testing();
