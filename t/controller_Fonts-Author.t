use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Fonts::Author;

ok( request('/fonts/author')->is_success, 'Request should succeed' );
done_testing();
