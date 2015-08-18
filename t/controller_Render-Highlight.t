use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Render::Highlight;

ok( request('/render/highlight')->is_success, 'Request should succeed' );
done_testing();
