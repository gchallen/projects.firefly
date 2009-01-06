#!/usr/bin/perl -w

use strict;
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;

open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";
my $numMotes = $ARGV[1];

my @firingArray;
my @sequenceNumberArray;
my @beforeSize;
my @afterSize;
my @beforeStdDev;
my @afterStdDev;
my @beforeAverage;
my @afterAverage;
my $seenSynch = 0;
my $seenGroup = 0;
my $maxGroupSize = 0;
my $lastGroupFire = 0;
my @groupDiffs;
my @groupSpreads;
my @groupFires;
my $groupFireNumber = 0;
my $maxSeenDiff = 0;
my $minSeenDiff = 1000;
my $latestFire = 0;
my $timeToSync = 0;

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
  
  while ($groupString =~ s/(\([^\)]+\))\,//) {
    my $innerString = $1;
    $innerString =~ /\(([0-9\.]+),\s+([0-9\.]+),\s+([0-9\.]+)\)/;
    $sequenceNumberArray[$1] = $2;  
    push(@tempArray, $3);
  }

  @tempArray = sort {$a <=> $b} (@tempArray);
  my $maxDiff = $tempArray[@tempArray - 1] - $tempArray[0];
  if (($seenSynch == 1) &&
      ($maxDiff > $maxSeenDiff)) {
    $maxSeenDiff = $maxDiff;
  }

  if (($seenSynch == 1) &&
      ($groupSize == $numMotes)) {
    push(@groupSpreads, $maxDiff);
  }
  
  if (($seenSynch == 1) &&
      ($groupSize == $numMotes) &&
      ($maxDiff < $minSeenDiff)) {
    $minSeenDiff = $maxDiff;
  }
  
  if (($seenSynch == 1) &&
      ($groupReceiveTime > $latestFire)) {
    $latestFire = $groupReceiveTime;
  }

  if ($groupSize > $maxGroupSize) {
    $maxGroupSize = $groupSize;
  }
  
  @tempArray = ($groupSize, $groupReceiveTime, $groupID);
  push(@firingArray, \@tempArray);
  if (@firingArray > 10) {
    shift(@firingArray);
  }

  if ($seenGroup == 0) {
    if ($groupSize == $numMotes) {
      $seenGroup = 1;
    }
  }

  my $togetherCount = 0;
  for (my $i = 0; $i < @firingArray; $i++) {
    if ($firingArray[$i]->[0] == $numMotes) {
      $togetherCount++;
    }
  }

  if ($seenSynch == 0) {
    if (($togetherCount / @firingArray) > 0.9) {
      $timeToSync = $firingArray[0]->[1];
      $seenSynch = 1;
    } 
  }

  if ($seenSynch == 0) {
    push(@beforeStdDev, $groupStdDev);
    push(@beforeSize, $groupSize);
    push(@beforeAverage, $groupStdDev);
  } else {
    if ($lastGroupFire != 0) {
      push(@groupDiffs, ($groupReceiveTime - $lastGroupFire));
    }
    $lastGroupFire = $groupReceiveTime;
    my @tempArray = ($groupReceiveTime, $groupFireNumber++);
    push (@groupFires, \@tempArray);
    push(@afterStdDev, $groupStdDev);
    push(@afterSize, $groupSize);
  }
}

# 08 Apr 2005 : GWA : Dump first half of data.

my ($groupSpread50, $groupSpread95);

my $numberVeryClose = 0;
my $totalNumberFires = 0;

$totalNumberFires = sprintf("%d", $latestFire - $timeToSync);

foreach my $currentSpread (@groupSpreads) {
  if ($currentSpread < ($minSeenDiff * 10)) {
    $numberVeryClose++;
  }
}

@groupSpreads = splice(@groupSpreads, @groupSpreads / 2,
@groupSpreads / 2);
my @newNewGroupSpreads = sort {$a <=> $b} @groupSpreads;
foreach my $currentSpreads (@newNewGroupSpreads) {
  print "$currentSpreads\n";
}
