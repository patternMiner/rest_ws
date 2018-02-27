package RestWs;

use Log::Log4perl;
use Log::Any::Adapter;
use Log::Any qw ( $log );

use AppContextBuilder;
use CP::DownloadContentHandler;
use CP::StorageDeallocateHandler;
use Mojo::Base 'Mojolicious';
use StatusCodes;
use WelcomeRequestHandler;
use YAML::XS;

our $VERSION = '0.0.0';

# Defines the routes and the request dispatchers.
sub startup {
    my ($app) = @_;

    my $config = _get_config($app);
    my $env = $config->{environment};

    Log::Log4perl::init( "etc/$env/log4perl.conf" );
    Log::Any::Adapter->set('Log::Log4perl');

    my $ctx    = AppContextBuilder::build(
        service_name => $config->{service_name},
        version      => $VERSION,
        storage_pool => $config->{storage_pool}
    );

    my $r = $app->routes;
    # routes
    $r->get( '/' => WelcomeRequestHandler->new( ctx => $ctx )->dispatch('get') );
    $r->post( '/cp/v0/content' =>
          CP::DownloadContentHandler->new( ctx => $ctx )->dispatch('post') );
    $r->delete( '/cp/v0/content' =>
        CP::StorageDeallocateHandler->new( ctx => $ctx )->dispatch('delete') );
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
