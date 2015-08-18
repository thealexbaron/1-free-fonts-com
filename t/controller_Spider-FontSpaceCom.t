use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Spider::FontSpaceCom;

ok( request('/spider/fontspacecom')->is_success, 'Request should succeed' );
done_testing();
