package CP::ContentPipeline;

use strict;
use warnings;

use Moo;
use Pipeline;

with 'Pipeline';

has url  => (is => 'ro', required => 1);
has size => (is => 'ro', required => 1);

sub BUILD {
    my ($self, @rest) = @_;

    my $state = $self->state;

    $state->{url} = $self->url;
    $state->{size} = $self->size;
    ($state->{archive_name}) = $self->url =~ m/.*\/(.*)$/;;
    ($state->{basename}) = $state->{archive_name} =~ m/(.*)\..*$/;
}

1;
