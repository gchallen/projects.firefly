#!/usr/bin/perl

use strict;

my $index = $ARGV[0];
my $skipCount = $ARGV[1];
my $input = $ARGV[2];

open(INPUT, "$input")
  or die "Can't open $input\n";

my $loopCount;
my @inArray;
my %outHash;
my $runningCount = 0;

while (my $line = <INPUT>) {
  if ($loopCount > $skipCount) {
    my @line = split(/\s/, $line);
    push(@inArray, $line[$index]);
  }
  $loopCount++;
}

@inArray = sort {$a <=> $b} @inArray;

for (my $i = 0; $i < @inArray; $i++) {
  $runningCount++;
  $outHash{$inArray[$i]} = $runningCount;
}

foreach my $currentKey (sort {$a <=> $b} keys(%outHash)) {
  printf("%e\t%e\n", $currentKey, $outHash{$currentKey} / $runningCount);
}
