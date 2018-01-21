package CP::Download;

use strict;
use warnings;

use File::Temp qw(tempdir);
use LWP::Simple;
use Moo;

with 'Step';

has _to_be_freed => (is => 'rw', default => sub { [] });

sub execute {
    my ( $self, $pipeline ) = @_;

    my $state = $pipeline->state;
    my $download_dir = tempdir( CLEANUP => 1 );
    my $downloaded_blob = join('/', $download_dir, $state->{archive_name});

    my $rc = getstore( $state->{url}, $downloaded_blob);
    if (is_success($rc)) {
        push (@{$self->_to_be_freed}, $download_dir);
        $pipeline->state->{downloaded_blob} = $downloaded_blob;
    } else {
        $pipeline->add_result_error({
          application_error => "Failed to download the url: $state->{url}."
        });
    }
}

sub cleanup {
    my ($self, $pipeline) = @_;

    $self->_to_be_freed([]);
}

1;
