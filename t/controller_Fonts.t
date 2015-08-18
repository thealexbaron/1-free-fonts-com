use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Fonts;

ok( request('/fonts')->is_success, 'Request should succeed' );
done_testing();
