use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Font;

ok( request('/font')->is_success, 'Request should succeed' );
done_testing();
