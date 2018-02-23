package UnitTesting::Harness;

use strict;
use warnings;

use AppContextBuilder;
use Archive::Tar;
use Array::Compare;
use Log::Any qw( $log );
use RestWs;
use YAML::XS;

sub create_test_config {
    return YAML::XS::Load(<<END);
# Your application's name
service_name: 'REST Web Service'

storage_pool: '/tmp/RestWs/storage_pool'
END
}

sub create_test_app_context {

    my $ctx = AppContextBuilder::build(
        service_name => 'REST Web Service',
        storage_pool => '/tmp/RestWs/storage_pool',
        version      => $RestWs::VERSION,
    );

    return $ctx;
}

sub create_test_file {
    my ( $dir, $content ) = @_;

    my @files = ( "awesome/bar", "awesome/foo" );
    my $tar = Archive::Tar->new();
    foreach my $file (@files) {
        $tar->add_data( $file, $content );
    }
    $tar->write( "$dir/files.tgz", COMPRESS_GZIP );

    return "$dir/files.tgz";
}

sub load_test_data {
    my ($test_data_yml) = @_;

    my $test_data = YAML::XS::Load($test_data_yml);

    return $test_data;
}

# returns true if both the Result objects are equal.
sub results_equal {
    my ($this, $that) = @_;

    my $this_payload = $this->get_payload();
    my $that_payload = $that->get_payload();

    return
      _arrayrefs_equal($this_payload->{items}, $that_payload->{items}) &&
      _arrayrefs_equal($this_payload->{errors}, $that_payload->{errors});

}

# returns true if both arrays have same elements, albeit in different order. false, otherwise.
sub _arrayrefs_equal {
    my ($this, $that) = @_;

    unless (@{$this} || @{$that}) {
        return 1;
    }

    my @sorted_this = (sort { $a <=> $b } @{$this});
    my @sorted_that = (sort { $a <=> $b } @{$that});

    my $comp = Array::Compare->new(DefFull => 1);

    my $comp_result = $comp->compare(\@sorted_this, \@sorted_that);

    return $comp_result;

}

1;
