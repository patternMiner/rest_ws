use strict;
use warnings;
use CP::ContentPipeline;
use CP::Download;
use CP::Extract;
use File::Slurp qw(read_file);
use File::Temp qw(tempdir);
use JSON;
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
        _verify_content_pipeline( $test->{params} );
    };
}

done_testing();

sub _verify_content_pipeline {
    my ($params) = @_;

    my @locations = ( join( '/', $config->{storage_pool}, 'a' ), );
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
    $params->{request_params}->{ctx} =
      UnitTesting::Harness::create_test_app_context();

    my $pipeline;
    if ( $params->{expect_construction_to_succeed} ) {
        ok(
            lives {
                $pipeline =
                  CP::ContentPipeline->new( $params->{request_params} );
            },
            "Pipeline construction succeeds - as expected."
        );

        my $result =
          $pipeline->add_step( CP::Download->new( name => 'download' ) )
          ->add_step( CP::Extract->new( name => 'extract' ) )->execute();

        is( $result, $params->{expected_result}, "The result looks correct." );

        if ( $params->{expect_download_to_succeed} ) {
            my $downloaded_blob = $pipeline->state->{downloaded_blob};
            ok( -f $downloaded_blob,
                "The downloaded_blob file: $downloaded_blob exists." );
        }

        if ( $params->{expect_extract_to_succeed} ) {
            my $extract_location =
              join( '/', $allocated_location, $pipeline->state->{basename} );
            ok( -d $extract_location,
                "The extract_location dir: $extract_location exists." );
            foreach my $file ( @{ $params->{expect_extracted_files} } ) {
                ok( -f "$extract_location/$file",
                    "The file: $extract_location/$file exists." );
                is( read_file("$extract_location/$file"), $file_content,
                    "The file: $extract_location/$file contents look correct."
                );
            }
        }
    }
    else {
        ok(
            dies {
                $pipeline =
                  CP::ContentPipeline->new( $params->{request_params} );
            },
            "Pipeline construction fails - as expected."
        );
    }
}

sub _get_test_data {
    return UnitTesting::Harness::load_test_data(<<TEST);
-
  name: 'Test content pipeline, with valid parameters'
  params:
    request_params:
        url: "$url"
        size: '1M'
    expect_construction_to_succeed: 1
    expect_dowload_to_succeed: 1
    expect_extract_to_succeed: 1
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
        url: "file://home/blah/blah.tar"
        size: '1M'
    expect_construction_to_succeed: 1
    expected_result:
        errors:
            -
                application_error: "Failed to download the url: file://home/blah/blah.tar."
        items: []
-
  name: 'Test content pipeline, with missing parameters'
  params:
    request_params:
        url: "$url"
    expect_construction_to_succeed: 0
TEST
}
