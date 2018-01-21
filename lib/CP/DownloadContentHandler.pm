package CP::DownloadContentHandler;

use strict;
use warnings;

use CP::ContentPipeline;
use CP::Download;
use CP::Extract;
use Moo;
use Params::ValidationCompiler qw(validation_for);
use RequestHandler;
use Types::Standard qw( Str );

with 'RequestHandler';

my $param_validator = validation_for(
  params => {
    url  => { type => Str },
    size => { type => Str, optional => 1 }
  }
);

sub handle_request {
    my ( $self, @rest ) = @_;

    my %validated_params = $param_validator->(@rest);

    return
      CP::ContentPipeline->new(ctx => $self->ctx, url => $validated_params{url})
        ->add_step(CP::Download->new(name => 'download'))
        ->add_step(CP::Extract->new(name => 'extract'))
        ->execute();
}

1;
