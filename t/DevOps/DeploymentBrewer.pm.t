
=head1 deployment_brewer

Data driven unit tests for DevOps::DeploymentBrewer

=head1 SEE ALSO

DevOps::DeploymentBrewer

=cut

#!/usr/bin/perl
use strict;
use warnings;
use File::Temp qw(tempdir);
use DevOps::DeploymentBrewer;
use Log::Any::Adapter qw(TAP);
use Log::Any qw( $log );
use Test2::V0;
use Test2::Plugin::BailOnFail;
use YAML::XS;

my $test_data = _get_test_data();

foreach my $test ( @{$test_data} ) {
    subtest $test->{name} => sub {
        foreach my $verification ( @{ $test->{verifications} } ) {
            _verify( $verification->{verify}, $verification->{params} );
        }
    };
}

done_testing();

sub _verify {
    my ( $verify, $params ) = @_;

    $log->infof("params: %s", $params->{request_params});
    my $result =
        DevOps::DeploymentBrewer::brew( $params->{request_params} );
    $log->infof("result: %s", $result);

    is( $result->to_hashref(), $params->{expected_result}, $verify );
}

sub _get_test_data {
    my $storage_pool    = tempdir( CLEANUP => 1 );
    my $deployment_root = tempdir( CLEANUP => 1 );
    my $service_binary  = 'bin/rest_ws';
    my $test_data_yml   = <<TEST;
-
  name: 'brew rest_ws deployment'
  verifications:
    -
      verify: 'Brew with missing parameters'
      params:
        request_params:
            deployment_root: "$deployment_root"
            deployment_type: "uat"
            deployment_id: "dvs"
            service_binary: "$service_binary"
        expected_result:
            errors:
                -
                  application_error: "storage_pool is a required parameter"
            items: []
    -
      verify: 'Brew with invalid parameters'
      params:
        request_params:
            deployment_root: "$deployment_root"
            deployment_type: "uat"
            deployment_id: "dvs"
            storage_pool: "/tmp/blah/sm"
            service_binary: "$service_binary"
        expected_result:
            errors:
                -
                  invalid_arg: "/tmp/blah/sm doesn't exist."
            items: []
    -
      verify: 'Brew with valid parameters'
      params:
        request_params:
            deployment_root: "$deployment_root"
            deployment_type: "uat"
            deployment_id: "dvs"
            storage_pool: "$storage_pool"
            service_binary: "$service_binary"
        expected_result:
            errors: []
            items:
                -
                  "fresh_brew": "$deployment_root/uat/dvs"
    -
      verify: 'Brew over an existing one'
      params:
        request_params:
            deployment_root: "$deployment_root"
            deployment_type: "uat"
            deployment_id: "dvs"
            storage_pool: "$storage_pool"
            service_binary: "$service_binary"
        expected_result:
            errors:
                -
                  invalid_operation: "Can't clobber existing deployment"
            items: []
TEST

    my $test_data = YAML::XS::Load($test_data_yml);

    return $test_data;
}
