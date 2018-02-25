#!/usr/bin/perl
use strict;
use warnings;

use File::Slurp qw(read_file);
use File::Temp qw(tempdir);
use CP::DownloadContentHandler;
use UnitTesting::Harness;
use Log::Any::Adapter qw(TAP);
use Test2::V0;
use Test2::Plugin::BailOnFail;

my $provisioned_location = tempdir( CLEANUP => 1 );
my $test_data_dir        = tempdir( CLEANUP => 1 );
my $file_content         = "Hello, World!";
my $content_file =
  UnitTesting::Harness::create_test_file( $test_data_dir, $file_content );
my $crc = CP::DownloadContentHandler::get_crc($content_file);
my $content_url = "file:/$content_file";
my $test_data = get_test_data();
my $ctx = UnitTesting::Harness::create_test_app_context();
my $download_content_handler = CP::DownloadContentHandler->new( ctx => $ctx );

foreach my $test ( @{$test_data} ) {
    subtest $test->{name} => sub {
        _verify_download_content_handler( $test->{params} );
    };
}

done_testing();

sub _verify_download_content_handler {
    my ($params) = @_;

    my $exec_state = {};
    my $mock_sm =
      UnitTesting::MockSM::create_mock_storage_manager(
        $params->{allocation_result} );

    my $got_result =
        $download_content_handler->handle_request( $exec_state, %{ $params->{request_params} } );

    is ($got_result, $params->{expected_result}, 'Result looks correct.');

    if ( $params->{expect_download_to_succeed} ) {
        my $downloaded_blob = $exec_state->{downloaded_blob};
        ok( not (-f $downloaded_blob),
            "The downloaded_blob file: $downloaded_blob is deleted." );
    }

    if ( $params->{expect_extract_to_succeed} ) {
        my $extract_location =
            join( '/', $provisioned_location, $exec_state->{basename} );
        ok( -d $extract_location,
            "The extract_location dir: $extract_location exists." );
        foreach my $file ( @{ $params->{expect_extracted_files} } ) {
            ok( -f "$extract_location/$file",
                "The file: $extract_location/$file exists." );
            is( read_file("$extract_location/$file"),
                $file_content,
                "The file: $extract_location/$file contents look correct." );
        }
    }
}

sub get_test_data {
    my $invalid_location = "/blah/blah";
    my $app_error = "Directory doesn't exist";
    return UnitTesting::Harness::load_test_data(<<TEST);
-
  name: 'Test content pipeline, with valid parameters'
  params:
    allocation_result:
        provisioned_location: "$provisioned_location"
    request_params:
        content_url: "$content_url"
        crc: "$crc"
        package_size: '1M'
    expect_download_to_succeed: 1
    expect_extract_to_succeed: 1
    expect_extracted_files:
        -
            "awesome/foo"
        -
            "awesome/bar"
    expected_result:
        items:
            -
                mods_image_id: "$provisioned_location"
        errors: []
-
  name: 'Test content pipeline, with valid parameters, but invalid storage'
  params:
    allocation_result:
        provisioned_location: "$invalid_location"
    request_params:
        content_url: "$content_url"
        crc: "$crc"
        package_size: '1M'
    expect_download_to_succeed: 1
    expect_extract_to_succeed: 0
    expected_result:
        errors:
            -
                application_error: "$app_error"
        items: []
-
  name: 'Test content pipeline, with invalid url'
  params:
    allocation_result:
        provisioned_location: "$provisioned_location"
    request_params:
        content_url: "file://home/blah/blah.tar"
        crc: "$crc"
        package_size: '1M'
    expected_result:
        errors:
            -
                application_error: "Failed to download the content_url: file://home/blah/blah.tar"
        items: []
-
  name: 'Test content pipeline, with invalid package_size'
  params:
    allocation_result:
        provisioned_location: "$provisioned_location"
    request_params:
        content_url: "file://home/blah/blah.tar"
        crc: "$crc"
        package_size: '5Y'
    expected_result:
        errors:
            -
                invalid_parameter: "5Y is not a valid package_size."
        items: []
-
  name: 'Test content pipeline, with missing package_size'
  params:
    allocation_result:
        provisioned_location: "$provisioned_location"
    request_params:
        content_url: "$content_url"
        crc: "$crc"
    expected_result:
        errors:
            -
                missing_parameter: "package_size is a required parameter."
        items: []
-
  name: 'Test content pipeline, with missing crc'
  params:
    allocation_result:
        provisioned_location: "$provisioned_location"
    request_params:
        content_url: "$content_url"
        package_size: '1M'
    expected_result:
        errors:
            -
                missing_parameter: "crc is a required parameter."
        items: []
-
  name: 'Test content pipeline, with missing crc and invalid package_size'
  params:
    allocation_result:
        provisioned_location: "$provisioned_location"
    request_params:
        content_url: "file://home/blah/blah.tar"
        package_size: '9U'
    expected_result:
        errors:
            -
                missing_parameter: "crc is a required parameter."
            -
                invalid_parameter: "9U is not a valid package_size."
        items: []
TEST
}
