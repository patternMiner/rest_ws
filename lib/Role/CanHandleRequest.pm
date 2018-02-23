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
use Log::Any qw($log);
use Moo::Role;
use Result;
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
        my ($missing_parameter) = $_ =~ m/MissingParameter:([^:]*):/;
        my ($invalid_parameter) = $_ =~ m/InvalidParameter:([^:]*):/;
        if ($missing_parameter) {
            $result->push_error( { missing_parameter => $missing_parameter } );
        }
        elsif ($invalid_parameter) {
            $result->push_error( { invalid_parameter => $invalid_parameter } );
        }
        else {
            my $error = "$_";
            $error =~ s/ at .*$//;
            chomp $error;
            $result->push_error( { application_error => $error} );
        }
    };

    # log the result
    $log->infof( "RequestHandler execution state: %s", $exec_state );
    $log->infof( "RequestHandler result: %s", $result->get_payload() );

    # return the result
    return $result->get_payload();
};

sub dispatch {
    my ($self) = @_;

    return sub {
        my ($c) = @_;

        my $result = $self->handle_request( {}, $c->req->params->to_hash );

        $c->render( json => $result );
    };
}

sub validate_all_parameters {
    my ($self, $params_validation_spec, $params) = @_;

    my $validated_params = {};
    my $result = Result->new();

    while(my($p_name, $v_spec) = each %{$params_validation_spec}) {
        my $p_type = $v_spec->{type};
        my $p_value = $params->{$p_name};
        if ($p_value) {
            my $message = $p_type->validate($p_value);
            if ($message) {
                $result->push_error({invalid_parameter => $message});
            } else {
                $validated_params->{$p_name} = $p_type->assert_return($p_value);
            }
        } else {
            if ($v_spec->{default}) {
                $validated_params->{$p_name} = $v_spec->{default}->();
            }
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
