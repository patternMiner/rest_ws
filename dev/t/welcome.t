#!/usr/bin/perl
use strict;
use warnings;
use UnitTesting::Harness;
use Log::Any qw( $log );
use Log::Any::Adapter qw( TAP );
use Test::Mojo;
use Test2::V0;
use Test2::Plugin::BailOnFail;

subtest "Test welcome page" => sub {
    my $config = UnitTesting::Harness::create_test_config();
    my $t = Test::Mojo->new( 'RestWs' => $config );

    $t->get_ok('/')->status_is(200)->json_is(
        {
            errors => [],
            items  => [
                {
                    version      => '0.0.0',
                    service_name => 'REST Web Service'
                }
            ]
        }
    );
};

done_testing();
