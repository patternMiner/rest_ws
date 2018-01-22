package CP::Extract;

use strict;
use warnings;

use Archive::Extract;
use Moo;
use Params::ValidationCompiler qw(validation_for);
use Type::Tiny;
use Types::Standard qw( Str );

my $SIZE = "Type::Tiny"->new(
    name       => "Size",
    constraint => sub { $_ =~ m/^\d+[BKMGT]{1}$/; },
    message    => sub { "InvalidParameter:$_ is not a valid size:" },
);

with 'Step';

my $state_validator = validation_for(
    params => {
        url             => { type => Str },
        size            => { type => $SIZE },
        basename        => { type => Str },
        downloaded_blob => { type => Str }
    },
    slurpy => 1    # allow and ignore extra parameters
);

sub execute {
    my ( $self, $pipeline ) = @_;

    my $state = $pipeline->state;
    $state_validator->( %{$state} );

    my $allocated_location =
      $pipeline->ctx->storage_manager->get_storage( $state->{size} );
    my $extract_location = join( '/', $allocated_location, $state->{basename} );

    my $ae = Archive::Extract->new( archive => $state->{downloaded_blob} );
    if ( defined $ae ) {
        $ae->extract( to => $extract_location ) || die $ae->error;
        $pipeline->add_result_item(
            { allocated_location => $allocated_location } );
    }
    else {
        $pipeline->ctx->storage_manager->free_storage($allocated_location);
        my $error_msg =
          sprintf( "Failed to extract the contents of url: %s", $state->{url} );
        $pipeline->add_result_error( { application_error => $error_msg } );
    }
}

1;
