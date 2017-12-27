package AppContextBuilder;

use strict;
use warnings;

use AppContext;
use YAML::XS 'LoadFile';

sub build {
    my $log = shift;

    my $config       = LoadFile('rest_ws.yml');
    my $service_name = $config->{'service_name'};
    my $version      = $config->{'version'};

    my $ctx = AppContext->new(
        config       => $config,
        log          => $log,
        service_name => $service_name,
        version      => $version
    );

    return $ctx;
}

1;
