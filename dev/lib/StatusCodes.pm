
=head1 NAME

StatusCodes - Encapsulates the HTTP Status Codes for the REST API.

=cut

package StatusCodes;

use strict;
use warnings;
use Const::Fast;

const our $OK            => 200; # The request was successful.
const our $OK_CREATED    => 201; # The request was successful; the resource was created/updated.
const our $ACCEPTED      => 202; # The request has been accepted for further processing.
const our $OK_NO_CONTENT => 204; # The request was successful; the resource was deleted.
const our $BAD_REQUEST   => 400; # Bad request. Client should not repeat the request without modifications.

1;
