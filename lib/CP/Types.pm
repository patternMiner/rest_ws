
=head1 CP::Types

Storage related parameter types, throwing the following
formatted and parsable text when the input is invalid:

 "InvalidParameter:<parameter_value> is not a valid <parameter_name>.:"

=head1 SEE ALSO

CP::StorageManager

=cut

package CP::Types;

use warnings;
use strict;
use Type::Library
    -base,
    -declare => qw( MaxSize );
use Type::Utils -all;
use Types::Standard qw ( Str );

declare MaxSize,
  as Str,
    where { $_ =~ m/^\d+[BKMGT]{1}$/ }
    message {
            return "$_ is not a valid max_size.";
    };

1;
