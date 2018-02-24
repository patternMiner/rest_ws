
=head1 DevOps::DeploymentBrewer

Functions and constants to compose and maintain the rest_ws deployment.

=head1 SEE ALSO

RestWs

=cut

package DevOps::DeploymentBrewer;

use strict;
use warnings;
use Const::Fast;
use Result;
use Params::ValidationCompiler qw(validation_for);
use Template;
use Try::Tiny;
use Types::Standard qw( Any Str );
use YAML::XS;

const my $DEPLOYMENT_ROOT => 'deployments';
const my $SERVICE_NAME    => 'rest_ws';
const my $SERVICE_PORT    => 3000;

my $param_validator = validation_for(
    params => {
        deployment_root => { type => Str, default => $DEPLOYMENT_ROOT },
        deployment_type => { type => Str, default => 'uat' },
        deployment_id   => { type => Str, default => 'test' },
        storage_pool    => { type => Any, default => sub {
                die "storage_pool is a required parameter";
            }},
        service_binary  => { type => Any, default => sub {
                die "service_binary is a required parameter";
            }},
        service_name    => { type => Str, default => $SERVICE_NAME },
        service_port    => { type => Str, default => $SERVICE_PORT }
    }
);

sub brew {
    my (@params) = @_;

    my $result = Result->new();

    try {
        my %validated_params = $param_validator->(@params);

        _coerce_params( \%validated_params );

        my $deployment_root = $validated_params{deployment_root};
        my $deployment_type = $validated_params{deployment_type};
        my $deployment_id   = $validated_params{deployment_id};
        my $storage_pool    = $validated_params{storage_pool};
        my $service_binary  = $validated_params{service_binary};

        unless ( -d $deployment_root ) {
            $result->push_error(
                { "invalid_arg" => "$deployment_root doesn't exist." }
            );
            return $result;
        }

        unless ( -f $service_binary ) {
            $result->push_error(
                { "invalid_arg" => "$service_binary doesn't exist." }
            );
            return $result;
        }

        unless ( -d $storage_pool ) {
            $result->push_error(
                { "invalid_arg" => "$storage_pool doesn't exist." }
            );
            return $result;
        }

        unless ( -d "$deployment_root/$deployment_type" ) {
            mkdir "$deployment_root/$deployment_type";
        }

        my $deployment_home =
          "$deployment_root/$deployment_type/$deployment_id";
        unless ( -d $deployment_home ) {
            mkdir "$deployment_home";
        }

        if ( -f "$deployment_home/config.yml" ) {
            $result->push_error(
                { "invalid_operation" => "Can't clobber existing deployment" }
            );
            return $result;
        }

        # create config
        _process_template( "devops/config/config.yml.tmpl",
            "$deployment_home/config.yml", \%validated_params );

        $result->push_item( { "fresh_brew" => "$deployment_home" } );
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

    $params->{deployment_root} =~ s|/\z||;
    $params->{storage_pool} =~ s|/\z||;
    $params->{environment} = ($params->{deployment_type} eq 'dev')
      ? 'development'
      : 'production';
}

sub _process_template {
    my ( $template_file, $output_file, $vars ) = @_;

    my $template = Template->new();

    $template->process( $template_file, $vars, $output_file )
      || die $template->error(), "\n";
}

1;
