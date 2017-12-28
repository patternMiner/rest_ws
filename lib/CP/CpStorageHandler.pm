package CP::CpStorageHandler;

use strict;
use warnings;

sub upload {
    my ( $ctx, $local_location, $allocated_location ) = @_;

    my $log = $ctx->log;

    $log->info( "upload content: local_location=$local_location, "
          . "allocated_location=$allocated_location" );

    my $result = {
        errors => [],
        items  => []
    };

    return $result;
}

sub download {
    my ( $ctx, $local_location, $allocated_location ) = @_;

    my $log = $ctx->log;

    $log->info( "download content: local_location=$local_location, "
          . "allocated_location=$allocated_location" );

    my $result = {
        errors => [],
        items  => []
    };

    return $result;
}

1;
