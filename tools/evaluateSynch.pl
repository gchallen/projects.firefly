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
      print "First Group Fire at Time $groupReceiveTime\n";
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
      print "Time to Sync : $firingArray[0]->[1]\n";
      $timeToSync = $firingArray[0]->[1];
      print "Acheived Synchronization at Group Fire $firingArray[0]->[2]\n";
      for (my $i = 0; $i < @sequenceNumberArray; $i++) {
        if (defined($sequenceNumberArray[$i])) {
          print "Acheived Synchronization on Mote $i Seqno " .
                $sequenceNumberArray[$i] . "\n";
        }
      }
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

my @newGroupSpreads = 
  splice(@groupSpreads, @groupSpreads / 2, @groupSpreads / 2);
my @newNewGroupSpreads = sort {$a <=> $b} @newGroupSpreads;
my $rightMoment = sprintf("%d", (@newNewGroupSpreads * 0.95) - 1);
my $secondRightMoment = sprintf("%d", (@newNewGroupSpreads * 0.5) - 1);
$groupSpread95 = $newNewGroupSpreads[$rightMoment];
$groupSpread50 = $newNewGroupSpreads[$secondRightMoment];

my $beforeGroupSizeAverage =
  Statistics::Basic::Mean->new(\@beforeSize)->query;
my $beforeGroupSizeStdDev =
  Statistics::Basic::StdDev->new(\@beforeSize)->query;
my $afterGroupSizeAverage =
  Statistics::Basic::Mean->new(\@afterSize)->query;
my $afterGroupSizeStdDev =
  Statistics::Basic::StdDev->new(\@afterSize)->query;
my $afterGroupDiffStdDev =
  Statistics::Basic::StdDev->new(\@groupDiffs)->query;
my $afterGroupStdAv =
  Statistics::Basic::Mean->new(\@afterStdDev)->query;

my $fitData;
if ($seenSynch == 1) {
  $fitData = &linfit(\@groupFires);
}

# print "Before Synchronization Group Size Average $beforeGroupSizeAverage\n";
print "Before Synchronization Group Size StdDev $beforeGroupSizeStdDev\n";
print "Largest Group : $maxGroupSize\n";

if ($seenSynch == 1) {
  print "SYNC\n";
  print "After Synchronization Group Size Average $afterGroupSizeAverage\n";
  print "After Synchronization Group Size StdDev $afterGroupSizeStdDev\n";
  print "After Synchronization Group Period Diff StdDev" .
        " $afterGroupDiffStdDev\n";
  print "After Spread (Av StdDev) : $afterGroupStdAv\n";
  print "After Group Frequency : $fitData->[0]\n";
  print "After Spread (Max) : $maxSeenDiff\n";
  print "After Spread 90 : $groupSpread95\n";
  print "After Spread 50 : $groupSpread50\n";
  print "Best Acheived : $minSeenDiff\n";
  print "Number Very Close : $numberVeryClose\n";
  print "Total Number Projected After Group Fires : $totalNumberFires\n";
} else {
  print "NOSYNC\n";
}

sub linfit {
  my $arrayRef = shift;
  my $s = 0; 
  my ($del, $b, $a);
  my ($sx, $sy, $sxx, $sxy);

  foreach my $currentRef (@{$arrayRef}) {
    $sx += $currentRef->[0];
    $sy += $currentRef->[1];
    $sxx += ($currentRef->[0] * $currentRef->[0]);
    $sxy += $currentRef->[0] * $currentRef->[1];
    $s++;
  }

  $del = $s*$sxx - $sx*$sx;

  if ($del) {
    $b = ($sxx*$sy - $sx*$sxy) / $del;
    $a = ($s*$sxy - $sx*$sy) / $del;
  } 
  my @tempArray = ($a, $b);
  return \@tempArray;
}
