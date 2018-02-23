
package CP::DownloadContentHandler;

use Archive::Extract;
use CP::Types qw( MaxSize );
use File::Temp qw( tempdir );
use Log::Any qw( $log );
use LWP::Simple;
use Moo;
use Result;
use String::CRC32;
use Type::Tiny;
use Types::Standard qw( Str );

with 'Role::CanHandleRequest';

my $params_validation_spec = {
  content_url => { type => Str },
  max_size    => { type => MaxSize },
  crc         => { type => Str }
};

sub handle_request {
    my ( $self, $exec_state, $params ) = @_;

    my $result = $self->validate_all_parameters($params_validation_spec, $params);
    return $result if ($result->is_error());

    my $validated_params = $result->to_hashref()->{items}->[0];
    my $storage_manager = $self->ctx->storage_manager;
    $result = $storage_manager->get_storage( $validated_params->{max_size} );
    return $result if ($result->is_error());

    ## Setup execution state.
    $exec_state->{$_} = $validated_params->{$_} for keys %{$validated_params};
    $exec_state->{provisioned_location} =
      $result->to_hashref()->{items}->[0]->{provisioned_location};
    die "Directory doesn't exist" unless (-d $exec_state->{provisioned_location});
    ( $exec_state->{archive_name} ) =
      $exec_state->{content_url} =~ m/.*\/(.*)$/;
    ( $exec_state->{basename} ) =
      $exec_state->{archive_name} =~ m/(.*)\..*$/;

    ## Setup execution error handler.
    my $handle_exec_error = sub {
        my ($error_result) = @_;

        my $free_storage_result =
          $storage_manager->free_storage( $exec_state->{provisioned_location} );

        if ($exec_state->{downloaded_blob}) {
            unlink $exec_state->{downloaded_blob};
        }

        return ($free_storage_result->is_error())
          ? $free_storage_result
          : $error_result;
    };

    ## Perform step 1: Download.
    $log->infof("Step: Download: exec_state = %s", $exec_state);
    $result = _download( $exec_state );
    $log->infof("Step: Download: result = %s", $result);

    if ($result->is_error()) {
        return $handle_exec_error->($result);
    }

    ## Perform step 2: Extract.
    $log->infof("Step: Extract: exec_state = %s", $exec_state);
    $result = _extract( $exec_state );
    $log->infof("Step: Extract: result = %s", $result);

    if ($result->is_error()) {
        return $handle_exec_error->($result);
    }

    ## remove the downloaded blob as it got extracted successfully.
    unlink $exec_state->{downloaded_blob};

    return $result;
}

sub _download {
    my ( $exec_state ) = @_;

    my $handle_download_error = sub {
        my ( $exec_state, $error ) = @_;

        $error =~ s/ at .*$//;

        my $error_msg = sprintf( "Failed to download the content_url: %s%s",
          $exec_state->{content_url}, $error );

        my $result = Result->new();
        return $result->push_error( { application_error => $error_msg } );
    };

    my $downloaded_blob = join( '/',
      $exec_state->{provisioned_location},
      $exec_state->{archive_name} );

    my $rc = getstore( $exec_state->{content_url}, $downloaded_blob );

    unless ( is_success($rc) ) {
        return $handle_download_error->( $exec_state, "" );
    }

    my $crc = get_crc($downloaded_blob);
    unless ( $exec_state->{crc} eq $crc ) {
        return $handle_download_error->( $exec_state,
          " Error: CRC check failed. expected: $exec_state->{crc}, got $crc"
        );
    }

    # update state
    $exec_state->{downloaded_blob} = $downloaded_blob;

    return Result->new();
}

sub _extract {
    my ( $exec_state ) = @_;

    my $result = Result->new();
    my $handle_extraction_error = sub {
        my ( $error ) = @_;

        $error =~ s/ at .*$//;
        my $error_msg = sprintf(
          "Failed to extract the contents of content_url: %s %s",
          $exec_state->{content_url},
            $error ? "\nCaught exception: $error" : ""
        );

        return $result-> push_error( { application_error => $error_msg } );
    };

    my $extract_location =
      join( '/', $exec_state->{provisioned_location}, $exec_state->{basename} );
    my $ae =
      Archive::Extract->new( archive => $exec_state->{downloaded_blob} );
    unless ($ae) {
        return $handle_extraction_error->();
    }
    unless ( $ae->extract( to => $extract_location ) ) {
        return $handle_extraction_error->( $ae->error );
    }

    return $result->push_item({provisioned_location => $exec_state->{provisioned_location}});
}

sub get_crc {
    my ($file) = @_;
    open( my $fh, '<', $file ) || die;
    binmode $fh;
    my $crc = crc32(*$fh);
    close($fh);

    return $crc;
}

1;
