package AppContextBuilder;

use strict;
use warnings;

use AppContext;
use CP::StorageManager;
use Log::Any;
use Params::ValidationCompiler qw( validation_for );
use Types::Standard qw( Object Str );

my $param_validator = validation_for(
    params => {
        log => {
            type    => Object,
            default => sub { Log::Any->get_logger }
        },
        storage_pool => { type => Str },
        service_name => { type => Str },
        version      => { type => Str },
    }
);

sub build {
    my (@params) = @_;

    my %validated_params = $param_validator->(@params);

    $validated_params{storage_manager} =
      CP::StorageManager->new(
        storage_pool => $validated_params{storage_pool} );

    my $ctx = AppContext->new(%validated_params);

    return $ctx;
}

1;
