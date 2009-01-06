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

if (@ARGV < 1)  {
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

$ARGV[0] =~ s/\.out//;
my $outputRoot = $ARGV[0];

foreach my $currentSourceAddr (@sourceAddrs) {
  local *CURRENTOUT;
  open(CURRENTOUT, ">$outputRoot-MOTE$currentSourceAddr.out");
  $fileHandle[$currentSourceAddr] = *CURRENTOUT;
}

while(my $currentLine = <INPUT>) {
  if ($currentLine !~ /^([0-9\.]+)\s+/) {
    next;
  }

  local *OUTPUT = $fileHandle[$1];
  print OUTPUT $currentLine;
}
