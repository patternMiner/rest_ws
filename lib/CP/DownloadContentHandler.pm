package CP::DownloadContentHandler;

use strict;
use warnings;

use Moo;
use Params::ValidationCompiler qw(validation_for);
use RequestHandler;
use Types::Standard qw( Str );

with 'RequestHandler';

my $param_validator = validation_for(
  params => {
    url  => { type => Str },
    size => { type => Str, optional => 1 }
  }
);

sub handle_request {
    my ( $self, @rest ) = @_;

    my %validated_params = $param_validator->(@rest);
    my $url = $validated_params{url};
    my $archive_name = _get_archive_name($url);

    my $ctx = $self->ctx;
    my $result = make_result();

    my $download_blob  = $ctx->download_manager->download($url, $archive_name);
    if ( $download_blob ) {
        my $allocated_location = $ctx->extraction_manager->extract($download_blob, $archive_name);
        if (defined $allocated_location) {
            my $item = { allocated_location => $allocated_location };
            push_item( $result, $item );
        } else {
            my $error_msg = "Failed to extract the downloaded blob: $download_blob.";
            my $error_item = { application_error => $error_msg };
            push_error( $result, $error_item );
        }
    }
    else {
        my $error_msg = "Failed to download the url: $url.";
        my $error_item = { application_error => $error_msg };
        push_error( $result, $error_item );
    }

    $ctx->download_manager->cleanup();

    return $result;
}

sub _get_archive_name {
    my ($url) = @_;

    my ($archive_name) = $url =~ m/.*\/(.*)$/;

    return $archive_name;
}

1;
