
package Pipeline;

use strict;
use warnings;
use Moo::Role;
use Try::Tiny;

has ctx => ( is => 'ro', required => 1 );
has state => ( is => 'ro', default => sub {{}} );
has steps => ( is => 'ro', default => sub {[]} );
has result => ( is => 'lazy' );
has log => ( is => 'lazy' );

sub _build_result {
    my ($self) = @_;

    return {
      errors => [],
      items => []
    };
}

sub _build_log {
    my ($self) = @_;

    return $self->ctx->log;
}

sub add_step {
    my ( $self, $step, $name ) = @_;

    push (@{$self->steps}, $step);
    return $self;
};

sub add_result_item {
    my ($self, $item) = @_;

    push (@{$self->result->{items}}, $item);
    return $self;
}

sub add_result_error {
    my ($self, $error) = @_;

    push (@{$self->result->{errors}}, $error);
    return $self;
}

sub is_result_error {
    my ($self) = @_;

    return (@{$self->result->{errors}});
}

sub execute {
    my ($self) = @_;

    foreach my $step (@{$self->steps}) {
        if ($self->is_result_error()) {
            last;
        }
        try {
            $step->execute($self);
        } catch {
            $self->add_result_error({ application_error => "$_" });
        };

    }

    foreach my $step (@{$self->steps}) {
        try {
            $step->cleanup($self);
        } catch {
            $self->add_result_error({ application_error => "$_" });
        };
    }

    return $self->result;
}

1;
