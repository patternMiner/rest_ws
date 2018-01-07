
=head1 RequestHandler

Role to encapsulate the shared AppContext field, and request/response logging.

=cut

package RequestHandler;

use strict;
use warnings;
use Moo::Role;
use Try::Tiny;

has ctx => ( is => 'ro', required => 1 );

sub handle_request { }

around 'handle_request' => sub {
    my ( $orig, $self, @rest ) = @_;

    my $result = {
      errors => [],
      items => []
    };

    # log the parameters
    $self->ctx->log->infof( "RequestHandler parameters: %s", @rest );

    # do handle_request
    try {
        $result = $orig->( $self, @rest );
    } catch {
        my $error_item = {
          application_error => "$_"
        };
        push (@{$result->{errors}}, $error_item);
    };

    # log the result
    $self->ctx->log->infof( "RequestHandler result: %s", $result );

    # return the result
    return $result;
};

sub dispatch {
    my ($self) = @_;

    return sub {
        my ($c) = @_;

        my $result = $self->handle_request($c->req->params->to_hash);

        $c->render( json => $result );
    };
}

1;
