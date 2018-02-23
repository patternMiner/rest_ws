package WelcomeRequestHandler;

use Log::Any ( $log );
use Moo;
use RestWs;
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
        'version'      => $RestWs::VERSION
      });
}

1;
