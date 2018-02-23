package DevOps::Command;

use strict;
use warnings;
use Result;
use Log::Any qw( $log );
use Moo::Role;
use Try::Tiny;

requires 'execute';
requires 'extract_params';

around 'execute' => sub {
    my ( $orig, $self, $opt, $args ) = @_;

    my $result = Result->new();

    my $params = $self->extract_params( $opt, $args );

    # log the params
    $log->infof( "Command called with the following parameters:\n\t %s\n", $params );

    # do handle_request
    try {
        $result = $orig->( $self, $params );
    }
    catch {
        my $error = "$_";
        $error =~ s/ at .*$//;
        my $error_item = { application_error => $error };
        $result->push_error( $error_item );
    };

    if ($result->is_error()) {
        $log->infof( "Command failed:\n\t %s\n", $result->get_payload()->{errors} );
    } else {
        $log->infof( "Command successful.\n");
    }
};

1;
