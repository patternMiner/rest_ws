package RestWs;

use AppContextBuilder;
use CP::DownloadContentHandler;
use Mojo::Base 'Mojolicious';
use WelcomeRequestHandler;
use YAML::XS;

# Defines the routes and the request dispatchers.
sub startup {
    my ($app) = @_;

    my $config = _get_config($app);
    my $ctx    = AppContextBuilder::build(
        service_name => $config->{service_name},
        version      => $config->{version},
        storage_pool => $config->{storage_pool}
    );

    my $r = $app->routes;

    # routes
    $r->get( '/' => WelcomeRequestHandler->new( ctx => $ctx )->dispatch );
    $r->post( '/cp/v0/content' =>
          CP::DownloadContentHandler->new( ctx => $ctx )->dispatch );
}

sub _get_config {
    my ($app) = @_;

    my $config = $app->config;
    unless ( $config->{config_override} ) {
        my $home = $app->home;
        $config = YAML::XS::LoadFile("$home/config.yml");
    }

    return $config;
}

1;
