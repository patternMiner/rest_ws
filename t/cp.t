use strict;
use warnings;
use UnitTesting::Harness;
use JSON;
use Test::Mojo;
use Test2::V0;
use Test2::Plugin::BailOnFail;

my $config = UnitTesting::Harness::create_test_config();
my $test_data = _get_test_data( );

foreach my $test ( @{$test_data} ) {
    subtest $test->{name} => sub {
          _verify_cp_api(
            request_params  => $test->{request_params},
            expected_result => $test->{expected_result}
          );
    };
}

done_testing();

sub _verify_cp_api {
    my (%params) = @_;

    my $t = Test::Mojo->new('RestWs' => $config);
    my $tx = $t->ua->build_tx(%{ $params{request_params} });

    $t->request_ok($tx)
      ->status_is(200)
      ->json_is($params{expected_result});
}

sub _get_test_data {
    my $test_data_yml = <<TEST;
-
  name: 'Test upload content'
  request_params:
    PUT: '/cp/v0/content?local_location="foo"&allocated_location="bar"'
  expected_result:
    items: []
    errors: []

-
  name: 'Test download content'
  request_params:
    GET: '/cp/v0/content?local_location="foo"&allocated_location="bar"'
  expected_result:
    items: []
    errors: []

TEST

    my $test_data = UnitTesting::Harness::load_test_data($test_data_yml);

    return $test_data;
}
