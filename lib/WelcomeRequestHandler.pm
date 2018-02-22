package WelcomeRequestHandler;

use strict;
use warnings;

use Moo;
use Params::ValidationCompiler qw(validation_for);
use Result;
use Types::Standard qw( Str );

with 'Role::CanHandleRequest';

sub handle_request {
    my ( $self, $exec_state, @rest ) = @_;

    my $ctx = $self->ctx;

    return
      Result->new()
        ->push_item({
        'service_name' => $ctx->service_name,
        'version'      => $ctx->version
      });
}

1;
