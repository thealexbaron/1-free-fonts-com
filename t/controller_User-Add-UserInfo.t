use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::User::Add::UserInfo;

ok( request('/user/add/userinfo')->is_success, 'Request should succeed' );
done_testing();
