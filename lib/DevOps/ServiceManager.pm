
=head1 DevOps::ServiceManager

Functions and constants to start and stop specified rest_ws deployments as web services.

=head1 SEE ALSO

RestWs

=cut

package DevOps::ServiceManager;

use strict;
use warnings;
use Const::Fast;
use Result;
use Params::ValidationCompiler qw( validation_for );
use Log::Any qw( $log );
use Try::Tiny;
use Types::Standard qw( Str );
use YAML::XS;

const my $DEFAULT_VALUE => 'bogus';

my $param_validator = validation_for(
    params => {
        deployment => { type => Str, default => $DEFAULT_VALUE },
        action     => { type => Str, default => $DEFAULT_VALUE },
    }
);

sub perform {
    my (@params) = @_;

    my $result = Result->new();

    try {
        my %validated_params = $param_validator->(@params);

        _coerce_params( \%validated_params );

        my $deployment = $validated_params{deployment};
        my $action     = $validated_params{action};

        unless ( -d $deployment ) {
            $result->push_error(
                { "invalid_arg" => "$deployment doesn't exist." }
            );
            return $result;
        }

        my $deployment_data =
          _validate_deployment_data(
            YAML::XS::LoadFile("$deployment/config.yml") );

        my $service_binary = $deployment_data->{service_binary};
        my $service_port   = $deployment_data->{service_port};
        my $ws_process_pid_cmd =
          sprintf( "pgrep -f '%s.*%s'", $service_binary, $deployment );

        my $pid = qx/$ws_process_pid_cmd/;

        if ( $action eq 'start' ) {
            if ($pid) {
                $result->push_error(
                    {
                        "invalid_action" => "$deployment is already started."
                    }
                );
                return $result;
            }

            my $ws_daemon_cmd = sprintf( "%s daemon --home %s -l http://*:%s &",
                $service_binary, $deployment, $service_port );
            !system($ws_daemon_cmd)
              || die "Failed to start the deployment: $ws_daemon_cmd\n";

            $result->push_item(
                {
                    "started" => "$deployment"
                }
            );
        }
        elsif ( $action eq 'stop' ) {
            unless ($pid) {
                $result->push_error(
                    { "invalid_action" => "$deployment is already stopped." }
                );
                return $result;
            }

            my $ws_stop_cmd = "kill -9 $pid";
            !system($ws_stop_cmd)
              || die "Failed to stop the deployment: $ws_stop_cmd\n";

            $result->push_item(
                {
                    "stopped" => "$deployment"
                }
            );
        }
    }
    catch {
        my $error = "$_";
        $error =~ s/ at .*$//;
        chomp $error;
        $result->push_error( { "application_error" => $error } );
    };

    return $result;
}

sub _coerce_params {
    my ($params) = @_;

    die "Invalid deployment.\n" unless ( -d $params->{deployment} );

    $params->{deployment} =~ s|/\z||;
}

sub _validate_deployment_data {
    my ($deployment_data) = @_;

    _validate_file_param('service_binary', $deployment_data->{service_binary});
    _validate_port_param('service_port', $deployment_data->{service_port});
    _validate_dir_param('storage_pool', $deployment_data->{storage_pool});

    return $deployment_data;
}

sub _validate_file_param {
    my ($key, $value) = @_;
    die "$key is unspecified\n" unless ($value);
    die "$value doesn't exist\n" unless ( -f $value );
}

sub _validate_dir_param {
    my ($key, $value) = @_;
    die "$key is unspecified\n" unless ($value);
    die "$value doesn't exist\n" unless ( -d $value );
}

sub _validate_port_param {
    my ($key, $value) = @_;
    die "$key is unspecified\n" unless (defined $value);
    die "$key is invalid: $value\n" if ( $value =~ m/\D/ );
}

1;
