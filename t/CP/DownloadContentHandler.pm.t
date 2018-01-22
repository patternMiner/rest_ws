use strict;
use warnings;
use CP::ContentPipeline;
use CP::Download;
use CP::Extract;
use File::Slurp qw(read_file);
use File::Temp qw(tempdir);
use JSON;
use Test::Mojo;
use Test2::V0;
use Test2::Plugin::BailOnFail;
use Type::Tiny;
use UnitTesting::Harness;

my $config        = UnitTesting::Harness::create_test_config();
my $test_data_dir = tempdir( CLEANUP => 1 );
my $file_content  = "Hello, World!";
my $url =
  UnitTesting::Harness::create_test_url( $test_data_dir, $file_content );
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
          get_storage  => sub { return shift(@locations); },
          free_storage => sub {
              my ( $self, $location );
              unshift( @locations, $location );
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
        POST: "/cp/v0/content?url=$url&size=1M"
    expect_extracted_files:
        -
            "awesome/foo"
        -
            "awesome/bar"
    expected_result:
        items:
            -
                allocated_location: "$allocated_location"
        errors: []
-
  name: 'Test content pipeline, with invalid parameters'
  params:
    request_params:
        POST: "/cp/v0/content?url=file://home/blah/blah.tar&size=1M"
    expected_result:
        errors:
            -
                application_error: "Failed to download the url: file://home/blah/blah.tar."
        items: []
-
  name: 'Test content pipeline, with missing parameters'
  params:
    request_params:
        POST: "/cp/v0/content?size=1M"
    expected_result:
        errors:
            -
                missing_parameter: "url is a required parameter."
        items: []
TEST
}
