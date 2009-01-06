#!/usr/bin/perl

# 13 Dec 2004 : GWA : Take event data out of the log files for analysis.
#               This works when we have a common time base (i.e., one mote
#               that can here all of the others), so we'll have to do
#               something more clever than this when we get to real multihop
#               topologies to sort out all of the different receiver time
#               bases.
#
# Usage : ./processGroups.pl
# Creates : <datafileroot>-EVENT-MOTE<N>.out for each of N motes present in
#           trace.

use strict;
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;

my $JIFFIES_TO_SEC = 921600;

if (@ARGV != 2)  {
    print "Usage ./processGroups.pl eventAllFile processGroupsBucketSize \n";
    print "Bucket size=0.1 for simulator and 0.01 for real motes \n";
  exit();
}

# 13 Dec 2004 : GWA : Ugly hack to get the various motes used before we
#               actually start processing.

my $uniqSourceaddr;
if ($ARGV[0] =~ /gz$/) {
  $uniqSourceaddr = `zcat $ARGV[0] | grep -o -P ^[0-9]+ | sort | uniq`;
} else {
  $uniqSourceaddr = `grep -o -P ^[0-9]+ $ARGV[0] | sort | uniq`;
}
chomp $uniqSourceaddr;
my @sourceAddrs = split(/\s/, $uniqSourceaddr);

# 13 Dec 2004 : GWA : Set up file handles.

my @fileHandle;

if ($ARGV[0] =~ /gz$/) {
  open(INPUT, "zcat $ARGV[0] | sort -n -k 3,3|");
  $ARGV[0] =~ s/\.gz//;
} else {
  open(INPUT, "cat $ARGV[0] | sort -n -k 3,3|");
}

my $interval = $ARGV[1];  ## This is the bucket size

$ARGV[0] =~ s/\.out//;
$ARGV[0] =~ s/EVENT-ALL-//;
my $outputRoot = $ARGV[0];
open(OUTPUT, ">$outputRoot-GROUPS.out");

my %senderSeqno;
my @eventArray;
my $groupID = 0;

foreach my $currentSourceAddr (@sourceAddrs) {
  $senderSeqno{$currentSourceAddr} = 0;
}

# 13 Dec 2004 : GWA : Now do the processing.

while (my $currentLine = <INPUT>) {
  
  # 13 Dec 2004 : GWA : Skip commenting lines.
  
  if ($currentLine =~ /^\#/) {
    next;
  }
  
  my @currentArray = split(/\t/, $currentLine);
  my $sourceAddr = $currentArray[0];
  my $seqno = $currentArray[1];
  my $receivedTime = $currentArray[2];
  chomp($receivedTime);  

  # 13 Dec 2004 : GWA : I guess it's multi-path effects that cause us to
  #               sometimes receive packets twice.  By default we ignore the
  #               later.
  
  # 02 Jan 2005 : GWA : Dumping this as it's causing problems.

  if ($seqno <= $senderSeqno{$sourceAddr}) {
    next;
  }
  $senderSeqno{$sourceAddr} = $seqno;
 
  # 02 Jan 2004 : GWA : Yikes.  Forgot what the indexes mean.  Here's the
  #               theory:
  #               
  #               0 : receivedTime (event time)
  #               1 : holding count
  #               2 : holder id
  #               3 : claiming count
  #               4 : claimed?
  #               5 : claim finished
  #
  #               Adding a few:
  #
  #               6 : Node ID
  #               7 : Node Seqno

  my @tempArray;
  $tempArray[0] = $receivedTime;
  $tempArray[1] = 0;
  $tempArray[2] = 0;
  $tempArray[3] = 0;
  $tempArray[4] = 0;
  $tempArray[6] = $sourceAddr;
  $tempArray[7] = $seqno;

  push(@eventArray, \@tempArray);

  for (my $i = 0; $i < @eventArray; $i++) {
    $eventArray[$i]->[1] = 0;
    $eventArray[$i]->[2] = $i;
    $eventArray[$i]->[3] = 0;
    $eventArray[$i]->[4] = 0;
    $eventArray[$i]->[5] = 0;
  }

  my $didSwap;
  do {
    my $maxClaimCount = 0;
    $didSwap = 0;
    for (my $i = 0; $i < @eventArray; $i++) {
      if (($eventArray[$i]->[0] < ($receivedTime - $interval)) &&
          ($eventArray[$i]->[5] != 1)) {
        my $claimedCount = 0;
        for (my $j = $i; $j < @eventArray; $j++) {
          if (($eventArray[$j]->[0] > ($eventArray[$i]->[0] + $interval)) ||
              ($eventArray[$j]->[5] == 1)) {
            last;
          }
          $claimedCount++;
        }
        if ($claimedCount > $maxClaimCount) {
          $maxClaimCount = $claimedCount;
        }
        for (my $j = $i; $j < @eventArray; $j++) {
          if ($eventArray[$j]->[0] > ($eventArray[$i]->[0] + $interval)) {
            last;
          }
          if ($eventArray[$j]->[3] < $claimedCount) {
            if ($eventArray[$j]->[4] == 1) {
              $eventArray[$eventArray[$j]->[2]]->[1]--;
            }
            $eventArray[$i]->[1]++;
            $eventArray[$j]->[2] = $i;
            $eventArray[$j]->[3] = $claimedCount;
            $eventArray[$j]->[4] = 1;
            $didSwap = 1;
          }
        }
      }
    }
    for (my $i = 0; $i < @eventArray; $i++) {
      if ($eventArray[$i]->[0] < ($receivedTime - $interval)) {
        if ($eventArray[$i]->[5] == 1) {
          next;
        }
        if (($eventArray[$i]->[3] == $maxClaimCount) &&
            ($eventArray[$eventArray[$i]->[2]]->[1] == $maxClaimCount)) {
          $eventArray[$i]->[5] = 1;
        } else {
          $eventArray[$i]->[2] = $i;
          $eventArray[$i]->[4] = 0;
        }
      }
    }
  } while ($didSwap == 1);

  my $dropCount = 0;
  my $realDropCount = 0;
  my $claimID = 0;
  my $claimStarted = 0;
  my $memberString = "";
  my $groupReceiveTime = 0;
  my @doStatistics;
  my @doMax;

  #print OUTPUT "Start\n";
  for (my $i = 0; $i < @eventArray; $i++) {
    if ($eventArray[$i]->[0] >= ($receivedTime - $interval)) {
      last;
    } elsif ($eventArray[$i]->[0] < ($receivedTime - (2 * $interval))) {
      if ($eventArray[$i]->[2] == $i) {
        if ($dropCount > 0) {
          my $average = Statistics::Basic::Mean->new(\@doStatistics)->query;
          my $stdev = Statistics::Basic::StdDev->new(\@doStatistics)->query;
          @doMax = sort(@doMax);
          my $maxDiff = $doMax[@doMax - 1] - $doMax[0];
          printf OUTPUT ("%u\t%f\t%u\t%f\t%f\t%f\t%s\n", 
                         $groupID++,
                         $groupReceiveTime,
                         $dropCount,
                         $average,
                         $stdev,
                         $maxDiff,
                         $memberString);
          $dropCount = 0;
        } 
        @doStatistics = ();
        @doMax = ();
        $memberString = "";
        $groupReceiveTime = $eventArray[$i]->[0];
        $claimStarted = 1;
        $claimID = $i;
      }
      $memberString .= sprintf("\(%u, %u, %f\),", 
                               $eventArray[$i]->[6],
                               $eventArray[$i]->[7],
                               $eventArray[$i]->[0]);
      push(@doStatistics, $eventArray[$i]->[0]);
      push(@doMax, $eventArray[$i]->[0]);
      $dropCount++;
      $realDropCount++;
    } else {
      if (($claimStarted == 1) &&
          ($claimID == $eventArray[$i]->[2])) {
        $memberString .= sprintf("\(%u, %u, %f\),", 
                                 $eventArray[$i]->[6],
                                 $eventArray[$i]->[7],
                                 $eventArray[$i]->[0]);
        push(@doStatistics, $eventArray[$i]->[0]);
        push(@doMax, $eventArray[$i]->[0]);
        $realDropCount++;
        $dropCount++;
      } else {
        last;
      }
    }
  }
  
  if ($dropCount > 0) {
    my $average = Statistics::Basic::Mean->new(\@doStatistics)->query;
    my $stdev = Statistics::Basic::StdDev->new(\@doStatistics)->query;
    @doMax = sort(@doMax);
    my $maxDiff = $doMax[@doMax - 1] - $doMax[0];
    if ($maxDiff > $interval) {
      printf STDERR ("%u\t%f\t%u\t%f\t%f\t%f\t%s\n", 
                     $groupID++,
                     $groupReceiveTime,
                     $dropCount,
                     $average,
                     $stdev,
                     $maxDiff,
                     $memberString);
      print STDERR "DropCount : $dropCount\n";
      foreach my $currentEvent (@eventArray) {
        foreach my $currentKey (@{$currentEvent}) {
          print STDERR "$currentKey\t";
        }
        print "\n";
      }
      exit(1);
    }
    printf OUTPUT ("%u\t%f\t%u\t%f\t%f\t%f\t%s\n", 
                   $groupID++,
                   $groupReceiveTime,
                   $dropCount,
                   $average,
                   $stdev,
                   $maxDiff,
                   $memberString);
  }
  #print OUTPUT "End\n"; 
  
  for (my $i = 0; $i < $realDropCount; $i++) {
    shift(@eventArray);
  }
}


#foreach my $currentOldEvent (@eventArray) {
#  print OUTPUT "$currentOldEvent->[0]\t$currentOldEvent->[1]\n";
#}
