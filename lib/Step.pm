package Step;

use strict;
use warnings;
use Moo::Role;

requires 'execute';

has name => ( is => 'ro', required => 1 );

around 'execute' => sub {
    my ( $orig, $self, $pipeline ) = @_;

    # log the pipeline state
    $pipeline->log->infof( "Step: %s, state: %s",
        $self->name, $pipeline->state );

    # execute
    $orig->( $self, $pipeline );

    # log the pipeline result
    $pipeline->log->infof( "Step: %s, result: %s",
        $self->name, $pipeline->result );
};

1;
