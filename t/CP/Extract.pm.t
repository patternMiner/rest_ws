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

my $config = UnitTesting::Harness::create_test_config();
my $test_data_dir = tempdir( CLEANUP => 1 );
my $file_content = "Hello, World!";
my $url = UnitTesting::Harness::create_test_url($test_data_dir, $file_content);
my $allocated_location = join('/', $config->{storage_pool}, 'a');
my $test_data = _get_test_data( );

foreach my $test ( @{$test_data} ) {
    subtest $test->{name} => sub {
          _verify_extract_step($test->{params});
    };
}

done_testing();

sub _verify_extract_step {
    my ($params) = @_;

    my @locations = (
      join('/', $config->{storage_pool}, 'a'),
    );
    foreach my $location (@locations) {
        mkdir $location;
    }
    my $mock_sm = mock(
      'CP::StorageManager' => (
        override => [
          new => sub { return bless {}, 'CP::StorageManager' },
          get_storage => sub { return shift(@locations); },
          free_storage => sub {
              my ($self, $location);
              unshift(@locations, $location);
          }
        ]
      )
    );
    $params->{request_params}->{ctx} = UnitTesting::Harness::create_test_app_context();
    my $pipeline = CP::ContentPipeline->new($params->{request_params});
    my $result = $pipeline
      ->add_step(CP::Download->new(name => 'download'))
      ->add_step(CP::Extract->new(name => 'extract'))
      ->execute();

    is ($result, $params->{expected_result}, "The result looks correct.");

    if ($params->{check_pipeline_state}) {
        my $downloaded_blob = $pipeline->state->{downloaded_blob};
        ok (-f $downloaded_blob, "The downloaded_blob file: $downloaded_blob exists.")
    }
}

sub _get_test_data {
    return UnitTesting::Harness::load_test_data(<<TEST);
-
  name: 'Test extract step, with valid parameters'
  params:
    request_params:
        url: "$url"
        size: '1M'
    check_pipeline_state: 1
    expected_result:
        items:
            -
                allocated_location: "$allocated_location"
        errors: []
-
  name: 'Test extract step, with invalid parameters'
  params:
    request_params:
        url: "$url"
        size: 'bogus'
    expected_result:
        errors:
            -
                invalid_parameter: 'bogus is not a valid size'
        items: []
TEST
}
