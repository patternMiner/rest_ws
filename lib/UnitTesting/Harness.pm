package UnitTesting::Harness;

use strict;
use warnings;

use AppContextBuilder;
use RestWs;
use Log::Any::Adapter ('Stderr');
use YAML::XS;


sub create_test_config {
    my ($sm_instance_home) = @_;

    my $config_yml = <<END;
# Your application's name
service_name: 'REST Web Service'

# version of this release
version: '0.0.0'
END

    my $config = YAML::XS::Load($config_yml);

    return $config;
}

sub create_test_app_context {

    my $ctx = HSMB::AppContextBuilder::build(
        service_name => 'REST Web Service',
        version      => '0.0.0',
    );

    return $ctx;
}

sub load_test_data {
    my ($test_data_yml) = @_;

    my $test_data = YAML::XS::Load($test_data_yml);

    return $test_data;
}

1;
