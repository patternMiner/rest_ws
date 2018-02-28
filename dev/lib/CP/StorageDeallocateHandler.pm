
package CP::StorageDeallocateHandler;

use CP::Types qw( ProvisionedLocation );
use Log::Any qw( $log );
use Moo;
use Result;
use Type::Tiny;

with 'Role::CanHandleRequest';

my $params_validation_spec = {
  provisioned_location => { type => ProvisionedLocation },
};

sub handle_request {
    my ( $self, $exec_state, $params ) = @_;

    my $result = $self->validate_all_parameters($params_validation_spec, $params);
    return $result if ($result->is_error());

    my $validated_params = $result->to_hashref()->{items}->[0];
    my $storage_manager = $self->ctx->storage_manager;

    $result = $storage_manager->free_storage( $validated_params->{provisioned_location} );

    return $result;
}

1;
