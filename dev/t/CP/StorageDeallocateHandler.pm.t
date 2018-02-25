#!/usr/bin/perl
use strict;
use warnings;

use File::Temp qw(tempdir);
use UnitTesting::Harness;
use Log::Any::Adapter qw(TAP);
use Log::Any qw($log);
use Test::Mojo;
use Test2::V0;
use Test2::Plugin::BailOnFail;

my $config = UnitTesting::Harness::create_test_config();
my $r = $ctx->storage_provider->get_storage('10K');
my $provisioned_location = $r->to_hashref()->{items}->[0]->{provisioned_location};
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

    $t->request_ok($tx);

    is ($tx->res->status, $params->{response_status}, 'Response status looks good.');

    is ($tx->res->json, $params->{expected_result}, 'Result looks good.');
}

sub _get_test_data {
    return UnitTesting::Harness::load_test_data(<<TEST);
-
  name: 'Test delete storage with valid parameters'
  params:
      request_params:
        DELETE: "/cp/v0/content?provisioned_location=$provisioned_location"
      response_status: 200
      expected_result:
        errors: []
        items:
          -
            provisioned_location: "$provisioned_location"

-
  name: 'Test delete storage with invalid parameters'
  params:
      request_params:
        DELETE: "/cp/v0/content?provisioned_location=shree420"
      response_status: 500

-
  name: 'Test delete storage with missing parameters'
  params:
      request_params:
        DELETE: "/cp/v0/content"
      response_status: 200
      expected_result:
        errors:
            -
                missing_parameter: "provisioned_location is a required parameter."
        items: []
TEST
}
