#!/usr/bin/perl
use strict;
use warnings;

use File::Slurp qw(read_file);
use File::Temp qw(tempdir);
use CP::StorageDeallocateHandler;
use UnitTesting::Harness;
use UnitTesting::MockSM;
use Log::Any::Adapter qw(TAP);
use Test2::V0;
use Test2::Plugin::BailOnFail;

my $provisioned_location = tempdir( CLEANUP => 1 );
my $ctx = UnitTesting::Harness::create_test_app_context();
my $storage_deallocate_handler = CP::StorageDeallocateHandler->new( ctx => $ctx );
my $test_data = get_test_data();

foreach my $test ( @{$test_data} ) {
    subtest $test->{name} => sub {
        _verify_storage_deallocation_handler( $test->{params} );
    };
}

done_testing();

sub _verify_storage_deallocation_handler {
    my ($params) = @_;

    my $exec_state = {};

    my $got_result =
        $storage_deallocate_handler->handle_request( $exec_state, $params->{request_params} );

    is ($got_result, $params->{expected_result}, 'Result looks correct.');
}

sub get_test_data {
    my $invalid_location = "/blah/blah";
    my $app_error = "Directory doesn't exist";
    return UnitTesting::Harness::load_test_data(<<TEST);
-
  name: 'Test storage deallocation, with valid parameters'
  params:
    request_params:
        provisioned_location: "$provisioned_location"
    expected_result:
        errors: []
        items:
            -
                deleted:
                    -
                        "$provisioned_location"
-
  name: 'Test storage deallocation, with valid parameters, but invalid storage'
  params:
    request_params:
        provisioned_location: "$invalid_location"
    expected_result:
        errors:
            -
                delete_error: "Failed to delete $invalid_location."
        items: []
-
  name: 'Test content pipeline, with missing provisioned_location'
  params:
    request_params:
    expected_result:
        errors:
            -
                missing_parameter: "provisioned_location is a required parameter."
        items: []
TEST
}
