
=head1 service_manager

Data driven unit tests for DevOps::ServiceManager

=head1 SEE ALSO

DevOps::ServiceManager

=cut

#!/usr/bin/perl
use strict;
use warnings;
use FindBin ();
use File::Temp qw( tempdir );
use DevOps::DeploymentBrewer;
use DevOps::ServiceManager;
use Log::Any::Adapter ('TAP');
use Log::Any qw( $log );
use Test2::V0;
use Test2::Plugin::BailOnFail;
use YAML::XS;

my $service_binary  = 'bin/rest_ws';
my $storage_pool    = tempdir( CLEANUP => 1 );
my $deployment_root = tempdir( CLEANUP => 1 );
my $deployment      = _create_test_deployment();
my $test_data       = _get_test_data();

foreach my $test ( @{$test_data} ) {
    subtest $test->{name} => sub {
        foreach my $verification ( @{ $test->{verifications} } ) {
            _verify( $verification->{verify}, $verification->{params} );
        }
    };
}

_cleanup_test_deployment();

done_testing();

sub _verify {
    my ( $verify, $params ) = @_;

    $log->infof("params: %s", $params->{request_params});
    my $result =
        DevOps::ServiceManager::perform( $params->{request_params} );
    $log->infof("result: %s", $result->to_hashref());

    is( $result->to_hashref(), $params->{expected_result}, $verify );
}

sub _get_test_data {
    my $test_data_yml = <<TEST;
-
  name: 'service start|stop rest_ws deployments'
  verifications:
    -
      verify: 'start valid deployment'
      params:
        request_params:
            deployment: "$deployment"
            action: "start"
        expected_result:
            errors: []
            items:
                -
                    started: "$deployment"
    -
      verify: 'start an already started deployment'
      params:
        request_params:
            deployment: "$deployment"
            action: "start"
        expected_result:
            errors:
                -
                    invalid_action: "$deployment is already started."
            items: []
    -
      verify: 'stop valid deployment'
      params:
        request_params:
            deployment: "$deployment"
            action: "stop"
        expected_result:
            errors: []
            items:
                -
                    stopped: "$deployment"
    -
      verify: 'stop an already stopped deployment'
      params:
        request_params:
            deployment: "$deployment"
            action: "stop"
        expected_result:
            errors:
                -
                    invalid_action: "$deployment is already stopped."
            items: []
TEST

    my $test_data = YAML::XS::Load($test_data_yml);

    return $test_data;
}

sub _create_test_deployment {
    my $params = {
      storage_pool => $storage_pool,
      deployment_root => $deployment_root,
      service_name => '_unit_test_',
      service_port => '0',
      service_binary => $service_binary,
    };

    my $result = DevOps::DeploymentBrewer::brew($params);
    die sprintf("Caught errors: %s", $result->to_hashref()->{errors})
      if ( $result->is_error() );

    return sprintf( "%s/test/test", $params->{deployment_root} );
}

sub _cleanup_test_deployment {
    my $rest_ws_process_pid_cmd =
      sprintf( "pgrep -f '%s.*%s'", $service_binary, $deployment );
    my $pid = qx/$rest_ws_process_pid_cmd/;
    if ($pid) {
        my $rest_ws_stop_cmd = "kill -9 $pid";
        !system($rest_ws_stop_cmd)
          || die "Failed to stop the deployment: $rest_ws_stop_cmd\n";
    }
}
