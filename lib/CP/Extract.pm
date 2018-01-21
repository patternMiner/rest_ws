package CP::Extract;

use strict;
use warnings;

use Archive::Extract;
use Moo;
use Params::ValidationCompiler qw(validation_for);
use Types::Standard qw( Str );

with 'Step';

my $state_validator = validation_for(
  params => {
    url  => { type => Str },
    size => { type => Str },
    basename => { type => Str },
    downloaded_blob => { type => Str }
  },
  slurpy => 1 # allow and ignore extra parameters
);

sub execute {
    my ( $self, $pipeline ) = @_;

    my $state = $pipeline->state;
    $state_validator->(%{$state});

    my $allocated_location = $pipeline->ctx->storage_manager->get_storage();
    my $extract_location = join ('/', $allocated_location, $state->{basename});

    my $ae = Archive::Extract->new(archive => $state->{downloaded_blob});
    if (defined $ae) {
        $ae->extract(to => $extract_location) || die $ae->error;
        $pipeline->add_result_item({ allocated_location => $allocated_location });
    } else {
        $pipeline->ctx->storage_manager->free_storage($allocated_location);
        my $error_msg = sprintf("Failed to extract the contents of url: %s", $state->{url});
        $pipeline->add_result_error({ application_error => $error_msg });
    }
 }

sub cleanup {
    my ($self, $pipeline) = @_;
}

1;
