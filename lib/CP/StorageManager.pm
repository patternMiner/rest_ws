package CP::StorageManager;

use strict;
use warnings;

use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Moo;

has storage_pool => (is => 'ro');

sub get_storage {
    my ( $self, $size) = @_;

    return tempdir( DIR => $self->storage_pool );
}

sub free_storage {
    my ( $self, $location) = @_;

    remove_tree($location);
}

1;
