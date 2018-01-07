package CP::DownloadContentHandler;

use strict;
use warnings;

use RequestHandler;
use Moo;
use Params::ValidationCompiler qw(validation_for);
use Types::Standard qw( Str );

with 'RequestHandler';

my $param_validator = validation_for(
  params => {
    local_location => { type => Str },
    allocated_location => { type => Str }
  }
);

sub handle_request {
    my ( $self, @rest ) = @_;

    my %validated_params = $param_validator->(@rest);

    my $result = {
        errors => [],
        items  => []
    };

    return $result;
}

1;
