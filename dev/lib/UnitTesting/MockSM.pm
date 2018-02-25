
package UnitTesting::MockSM;

use strict;
use warnings;
use Result;
use CP::StorageManager;
use Test2::V0;

sub create_mock_storage_manager {
    my ($allocation_result) = @_;

    my $mock_storage_manager = mock(
        'CP::StorageManager' => (
            override => [
                new => sub { return bless {}, 'CP::StorageManager'; },
                get_storage =>
                  sub {
                      return
                          HSMB::Result->new()->push_item($allocation_result);
                  },
                free_storage => sub { return new HSMB::Result->new() }
            ]
        )
    );

    return $mock_storage_manager;
}

1;
