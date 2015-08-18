use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Harvest';
use Harvest::Controller::Contact;

ok( request('/contact')->is_success, 'Request should succeed' );
done_testing();
