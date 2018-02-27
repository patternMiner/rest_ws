=head1 NAME

Role::CanHandleRequest - Role encapsulating the ApplicationContext attribute,
request parameter/result logging, and top-level exception handling around the
handle_request method.

=head1 SYNOPSIS

    package CP::DownloadContentHandler;

    use Result;
    with 'Role::CanHandleRequest';

    sub handle_request {
        my ( $self, $exec_state, @rest ) = @_;

        my %validated_params = $param_validator->(@rest);
        my $result = Result->new();
        my $max_size = $validated_params{max_size};

           ...

        return $result;
    }

=head1 DESCRIPTION

Encapsulates the logging of the input parameters and the result values,
and top-level exception handling around the handle_request method. To be
shared across all request handlers.

=cut

package Role::CanHandleRequest;

use strict;
use warnings;
use Log::Any qw( $log );
use Moo::Role;
use Result;
use StatusCodes;
use Try::Tiny;

requires 'handle_request';

has ctx => ( is => 'ro', required => 1 );

around 'handle_request' => sub {
    my ( $orig, $self, $exec_state, $params, @rest ) = @_;

    my $result = Result->new();

    # log the parameters
    $log->infof( "RequestHandler parameters: %s", $params );

    # do handle_request
    try {
        $result = $orig->( $self, $exec_state, $params );
    }
    catch {
        $log->infof( "RequestHandler: Caught exception: %s", $_ );
        my $error = "$_";
        $error =~ s/ at .*$//;
        chomp $error;
        $result->push_error( { application_error => $error} );
    };

    # log the result
    $log->infof( "RequestHandler execution state: %s", $exec_state );
    $log->infof( "RequestHandler result: %s", $result->to_hashref() );

    # return the result
    return $result->to_hashref();
};

sub dispatch {
    my ($self, $http_method) = @_;

    return sub {
        my ($c) = @_;

        my $result = $self->handle_request( {}, $c->req->params->to_hash );
        my $status = $StatusCodes::OK;
        if (@{$result->{errors}}) {
            $status = $StatusCodes::HTTP_BAD_REQUEST;
        } elsif ($http_method eq 'delete') {
            $status = $StatusCodes::HTTP_NO_CONTENT;
        } elsif ($http_method =~ m/put|post/) {
            $status = $StatusCodes::HTTP_CREATED;
        }

        $c->render( json => $result, status => $status );
    };
}

=head2 C<validate_all_parameters>

Validates all of the given named parameter values, according to a given validation spec.

=head3 PARAMETERS

=over

=item C<param_validation_spec>

A hashref of named parameter specs, each containing a 'type' attribute that indicates a
Type::Tiny type, and an optional 'default' attribute which is a value providing coderef.

  e.g:
    {
        content_url => { type => Str },
        max_size    => { type => MaxSize },
        crc         => { type => Str }
    }


=item C<params>

Request parameters as a hash of parameter_name keys mapped to corresponding parameter_values.

=back

=head3 RETURN

Returns a Result object, containing the parameter validation errors, or the validated
paremeter hashref.

Iterates through each parameter spec and validates its value from the named parameter values,
collects any missing parameter and/or invalid parameter values as errors, and assigns default
values where appropriate.  When there are no errors, returns the validated parameter hashref
as an item of the Result object.  Similarly, errors are added to the returned Result
object.

=cut

sub validate_all_parameters {
    my ($self, $params_validation_spec, $params) = @_;

    my $validated_params = {};
    my $result = Result->new();

    foreach my $p_name (sort (keys %{$params_validation_spec})) {
        my $v_spec = $params_validation_spec->{$p_name};
        my $p_type = $v_spec->{type};
        my $p_value = $params->{$p_name};
        # if no value is present, take the default value for validation.
        unless ($p_value) {
            if ($v_spec->{default}) {
                my $default = $v_spec->{default};
                $p_value = (ref ($default) eq 'CODE') ? $default->() : $default;
            }
        }
        # validate the value, if present.
        if ($p_value) {
            my $message = $p_type->validate($p_value);
            if ($message) {
                $result->push_error({invalid_parameter => $message});
            } else {
                $validated_params->{$p_name} = $p_type->assert_return($p_value);
            }
        } else {
            # unless the parameter is optional, consider its missing value as an error.
            unless ($v_spec->{optional}) {
                $result->push_error({missing_parameter => "$p_name is a required parameter."});
            }
        }
    }

    unless ($result->is_error()) {
        $result->push_item($validated_params);
    }

    return $result;
}

1;
