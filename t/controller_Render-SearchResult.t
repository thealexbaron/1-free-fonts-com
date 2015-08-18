use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Render::SearchResult;

ok( request('/render/searchresult')->is_success, 'Request should succeed' );
done_testing();
