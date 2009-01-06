#!/usr/bin/perl

use strict;

my $fields = shift(@ARGV);
my $with = shift(@ARGV);
my $outputLine = "plot ";
@ARGV = sort {
  ($a =~ /MOTE(\d+)/)[0] <=> ($b =~ /MOTE(\d+)/)[0]
} @ARGV;
for (my $i = 0; $i < @ARGV; $i++) {
  $ARGV[$i] =~ /MOTE(\d+)/;
  $outputLine .= "\'$ARGV[$i]\' u $fields w $with t \"$1\"";
  if ($i != (@ARGV - 1)) {
    $outputLine .= ", ";
  }
}
print "$outputLine";
