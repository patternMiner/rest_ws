package CP::Download;

use strict;
use warnings;

use LWP::Simple;
use Moo;

with 'Step';

has to_be_freed => (is => 'ro', default => sub { [] });

sub execute {
    my ( $self, $pipeline ) = @_;

    my $state = $pipeline->state;
    my $download_dir = $pipeline->ctx->storage_manager->get_storage();
    my $downloaded_blob = join('/', $download_dir, $state->{archive_name});

    my $rc = getstore( $state->{url}, $downloaded_blob);
    if (is_success($rc)) {
        push (@{$self->to_be_freed}, $download_dir);
        $pipeline->state->{downloaded_blob} = $downloaded_blob;
    } else {
        $pipeline->ctx->storage_manager->free_storage($download_dir);
        $pipeline->add_result_error({
          application_error => "Failed to download the url: $state->{url}."
        });
    }
}

sub cleanup {
    my ($self, $pipeline) = @_;

    foreach my $download_dir (@{$self->to_be_freed}) {
        $pipeline->ctx->storage_manager->free_storage($download_dir);
    }

}

1;
