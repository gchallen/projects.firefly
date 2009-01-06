#!/usr/bin/perl

# 13 Dec 2004 : GWA : Take event data out of the log files for analysis.
#               This works when we have a common time base (i.e., one mote
#               that can here all of the others), so we'll have to do
#               something more clever than this when we get to real multihop
#               topologies to sort out all of the different receiver time
#               bases.
#
# Usage : ./processEvents.pl <datafile>
# Creates : <datafileroot>-EVENT-MOTE<N>.out for each of N motes present in
#           trace.

use strict;
my $JIFFIES_TO_SEC = 921600;

if (@ARGV < 1)  {
  print "Usage: $0 dataFile <ALL> \n";
  print "Output: sourceAddr seqno event-time(secs) mod-of-event(or relative phase) \n";
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
  open(INPUT, "zcat $ARGV[0]|");
  $ARGV[0] =~ s/\.gz//;
} else {
  open(INPUT, "$ARGV[0]");
}

my $kind = $ARGV[1];
my $tossUnSynced = $ARGV[2];

# 13 Dec 2004 : GWA : Need to handle overflow.

my %receiverLast;
my %receiverOverflowCount;
my %senderOverflowCount;
my %senderLast;
my $overflowConstant = 2**32;
my %senderSeqno;

$ARGV[0] =~ s/\.out//;
my $outputRoot = $ARGV[0];

if ($kind eq "ALL") {
  open(ALLHANDLE, ">$outputRoot-EVENT-ALL.out");
}

foreach my $currentSourceAddr (@sourceAddrs) {
  local *CURRENTOUT;
  if ($kind ne "ALL") {
    open(CURRENTOUT, ">$outputRoot-EVENT-MOTE$currentSourceAddr.out");
  }
  $fileHandle[$currentSourceAddr] = *CURRENTOUT;
  $senderLast{$currentSourceAddr} = 0;
  $senderOverflowCount{$currentSourceAddr} = 0;
  $receiverLast{$currentSourceAddr} = 0;
  $receiverOverflowCount{$currentSourceAddr} = 0;
  $senderSeqno{$currentSourceAddr} = 0;
}

# 13 Dec 2004 : GWA : Now do the processing.

my %receivedStart;
my %senderStart;
my $tossimFLAG = 0;
my $FTSPFlag = 0;

while(my $currentLine = <INPUT>) {

  # 13 Dec 2004 : GWA : Skip commenting lines.
  
  if ($currentLine =~ /^\#/) {
    if ($currentLine =~ /^.{2}(JIFFIES)\s+(\S*)/) {
      $JIFFIES_TO_SEC = $2;
    }
    if ($currentLine =~ /^.{2}(TOSSIM)/) {
      $tossimFLAG = 1;
    }
    if ($currentLine =~ /^.{2}(FTSP)/) {
      $tossimFLAG = 1;
      $FTSPFlag = 1;
    }
    next;
  }
  
  my @currentArray = split(/\t/, $currentLine);
  my $sourceAddr = $currentArray[0];
  my $seqno = $currentArray[1];
  my $receivedTime = $currentArray[2];
  
  # 13 Dec 2004 : GWA : I guess it's multi-path effects that cause us to
  #               sometimes receive packets twice.  By default we ignore the
  #               later.
  
  if ($seqno <= $senderSeqno{$sourceAddr}) {
    next;
  }

  my $seqnoDiff = $seqno - $senderSeqno{$sourceAddr};
  $senderSeqno{$sourceAddr} = $seqno;

  # 13 Dec 2004 : GWA : The only real change from processSkew.  Correct the
  #               event time by removing the delay.

  $receivedTime -= $currentArray[4];

  if (($currentArray[5] != 1) &&
      ($tossUnSynced == 1)) {
    next;
  }
  # 13 Dec 2004 : GWA : Ack, handle overflows.

  $receivedTime += ($overflowConstant * $receiverOverflowCount{$sourceAddr});
  
  if (($receiverLast{$sourceAddr} - $receivedTime) > 
      (2**32 - ($JIFFIES_TO_SEC * 10))) {
    $receivedTime += $overflowConstant;
    $receiverOverflowCount{$sourceAddr}++;
  }
  
  local *OUTPUT = $fileHandle[$sourceAddr];
  
  if ($receivedStart{$sourceAddr} == undef) {
    $receivedStart{$sourceAddr} = $receivedTime;
  }

  my $event = $receivedTime;
  my $diff;

  # 15 Dec 2004 : GWA : With TOSSIM mote start times are randomized, but not
  #               the actual system time, so we don't want to correct this
  #               here.

  if ($tossimFLAG == 0) {
    $event -= $receivedStart{$sourceAddr};
  }

  if ($receiverLast{$sourceAddr} == 0) {
    $diff = $JIFFIES_TO_SEC;
  } else {
    $diff = $receivedTime - $receiverLast{$sourceAddr};
    $diff /= $seqnoDiff;
  }
  
  $receiverLast{$sourceAddr} = $receivedTime;
  if ($tossimFLAG == 0) {
    $receivedTime -= $receivedStart{$sourceAddr};
  }
  
  $event /= $JIFFIES_TO_SEC;
  my $intEvent = sprintf("%d", $event);
  my $modulo = ($event - $intEvent);
  if ($kind ne "ALL") {
    print OUTPUT "$seqno\t$event\t$diff\t$modulo\n";
  } else {
    print ALLHANDLE "$sourceAddr\t$seqno\t$event\t$modulo\n";
  }
}
