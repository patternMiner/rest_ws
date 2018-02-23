use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME            => 'RestWs',
  VERSION_FROM    => 'lib/RestWs.pm',
  test            => { TESTS => 't/*.t t/*/*.t' }
);
