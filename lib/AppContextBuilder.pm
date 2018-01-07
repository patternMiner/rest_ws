package AppContextBuilder;

use strict;
use warnings;

use AppContext;
use Log::Any;
use Params::ValidationCompiler qw( validation_for );
use Types::Standard qw( Object Str );

my $param_validator = validation_for(
  params => {
    log   => { type => Object, default => sub { Log::Any->get_logger } },
    service_name   => { type => Str },
    version => { type => Str },
  }
);

sub build {
    my (@params) = @_;

    my %validated_params = $param_validator->(@params);

    my $ctx = AppContext->new(%validated_params);

    return $ctx;
}

1;
