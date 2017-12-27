use strict;
use warnings;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('RestWs');

# Test upload content.
$t->put_ok('/cp/v0/content?local_location=/tmp/local&allocated_location=/tmp/allocated')
  ->status_is(200)
  ->json_is(
    {
        errors => [],
        items  => []
    }
);

# Test download content.
$t->get_ok('/cp/v0/content?local_location=/tmp/local&allocated_location=/tmp/allocated')
    ->status_is(200)
    ->json_is(
    {
        errors => [],
        items  => []
    }
);

done_testing();
