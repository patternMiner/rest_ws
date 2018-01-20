package CP::ExtractionManager;

use strict;
use warnings;

use Archive::Extract;
use Moo;
use Try::Tiny;


has storage_manager => (is => 'ro');

sub extract {
    my ( $self, $blob, $archive_name ) = @_;

    my $allocated_location = $self->storage_manager->get_storage();
    my $extract_location = _get_extract_location($archive_name, $allocated_location);

    my $result;
    try {
        my $ae = Archive::Extract->new(archive => $blob);
        if (defined $ae) {
            $ae->extract(to => $extract_location) || die $ae->error;
            $result = $allocated_location;
        }
    } catch {
        if ($allocated_location) {
            $self->storage_manager->free_storage($allocated_location);
        }
    };

    return $result;
}

sub _get_extract_location {
    my ($archive_name, $allocated_location) = @_;

    my ($basename) = $archive_name =~ m/(.*)\..*$/;

    return join ('/', $allocated_location, $basename);
}

1;
