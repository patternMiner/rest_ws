package DevOps::Command::brew;

use strict;
use warnings;

use App::Cmd::Setup -command;
use DevOps::DeploymentBrewer;
use Log::Any qw( $log );
use Moo;

with 'DevOps::Command';

# Added to the command name for 'devops help'
sub abstract {
    return "Create a deployment for RestWs.";
}

# Added to the output of 'rest_ws help <this command>'
sub description {
    return <<"END"}
Create a deployment for RestWs, based on:
\tdeployment type, deployment id, storage pool,
\tservice binary, service name, and service port.
END

sub usage_desc {
    return "%c brew [-s sm_instance] [-i deployment_id] [-t deployment_type] "
      . "[-b service_binary] [-n service_name] [-p service_port]";
}

sub opt_spec {
    return (
        [ 'service_binary|b=s', 'Path to rest_ws binary.' ],
        [
            'service_name|n=s',
            'Service name for the cloud. Defaults to rest_ws.'
        ],
        [
            'service_port|p=n',
            'Port number for the web service. Defaults to 3000.'
        ],
        [ 'storage_pool|s=s',     'Path to storage pool.' ],
        [ 'deployment_id|i=s',   'Deployment id. Defaults to dvs.' ],
        [ 'deployment_type|t=s', 'Deployment type. Defaults to uat.' ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    die "This command takes no positional arguments!\n" if @{$args};

    return;
}

sub extract_params {
    my ( $self, $opt, $args ) = @_;

    my $params = {};
    foreach my $param_key (
        'deployment_type', 'deployment_id',
        'storage_pool',    'service_binary',
        'service_name',    'service_port'
      )
    {
        my $param_value = $opt->{$param_key};
        if ( defined $param_value ) {
            $params->{$param_key} = $param_value;
        }
    }

    return $params;
}

sub execute {
    my ( $self, $params, $args ) = @_;

    DevOps::DeploymentBrewer::brew($params);
}

1;
