
=head1 NAME

HSMB::StatusCodes - HTTP Status Codes for the REST API.

=over

=item 200 (OK)

Geneneric success code that simply means that the operation was successful. Does not indicate anything else
regarding the contents of the response body.

Used for read-only GET operations on resources.

=item 201 (HTTP_CREATED)

Success code indicating that the operation was successful, and the corresponding resource has either been
created or updated successfully. It also indicates that the response body contains the updated representation
of the resource that just got created or updated.

Used for PUT or POST based resource creation/mutation API calls.

=item 202 (ACCEPTED)

Success code indicating that the request was accepted for further processing, which will be completed
sometime later. Does not indicate anything about the contents of the response body.

Used for all asynchronous API calls.

=item 204 ($HTTP_NO_CONTENT)

Success code indicating that the request was successful, and the resource got deleted. Also indicates
that the response body is empty.

Used for DELETE resource operations.

=item 400 ($HTTP_BAD_REQUEST)

Error code indicating that the request was unsuccessful, and the response body contains additional information
about the specific errors that caused the request to fail.

Used for all failures due to Client providing invalid, missing, and/or unfulfillable parameter values.

Client should not repeat the request without modification.

=item 500 (INTERNAL_SERVER_ERROR)

Error code indicating that the request was unsuccessful, unexpectedly, due to exceptions inside the request handler,
and the response body contains additional information about the specific errors that caused the request to fail.

The response body contents should be used to report such issues back to the admins of the webservice.

Used for all failures due to exceptions (unexpected) thrown from the request handlers.

=back

=cut

package StatusCodes;

use strict;
use warnings;
use Const::Fast;

const our $HTTP_OK                    => 200; # The request was successful.
const our $HTTP_CREATED            => 201; # The request was successful; the resource was created/updated.
const our $HTTP_ACCEPTED              => 202; # The request has been accepted for further processing.
const our $HTTP_NO_CONTENT         => 204; # The request was successful; the resource was deleted.
const our $HTTP_BAD_REQUEST           => 400; # Bad request. Client should not repeat the request without modifications.
const our $HTTP_INTERNAL_SERVER_ERROR => 500; # Something went horribly wrong on the server side.

1;
