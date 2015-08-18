use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Render::List;

ok( request('/render/list')->is_success, 'Request should succeed' );
done_testing();
