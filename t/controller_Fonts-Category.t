use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Fonts::Category;

ok( request('/fonts/category')->is_success, 'Request should succeed' );
done_testing();
