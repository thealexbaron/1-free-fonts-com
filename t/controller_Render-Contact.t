use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Render::Contact;

ok( request('/render/contact')->is_success, 'Request should succeed' );
done_testing();
