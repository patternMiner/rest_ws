use strict;
use warnings;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('RestWs');

# Test welcome page.
$t->get_ok('/')
  ->status_is(200)
  ->json_is( { version => '0.0.0', service_name => 'Mods HW Test Service' } );

done_testing();
