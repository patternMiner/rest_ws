
=head1 NAME

Result - Encapsulates the webservice result.

=head1 SYNOPSIS

    use Result;
    my $result = Result->new();
    my $provisioned_location;

    ...

    if ($error) {
        return $result->push_error({ application_error => $error});
    }

    return $result->push_item({ provisioned_location => $provisioned_location });

=head1 DESCRIPTION

Encapsulates the webservice result creation and manipulation functionality
needed by the request handlers.

The payload of the result has the following format:

 {
    errors => [],
    items => []
 }

where the the presence of errors indicate failure of the request.

The structure of the errors, and the items is left to the individual
request handlers, and the result does not interpret them in any way.

=cut

package Result;

use Array::Compare;
use Moo;

has _result => ( is => 'ro', default => sub { { errors => [], items => [] } } );

=head1 FUNCTIONS/METHODS

=cut


=head2 C<from_hashref>

Constructs a new Result object from a given hashref.

=head3 PARAMETERS

=over

=item C<hashref>

The hashref that will be the _result attribute of the new Result object.

=back

=head3 RETURN

A new Result object, having the given hashref as the _result attribute.

=cut

sub from_hashref {
      my ($class, $hashref) = @_;

      return Result->new(_result => $hashref);
}

=head2 C<push_item>

Adds the given item to the list of items.

=head3 PARAMETERS

=over

=item C<item>

The item hashref that needs to be added to the list of items.

=back

=head3 RETURN

self.

=cut

sub push_item {
    my ( $self, $item ) = @_;

    push( @{ $self->_result->{items} }, $item );
    return $self;
}

=head2 C<push_error>

Adds the given error to the list of errors.

=head3 PARAMETERS

=over

=item C<error>

The error hashref that needs to be added to the list of errors.

=back

=head3 RETURN

self.

=cut

sub push_error {
    my ( $self, $error ) = @_;

    push( @{ $self->_result->{errors} }, $error );
    return $self;
}

=head2 C<is_error>

Checks to see whether there are any errors in the list of errors.

=head3 PARAMETERS

None.

=head3 RETURN

Truthy if there are any errors. Falsy otherwise.

=cut

sub is_error {
    my ($self) = @_;

    return ( @{ $self->_result->{errors} } );
}

=head2 C<to_hashref>

Returns the hashref that constitutes this result.

=head3 PARAMETERS

None.

=head3 RETURN

The _result attribute, that constitutes the client consumable result hashref.

=cut

sub to_hashref {
    my ($self) = @_;

    return $self->_result;
}

1;
