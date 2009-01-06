#!/usr/bin/perl

# 15 Dec 2004 : GT : Convert TOSSIM output to a format that can be displayed.
#                        


use strict;

if (@ARGV != 2) {
  print "Usage\n";
}

my $infile  = $ARGV[0];
my $outfile = $ARGV[1];

if ( $outfile =~ /auto/i ) {
  $outfile = $infile;
  $infile =~ s/\.out$/\.raw/;
  system "mv $ARGV[0] $infile";
}

open(INPUT, "$infile");
open (OUTPUT, ">$outfile");

print OUTPUT <<DONE;
# MOTEID\tSEQNO\tRECEIVETIME\tSENTTIME\tSENTDELAY
# JIFFIES 4000000
# TOSSIM
DONE

while (my $currentLine = <INPUT>) {
  chomp($currentLine);
  my @firstArray = split(/:/, $currentLine);
  if ($currentLine =~ /^#/) {
    print OUTPUT $currentLine . "\n";
    next;
  }
  if ($currentLine =~ /Simulation/) {
    next;
  }
  if ($firstArray[0] eq "SIM") {
    next;
  }
  my @secondArray = split(/\t/, $firstArray[1]);

  my $sourceAddr = $firstArray[0];
  my $seqno = $secondArray[0];
  my $sentTime = sprintf("%u", $secondArray[1]);
  my $sendDelay = sprintf("%u", $secondArray[2]);
  my $sentFinal = $sentTime + $sendDelay;
  
  print OUTPUT "$sourceAddr\t$seqno\t$sentFinal\t$sentTime\t$sendDelay\n";
}
