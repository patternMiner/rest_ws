package RestWs;

use AppContextBuilder;
use CP::CpStorageHandler;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    my $ctx = AppContextBuilder::build( $self->app->log );
    my $r   = $self->routes;

    # define welcome route
    {
        $r->get(
            '/' => sub {
                my $c = shift;

                $c->render(
                    json => {
                        'service_name' => $ctx->service_name,
                        'version'      => $ctx->version
                    }
                );
            }
        );
    }

    # Define the copy routes.
    {
        # dispatcher for upload content.
        my $upload_content = sub {
            my $c = shift;

            my $local_location = $c->param('local_location');
            my $allocated_location = $c->param('allocated_location');

            my $result = CP::CpStorageHandler::upload( $ctx, $local_location, $allocated_location );

            $c->render( json => $result );
        };

        # dispatcher for download content.
        my $download_content = sub {
            my $c = shift;

            my $local_location = $c->param('local_location');
            my $allocated_location = $c->param('allocated_location');

            my $result = CP::CpStorageHandler::download( $ctx, $local_location, $allocated_location );

            $c->render( json => $result );
        };

        # copy storage routes.

        # upload content.
        $r->put( '/cp/v0/content' => $upload_content );
        $r->put( '/cp/v0/content/:local_location' => $upload_content );
        $r->put( '/cp/v0/content/:local_location/:allocated_location' => $upload_content );

        # download content.
        $r->get( '/cp/v0/content' => $download_content );
        $r->get( '/cp/v0/content/:local_location' => $download_content );
        $r->get( '/cp/v0/content/:local_location/:allocated_location' => $download_content );
    }

}

1;
