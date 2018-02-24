package DevOps::Command::service;

use strict;
use warnings;

use App::Cmd::Setup -command;
use DevOps::ServiceManager;
use Log::Any qw( $log );
use Moo;

with 'DevOps::Command';

# Added to the command name for 'devops help'
sub abstract {
    return "Start and stop rest_ws.";
}

# Added to the output of 'devops help <this command>'
sub description {
    return "Start or stop a deployment of rest_ws.";
}

sub usage_desc {
    return "%c service [-d deployment] start | stop ";
}

sub opt_spec {
    return ( [ 'deployment|d=s', 'Path to the deployment' ] );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my $arg_count = scalar( @{$args} );
    die "This command takes one argument!\n" unless ( $arg_count eq 1 );

    my $arg = $args->[0];
    die "This command takes either start of stop as argument.\n"
      unless ( $arg =~ m/start|stop/ );

    return;
}

sub extract_params {
    my ( $self, $opt, $args ) = @_;

    my $params = {
        deployment => $opt->{deployment},
        action     => $args->[0]
    };

    return $params;
}

sub execute {
    my ( $self, $params, $args ) = @_;

    DevOps::ServiceManager::perform($params);
}

1;
