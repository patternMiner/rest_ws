package CP::Extract;

use strict;
use warnings;

use Archive::Extract;
use Moo;

with 'Step';

sub execute {
    my ( $self, $pipeline ) = @_;

    my $state = $pipeline->state;
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
