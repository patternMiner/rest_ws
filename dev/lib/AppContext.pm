package AppContext;
use Moo;

has storage_manager => ( is => 'ro', required => 1 );
has service_name    => ( is => 'ro', required => 1 );

1;
