#!/usr/bin/perl
use strict;
use warnings;

use File::Temp qw(tempdir);
use UnitTesting::Harness;
use Log::Any::Adapter qw(TAP);
use Log::Any qw($log);
use StatusCodes;
use Test::Mojo;
use Test2::V0;
use Test2::Plugin::BailOnFail;

my $config  = UnitTesting::Harness::create_test_config();
my $provisioned_location = tempdir( DIR => $config->{storage_pool} );
my $test_data = _get_test_data();

foreach my $test ( @{$test_data} ) {
    subtest $test->{name} => sub {
          _verify_delete_storage_api( $test->{params} );
    };
}

done_testing();

sub _verify_delete_storage_api {
    my ($params) = @_;

    my $t = Test::Mojo->new( 'RestWs' => $config );
    my $tx = $t->ua->build_tx( %{ $params->{request_params} } );

    $t->request_ok($tx)->status_is( $params->{expected_status}, 'Response status looks good.' );
    if ($params->{expected_status} eq HTTP_NO_CONTENT) {
        is ("", $tx->res->json, "No content, as expected.");
    } else {
        is ($tx->res->json, $params->{expected_result}, 'Result looks good.');
    }
}

sub _get_test_data {
    return UnitTesting::Harness::load_test_data(<<TEST);
-
  name: 'Test delete storage with valid parameters'
  params:
      request_params:
        DELETE: "/cp/v0/content?provisioned_location=$provisioned_location"
      expected_status: "$StatusCodes::HTTP_NO_CONTENT"

-
  name: 'Test delete storage with invalid parameters'
  params:
      request_params:
        DELETE: "/cp/v0/content?provisioned_location=shree420"
      expected_status: "$StatusCodes::HTTP_BAD_REQUEST"
      expected_result:
        errors:
            -
                delete_error: "Failed to delete shree420."
        items: []

-
  name: 'Test delete storage with missing parameters'
  params:
      request_params:
        DELETE: "/cp/v0/content"
      expected_status: "$StatusCodes::HTTP_BAD_REQUEST"
      expected_result:
        errors:
            -
                missing_parameter: "provisioned_location is a required parameter."
        items: []
TEST
}
