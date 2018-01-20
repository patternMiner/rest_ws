package CP::DownloadManager;

use strict;
use warnings;

use LWP::Simple;
use Moo;
use Try::Tiny;


has storage_manager => (is => 'ro');
has to_be_freed => (is => 'ro', default => sub { [] });

sub download {
    my ( $self, $url, $archive_name ) = @_;

    my $download_dir = $self->storage_manager->get_storage();
    my $download_blob = join('/', $download_dir, $archive_name);

    my $rc;
    try {
        $rc  = getstore( $url, $download_blob);
        if (is_success($rc)) {
            push (@{$self->to_be_freed}, $download_dir);
        } else {
            $self->storage_manager->free_storage($download_dir);
        }
    } catch {
        $self->storage_manager->free_storage($download_dir);
    };

    return (defined $rc && is_success($rc)) ? $download_blob : undef;
}

sub cleanup {
    my ($self) = @_;

    foreach my $download_dir (@{$self->to_be_freed}) {
        $self->storage_manager->free_storage($download_dir);
    }

}

sub DEMOLISH {
    my ($self) = @_;

    $self->cleanup();
}

1;
