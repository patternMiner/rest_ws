use strict;
use warnings;
use CP::DownloadContentHandler;
use File::Slurp qw(read_file);
use File::Temp qw(tempdir);
use JSON;
use Result;
use Test::Mojo;
use Test2::V0;
use Test2::Plugin::BailOnFail;
use Type::Tiny;
use UnitTesting::Harness;

my $config        = UnitTesting::Harness::create_test_config();
my $test_data_dir = tempdir( CLEANUP => 1 );
my $file_content  = "Hello, World!";
my $content_blob =
  UnitTesting::Harness::create_test_file( $test_data_dir, $file_content );
my $crc = CP::DownloadContentHandler::get_crc($content_blob);
my $content_url = "file:/$content_blob";
my $allocated_location = join( '/', $config->{storage_pool}, 'a' );
my $test_data = _get_test_data();

foreach my $test ( @{$test_data} ) {
    subtest $test->{name} => sub {
          _verify_download_content_handler( $test->{params} );
    };
}

done_testing();

sub _verify_download_content_handler {
    my ($params) = @_;

    my @locations = (
      join( '/', $config->{storage_pool}, 'a' ),
    );
    foreach my $location (@locations) {
        mkdir $location;
    }
    my $mock_sm = mock(
      'CP::StorageManager' => (
        override => [
          new => sub { return bless {}, 'CP::StorageManager' },
          get_storage  => sub {
              return
                Result->new()->push_item({ provisioned_location => shift(@locations) });
          },
          free_storage => sub {
              my ( $self, $provisioned_location );
              unshift( @locations, $provisioned_location );
              return Result->new();
          }
        ]
      )
    );
    my $t = Test::Mojo->new( 'RestWs' => $config );
    my $tx = $t->ua->build_tx( %{ $params->{request_params} } );

    $t->request_ok($tx)->status_is(200)->json_is( $params->{expected_result} );
}

sub _get_test_data {
    return UnitTesting::Harness::load_test_data(<<TEST);
-
  name: 'Test content pipeline, with valid parameters'
  params:
    request_params:
        POST: "/cp/v0/content?crc=$crc&content_url=$content_url&max_size=1M"
    expect_extracted_files:
        -
            "awesome/foo"
        -
            "awesome/bar"
    expected_result:
        items:
            -
                provisioned_location: "$allocated_location"
        errors: []
-
  name: 'Test content pipeline, with invalid parameters'
  params:
    request_params:
        POST: "/cp/v0/content?crc=$crc&content_url=file://home/blah/blah.tar&max_size=1M"
    expected_result:
        errors:
            -
                application_error: "Failed to download the content_url: file://home/blah/blah.tar"
        items: []
-
  name: 'Test content pipeline, with missing parameters'
  params:
    request_params:
        POST: "/cp/v0/content?crc=$crc&max_size=1M"
    expected_result:
        errors:
            -
                missing_parameter: "content_url is a required parameter."
        items: []
TEST
}
