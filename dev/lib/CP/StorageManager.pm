package CP::StorageManager;

use strict;
use warnings;

use File::Path qw( remove_tree );
use File::Temp qw( tempdir );
use Log::Any qw( $log );
use Moo;
use Result;

has storage_pool => ( is => 'ro' );

sub get_storage {
    my ( $self, $size ) = @_;

    my $provisioned_location = tempdir( DIR => $self->storage_pool );

    return
      Result->new()->push_item({provisioned_location => $provisioned_location});
}

sub free_storage {
    my ( $self, $location ) = @_;

    my $result = Result->new();

    remove_tree( $location, { result => \my $deleted } );

    if (@{$deleted}) {
        $result->push_item({deleted => $deleted});
    } else {
        $result->push_error({delete_error => "Failed to delete $location."});
    }

    return $result;
}

1;
