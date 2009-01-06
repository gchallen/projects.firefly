#!/usr/bin/perl -w

use strict;
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;

open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";

my $syncTime = $ARGV[1];

while (my $line = <INPUT>) {
  if ($line !~
    /^([0-9\.]+)\s+([0-9\.]+)\s+([0-9\.]+)\s+([0-9\.]+)\s+([0-9\.]+)\s+([0-9\.]+)\s+(.*)/) {
    next;
  }
  
  my $groupID = $1;
  my $groupReceiveTime = $4;
  my $groupStdDev = $5;
  my $groupSize = $3;
  my $groupString = $7;
  my @tempArray;
  my @firingTimeArray;
  
  if ($groupReceiveTime < $syncTime) {
    next;
  }
  while ($groupString =~ s/(\([^\)]+\))\,//) {
    my $innerString = $1;
    $innerString =~ /\(([0-9\.]+),\s+([0-9\.]+),\s+([0-9\.]+)\)/;
    printf ("%d %f %f\n", $1, $groupReceiveTime, ($3 - $groupReceiveTime));
  }
} 
