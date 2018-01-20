package UnitTesting::Harness;

use strict;
use warnings;

use AppContextBuilder;
use Archive::Tar;
use RestWs;
use Log::Any::Adapter ('Stderr');
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

    my $ctx = HSMB::AppContextBuilder::build(
        service_name => 'REST Web Service',
        version      => '0.0.0',
    );

    return $ctx;
}

sub create_test_url {
    my ($dir, $content) = @_;

    my @files = ("$dir/bar", "$dir/foo");
    my $tar = Archive::Tar->new();
    foreach my $file (@files) {
        $tar->add_data($file, $content);
    }
    $tar->write("$dir/files.tgz", COMPRESS_GZIP);

    return "file:/$dir/files.tgz";
}

sub load_test_data {
    my ($test_data_yml) = @_;

    my $test_data = YAML::XS::Load($test_data_yml);

    return $test_data;
}

1;
