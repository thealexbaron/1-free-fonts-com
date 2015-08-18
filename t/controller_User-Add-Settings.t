use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::User::Add::Settings;

ok( request('/user/add/settings')->is_success, 'Request should succeed' );
done_testing();
