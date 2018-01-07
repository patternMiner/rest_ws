#!/usr/bin/env perl

# usage:
# ./rest_ws.pl daemon --home <app_home_path>

use strict;
use warnings;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
use Mojolicious::Commands;


# Start command line interface for application
Mojolicious::Commands->start_app('RestWs');
