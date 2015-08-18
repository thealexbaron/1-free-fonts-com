use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Signup;

ok( request('/signup')->is_success, 'Request should succeed' );
done_testing();
