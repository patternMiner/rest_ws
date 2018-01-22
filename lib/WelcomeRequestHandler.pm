package WelcomeRequestHandler;

use strict;
use warnings;

use RequestHandler;
use Moo;
use Params::ValidationCompiler qw(validation_for);
use Types::Standard qw( Str );

with 'RequestHandler';

sub handle_request {
    my ( $self, @rest ) = @_;

    my $ctx = $self->ctx;

    my $result = {
        errors => [],
        items  => [
            {
                'service_name' => $ctx->service_name,
                'version'      => $ctx->version
            }
        ]
    };

    return $result;
}

1;
