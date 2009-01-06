#!/usr/bin/perl

# 13 Dec 2004 : GWA : Take skew data out of our log files for analysis.
#               GT: This is obviously for MOTE data
#
# Usage : ./processSkew.pl <datafile>
# Creates : <datafileroot>-SKEW-MOTE<N>.out for each of N motes present in
#           trace.

use strict;
my $JIFFIES_TO_SEC = 921600;

if (@ARGV != 1)  {
  print "Usage\n";
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

# 13 Dec 2004 : GWA : Need to handle overflow.

my %receiverLast;
my %receiverOverflowCount;
my %senderOverflowCount;
my %senderLast;
my $overflowConstant = 2**32;

$ARGV[0] =~ s/\.out//;
my $outputRoot = $ARGV[0];
foreach my $currentSourceAddr (@sourceAddrs) {
  local *CURRENTOUT;
  open(CURRENTOUT, ">$outputRoot-SKEW-MOTE$currentSourceAddr.out");
  $fileHandle[$currentSourceAddr] = *CURRENTOUT;
  $senderLast{$currentSourceAddr} = 0;
  $senderOverflowCount{$currentSourceAddr} = 0;
  $receiverLast{$currentSourceAddr} = 0;
  $receiverOverflowCount{$currentSourceAddr} = 0;
}

# 13 Dec 2004 : GWA : Now do the processing.

my %receivedStart;
my %senderStart;

while(my $currentLine = <INPUT>) {

  # 13 Dec 2004 : GWA : Skip commenting lines.

  if ($currentLine =~ /^\#/) {
    next;
  }
  
  my @currentArray = split(/\t/, $currentLine);
  my $sourceAddr = $currentArray[0];
  my $receivedTime = $currentArray[2];
  my $sentTime = $currentArray[3];

  # 13 Dec 2004 : GWA : Ack, handle overflows.

  $sentTime += ($overflowConstant * $senderOverflowCount{$sourceAddr});
  $receivedTime += ($overflowConstant * $receiverOverflowCount{$sourceAddr});
  
  if (($receiverLast{$sourceAddr} - $receivedTime) > 
      (2**32 - ($JIFFIES_TO_SEC * 10))) {
    $receiverOverflowCount{$sourceAddr}++;
  }

  if (($senderLast{$sourceAddr} - $sentTime) > 
      (2**32 - ($JIFFIES_TO_SEC * 10))) {
    $senderOverflowCount{$sourceAddr}++;
  }

  $receiverLast{$sourceAddr} = $receivedTime;
  $senderLast{$sourceAddr} = $sentTime;

  local *OUTPUT = $fileHandle[$sourceAddr];

  if ($receivedStart{$sourceAddr} == undef) {
    $receivedStart{$sourceAddr} = $receivedTime;
  }
  if ($senderStart{$sourceAddr} == undef) {
    $senderStart{$sourceAddr} = $sentTime;
  }

  my $skew = ($receivedTime - $receivedStart{$sourceAddr}) -
             ($sentTime - $senderStart{$sourceAddr});
  $receivedTime -= $receivedStart{$sourceAddr};

  $receivedTime /= $JIFFIES_TO_SEC;
  $skew /= $JIFFIES_TO_SEC;
  print OUTPUT "$receivedTime\t$skew\n";
}
