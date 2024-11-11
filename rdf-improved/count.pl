#!perl -nw

use strict;
use warnings;

our $total;
BEGIN {$total = 0}
END {print "$total\n"}

m{ INFO |^Total} and next;
if (my ($file,$n) = m{^(.*) : Triples = (.*)$}) {
  $n =~ s{,}{}g;
  $total += $n;
  $_ = "$n\t$file\n"
};
print;
