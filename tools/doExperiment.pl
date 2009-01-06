#!/usr/bin/perl

use strict;

my $experimentFile = $ARGV[0];
my $dataRoot = $ARGV[1];
my $TOSDIR = $ARGV[2];
my $uniqueCounter = 1;
my $lastDataDir = "";

open(INPUT, "$experimentFile") 
  or die "Couldn't open $experimentFile\n";

while (my $line = <INPUT>) {
  if ($line =~ /^\#/) {
    next;
  }
  chomp($line);
  my @line = split(" ", $line);
  my $DataDir = $line[0];
  my $FFConstant = $line[1];
  my $TopologyFile = $line[2];
  my $NumMotes = $line[3];
  my $Time = $line[4];
  my $TopologyTag = $line[5];
  my $RandomSeed = $line[6];
  my $Makefile = $line[7];
  my $processDelay = $line[8];
  my $sendDelay = $line[9];
  my $ignorePeriod = $line[10];
  my $ExtraTag = $line[11];

  # 06 Jan 2005 : GWA : Build directory and file string.

  if ($lastDataDir ne $DataDir) {
    `mkdir -p $dataRoot/$DataDir`;
    `mkdir -p $dataRoot/$DataDir/FitsUsed`;
    `mkdir -p $dataRoot/$DataDir/FitsMsg`;
    print "Backing up Fits Directory Used\n";
    `cp -R * $dataRoot/$DataDir/FitsUsed`;
  }

  # 06 Jan 2005 : GWA : Modify .h file and rebuild.

  `mv FitsMsg.h FitsMsg.h.bac 2> /dev/null`;
  open(MUNGE, "FitsMsg.h.bac");
  open(OUTPUT, ">FitsMsg.h");
  while (my $currentLine = <MUNGE>) {
    if ($currentLine =~ /FIRINGFUNCTIONLOG2M_CONSTANT/) {
      $currentLine = "FIRINGFUNCTIONLOG2M_CONSTANT = $FFConstant,\n";
    }
    if ($currentLine =~ /FITS_PROCESS_DELAY/) {
      $currentLine = "FITS_PROCESS_DELAY = $processDelay,\n";
    }
    if ($currentLine =~ /FITS_SEND_DELAY/) {
      $currentLine = "FITS_SEND_DELAY = $sendDelay,\n";
    }
    if ($currentLine =~ /FITS_IGNORE_PERIOD /) {
      $currentLine = "FITS_IGNORE_PERIOD = $ignorePeriod,\n";
    }
    print OUTPUT $currentLine;
  }
  close(OUTPUT);
  my $outH = "$dataRoot/$DataDir/FitsMsg/" . $uniqueCounter . ".h";
  `cp FitsMsg.h $outH`;
  $ENV{'TOSDIR'} = "$TOSDIR";
  `make -f $Makefile pc $ExtraTag`; # 2> /dev/null`;

  $lastDataDir = $DataDir;
  my $outputFile = $DataDir . "-" . $NumMotes . "MOTES-" . $FFConstant .
                    "CONSTANT-" . $TopologyTag . "-" . $uniqueCounter . ".out";
  $uniqueCounter++;
  $outputFile = $dataRoot . "/" . $DataDir . "/" . $outputFile;
  open(ANNOTATE, ">$outputFile");
  my $now = localtime();
  my $lastCounter = $uniqueCounter - 1;
  print ANNOTATE <<OUT;
# $now
# FFConstant: $FFConstant
# TopologyFile: $TopologyFile
# TopologyTag: $TopologyTag
# NumMotes: $NumMotes
# Time: $Time
# TOSDIR: $TOSDIR
# RandomSeed: $RandomSeed
# ExtraMakeTag: $ExtraTag
# Makefile: $Makefile
# UniqueCounter: $lastCounter
# ProcessDelay: $processDelay
# SendDelay: $sendDelay
# IgnorePeriod: $ignorePeriod
OUT
  close(ANNOTATE);

  # 06 Jan 2005 : GWA : Build command string.
  
  my $commandString;
  if ($TopologyFile ne "-") {
    $commandString = "./build/pc/main.exe -t=$Time -r=lossy -seed=$RandomSeed";
    $commandString .= " -rf=$TopologyFile $NumMotes >> $outputFile";
  } else {
    $commandString = "./build/pc/main.exe -t=$Time -seed=$RandomSeed";
    $commandString .= " $NumMotes >> $outputFile";
  }
  
  print STDERR "Running $NumMotes with topology file $TopologyFile";
  print STDERR " and $FFConstant FF constant\n";
  print STDERR "$commandString\n";
  $ENV{'DBG'} = "usr1";
  `$commandString`;
  print STDERR "Converting to TOSSIM\n";
  `../tools/convertTOSSIM.pl $outputFile temp`;
  `mv temp $outputFile`;
  print STDERR "Gzipping\n";
  `gzip $outputFile`;
  `mv FitsMsg.h.bac FitsMsg.h 2> /dev/null`;
}
