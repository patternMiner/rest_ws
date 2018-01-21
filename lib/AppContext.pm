package AppContext;
use Moo;

has log                => ( is => 'ro', required => 1 );
has storage_manager    => ( is => 'ro', required => 1 );
has service_name       => ( is => 'ro', required => 1 );
has version            => ( is => 'ro', required => 1 );

1;
