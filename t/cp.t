use strict;
use warnings;
use File::Temp qw(tempdir);
use JSON;
use Test::Mojo;
use Test2::V0;
use Test2::Plugin::BailOnFail;
use UnitTesting::Harness;

my $config = UnitTesting::Harness::create_test_config();
my $test_data_dir = tempdir( CLEANUP => 1 );
my $url = UnitTesting::Harness::create_test_url($test_data_dir, "Hello, World!");
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

    my @locations = (
      join('/', $config->{storage_pool}, 'a'),
      join('/', $config->{storage_pool}, 'b'),
      join('/', $config->{storage_pool}, 'c'),
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
    my $t = Test::Mojo->new('RestWs' => $config);
    my $tx = $t->ua->build_tx(%{ $params{request_params} });

    $t->request_ok($tx)
      ->status_is(200)
      ->json_is($params{expected_result});
}

sub _get_test_data {
    my $allocated_location = join('/', $config->{storage_pool}, 'a');
    return UnitTesting::Harness::load_test_data(<<TEST);
-
  name: 'Test download content'
  request_params:
    POST: "/cp/v0/content?url=$url"
  expected_result:
    items:
        -
            allocated_location: "$allocated_location"
    errors: []

TEST
}
