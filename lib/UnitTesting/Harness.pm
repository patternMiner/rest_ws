package UnitTesting::Harness;

use strict;
use warnings;

use AppContextBuilder;
use Archive::Tar;
use Log::Any::Adapter ('Stderr');
use RestWs;
use YAML::XS;

sub create_test_config {
    return YAML::XS::Load(<<END);
# Your application's name
service_name: 'REST Web Service'

# version of this release
version: '0.0.0'

storage_pool: '/tmp/RestWs/storage_pool'
END
}

sub create_test_app_context {

    my $ctx = AppContextBuilder::build(
        service_name => 'REST Web Service',
        storage_pool => '/tmp/RestWs/storage_pool',
        version      => '0.0.0',
    );

    return $ctx;
}

sub create_test_url {
    my ( $dir, $content ) = @_;

    my @files = ( "awesome/bar", "awesome/foo" );
    my $tar = Archive::Tar->new();
    foreach my $file (@files) {
        $tar->add_data( $file, $content );
    }
    $tar->write( "$dir/files.tgz", COMPRESS_GZIP );

    return "file:/$dir/files.tgz";
}

sub load_test_data {
    my ($test_data_yml) = @_;

    my $test_data = YAML::XS::Load($test_data_yml);

    return $test_data;
}

1;
