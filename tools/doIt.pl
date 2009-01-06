#!/usr/bin/perl

# 09 Jan 2005 : GWA : Designed as a top-level processing script.  Should
#               take, as arguments, at minimum the directory to process and
#               the tab-delimited data file to modify.  Files in the
#               directory to process should be already converted and gzipped.


## processGroupsBucketSize: 0.1 for simulator - the interval within which 
## a bunch of nodes firing count as a group.
## This is set to 0.01 for Motelab.

use strict;
use FindBin;
use File::Temp qw/ tempfile tempdir /;

my @keysInOrder = (
# 11 Mar 2005 : GWA : Basic stuff
"Directory", "Filename", "# Nodes", "MoteLab/TOSSIM",
# 11 Mar 2005 : GWA : Topology info
"Topology Tag", "Topology File", 
# 11 Mar 2005 : GWA : Experiment parameters.
"Experiment Time", "Firing Function", "Random Seed",
"FF Constant", "Ignore Period", "Process Delay", "Send Delay",
# 11 Mar 2005 : GWA : Results
"Time to Sync", "After Spread (Av StdDev)", "After Spread (Max)",
"After Spread 50", "After Spread 90", 
"Largest Group", "After Group Frequency", 
# 11 Mar 2005 : GWA : Other random info
"Receiver", "Makefile", "Extra Make Tag", 
"Header Hash", "Source Hash", "Unique Counter");

if ((@ARGV < 2) ||
    (@ARGV > 4)) {
  print <<DONE;
Usage doIt.pl <directory> <output file> [<processGroups bucket size>] [<firing
function>]
DONE
exit(1);
}

my $processDirectory = $ARGV[0];
my $dataFiles = $ARGV[1];
my $tempDir = tempdir( CLEANUP => 1 );
#my $tempDir = $ARGV[2];
my $processGroupsBucketSize = 0.1;
my $firingFunction = "LOG";

if (@ARGV > 3) {
  $processGroupsBucketSize = $ARGV[3];
}

if (@ARGV > 4) {
  $firingFunction = $ARGV[4];
}

my @dataArray;

# 09 Jan 2005 : GWA : First thing to do is find files to process.

my $processFiles = `find $processDirectory -type f -name "*.out.gz"`;
my @processFiles = split("\n", $processFiles);

my $numFiles = $#processFiles;

# 09 Jan 2005 : GWA : Create a temporary directory for us to use for output
#               files.

open(OUTPUT, ">$dataFiles") or die "Can't open output file!\n";

foreach my $printKey (@keysInOrder) {
  print OUTPUT "$printKey\t";
}
print OUTPUT "\n";

print STDERR ($numFiles + 1) .  " files to process.\n";

# 09 Jan 2005 : GWA : Step through the array, processing as we go.

my $currentFile;
my $currentFileNumber = 0;
foreach my $currentFile (@processFiles) {

  # 09 Jan 2005 : GWA : Yikes, some munging to do to get certain data.
  
  my @fileNameMunge = split("/", $currentFile);
  my %currentDataHash;
  
  # 09 Jan 2005 : GWA : Filename should be last part, directory name before
  #               it.  We need at least that much of the path, so if we don't
  #               get it we have to bail.

  if (@fileNameMunge < 2) {
    print <<OOPS;
Please pass the full path of the directory to be processed to doIt.pl, or at
least enough so that I can figure out the containing directory name.
OOPS
    exit(1);
  }
  
  my $fileName = $fileNameMunge[@fileNameMunge - 1];
  $currentDataHash{"Directory"} = $fileNameMunge[@fileNameMunge - 2];
  my $fileNameRoot = $fileName;
  
  # 09 Jan 2005 : GWA : Make sure that we have actual correct datafiles.

  if ($fileName !~ /\.out\.gz/) {
    print <<OOPS;
Filename in wrong format.  Gzipped?
OOPS
    exit(1);
  }
  
  # 09 Jan 2005 : GWA : Make sure that there is valid data in the file and
  #               identify it as MoteLab or TOSSIM.
  
  my $fileNameHead = `zcat $currentFile | head -n 20`;
  my @fileNameHead = split("\n", $fileNameHead);
  if (@fileNameHead < 20) {
    print <<OOPS;
Problem with data file: shorter than 20 lines! This is probably a problem. Exiting.
OOPS
    exit(1);
  }

  # 11 Mar 2005 : GWA : We stuff this info in the header now; the filenames
  #               just serve as hints.

  foreach my $headerCurrentLine (@fileNameHead) {

    # 11 Mar 2005 : GWA : Make sure we're still in the header.
    
    if ($fileNameHead !~ /^\#/) {
      last;
    }
    if ($headerCurrentLine =~ /(TOSSIM|MOTELAB)/) {
      $currentDataHash{"MoteLab/TOSSIM"} = $1;
    } elsif ($headerCurrentLine =~ /FFConstant:\s*(\d+)/) {
      $currentDataHash{"FF Constant"} = $1;
    } elsif ($headerCurrentLine =~ /TopologyFile:\s*([A-Za-z0-9_-]+)/) {
      $currentDataHash{"Topology File"} = $1;
    } elsif ($headerCurrentLine =~ /TopologyTag:\s*(\w+)/) {
      $currentDataHash{"Topology Tag"} = $1;
    } elsif ($headerCurrentLine =~ /NumMotes:\s*(\d+)/) {
      $currentDataHash{"# Nodes"} = $1;
    } elsif ($headerCurrentLine =~ /Time:\s*(\d+)/) {
      $currentDataHash{"Experiment Time"} = $1;
    } elsif ($headerCurrentLine =~ /UniqueCounter:\s*(\d+)/) {
      $currentDataHash{"Unique Counter"} = $1;
    } elsif ($headerCurrentLine =~ /ProcessDelay:\s*(\d+)/) {
      $currentDataHash{"Process Delay"} = $1;
    } elsif ($headerCurrentLine =~ /SendDelay:\s*(\d+)/) {
      $currentDataHash{"Send Delay"} = $1;
    } elsif ($headerCurrentLine =~ /IgnorePeriod:\s*(\d+)/) {
      $currentDataHash{"Ignore Period"} = $1;
    } elsif ($headerCurrentLine =~ /Makefile:\s*(\w+)/) {
      $currentDataHash{"Makefile"} = $1;
    } elsif ($headerCurrentLine =~ /RandomSeed:\s*(\w+)/) {
      $currentDataHash{"Random Seed"} = $1;
    } elsif ($headerCurrentLine =~ /ExtraMakeTag:\s*(.*)$/) {
      $currentDataHash{"Extra Make Tag"} = $1;
    }
  }

  # 11 Mar 2005 : GWA : Make sure we got all the info we need.

  if (!defined($currentDataHash{"MoteLab/TOSSIM"})) {
    print <<OOPS;
Problem with data file: no TOSSIM or MoteLab tag.  Exiting.
OOPS
    exit(1);
  }
  if (!defined($currentDataHash{"FF Constant"})) {
    print <<OOPS;
Problem with data file: could not determine FF constant.  Exiting.
OOPS
    exit(1);
  }
  if (!defined($currentDataHash{"Topology File"})) {
    print <<OOPS;
Problem with data file: could not determine Topology File.  Exiting.
OOPS
    exit(1);
  }
  if (!defined($currentDataHash{"Topology Tag"})) {
    # 11 Mar 2005 : GWA : We forgot this once, so if we don't find it in the
    #               header check the file name.

    if ($fileName !~ /(GRID|ALLTOALL|LINE|RING)/) {
      print <<OOPS;
Problem with data file: could not determine topology.  Exiting.
OOPS
      exit(1);
    }
    $currentDataHash{"Topology"} = $1;
  }
  if (!defined($currentDataHash{"# Nodes"})) {
    print <<OOPS;
Problem with data file: could not determine number of motes.  Exiting.
OOPS
    exit(1);
  }
  if (!defined($currentDataHash{"Experiment Time"})) {
    print <<OOPS;
Problem with data file: could not determine experiment time.  Exiting.
OOPS
    exit(1);
  }
  if (!defined($currentDataHash{"Unique Counter"})) {
    print <<OOPS;
Problem with data file: could not get Unique Counter.  Exiting.
OOPS
    exit(1);
  } 
  if (!defined($currentDataHash{"Process Delay"})) {
    print <<OOPS;
Problem with data file: could not get Process Delay.  Exiting.
OOPS
    exit(1);
  } 
  if (!defined($currentDataHash{"Send Delay"})) {
    print <<OOPS;
Problem with data file: could not get Send Delay.  Exiting.
OOPS
    exit(1);
  } 
  if (!defined($currentDataHash{"Ignore Period"})) {
    print <<OOPS;
Problem with data file: could not get Ignore Period.  Exiting.
OOPS
    exit(1);
  } 
  if (!defined($currentDataHash{"Makefile"})) {
    print <<OOPS;
Problem with data file: could not get Makefile.  Exiting.
OOPS
    exit(1);
  } 
  if (!defined($currentDataHash{"Random Seed"})) {
    print <<OOPS;
Problem with data file: could not get Random Seed.  Exiting.
OOPS
    exit(1);
  } 

  # 11 Mar 2005 : GWA : This is given on the command line.

  $currentDataHash{"Firing Function"} = $firingFunction;

  # 11 Mar 2005 : GWA : This is the filename.

  $fileName =~ s/\.out\.gz//;
  chomp($fileName);
  $currentDataHash{"Filename"} = $fileName;
  
  # 11 Mar 2005 : GWA : Hashing up some stuff.

  my $dirmd5line = `find $processDirectory/FitsUsed -type f | xargs cat | md5sum -`;
  my $hmd5commandLine = "md5sum $processDirectory/FitsMsg/" .  
                        $currentDataHash{"Unique Counter"} . ".h";
  my $hmd5line = `$hmd5commandLine`;
  my @dirmd5array = split(/\s/, $dirmd5line);
  my @hmd5array = split(/\s/, $hmd5line);
  $currentDataHash{"Source Hash"} = $dirmd5array[0];
  $currentDataHash{"Header Hash"} = $hmd5array[0];

  # 09 Jan 2005 : GWA : For now I'm not going to worry about supporting
  #               multiple ways of acquiring the following data (# motes,
  #               topology, FF constant, etc).  The right way to do this is
  #               probably to stick a header in the file, but right now it's
  #               in the file name of the data produced by doExperiment.pl
  #               and that's what I'm interested in processing.
  #
  # 11 Mar 2005 : GWA : This got fixed.

# 11 Mar 2005 : GWA : Don't need this.  I hope.

  if ($fileName !~ /(\d+)CONSTANT/) {
    print <<OOPS;
Problem with data file: could not determine FF constant.  Exiting.
OOPS
    exit(1);
  }
  $currentDataHash{"FF Constant"} = $1;

  if ($fileName !~ /(GRID|ALLTOALL|LINE|RING|MOTELAB|ML)/) {
    print <<OOPS;
Problem with data file: could not determine topology.  Exiting.
OOPS
    exit(1);
  }
  $currentDataHash{"Topology"} = $1;

  if ($fileNameHead eq "MOTELAB") {
    if ($fileName !~ /RECEIVER(\d+)/) {
      print <<OOPS;
Problem with data file: could not determine receiver.  Exiting.
OOPS
      exit(1);
    }
    $currentDataHash{"Receiver"} = $1;
  } else {
    $currentDataHash{"Receiver"} = 0;
  }

  # 09 Jan 2005 : GWA : Yuck, have to get experiment time.  We only have
  #               probably three in use so far, so... hmm, well, easier said
  #               than done I guess.  We'll try using the last sequence
  #               number and making the loose assumption that motes fire
  #               close to once a second.

  my $experimentTimeData = `zcat $currentFile | tail -n 1`;
  my @experimentTimeData = split(/\s+/, $experimentTimeData);
  $experimentTimeData = $experimentTimeData[1];
  chomp($experimentTimeData);

  my $experimentTime = sprintf("%d", $experimentTimeData / 60);

  # 09 Jan 2005 : GWA : Bump it up if we were close to the end of an
  #               interval.  This happens because of randomized mote startup.

  if (($experimentTimeData % 60) > 50) {
    $experimentTime++;
  }
  $currentDataHash{"Experiment Time"} = $experimentTime;

  # 09 Jan 2005 : GWA : We now should have all the info about the files to be
  #               processed in our array.  Finally.

if (0) {
  printf("%s %s %d %s %s %s %d %s %d\n",
         $currentDataHash{"Directory"},
         $currentDataHash{"Filename"},
         $currentDataHash{"# Nodes"},
         $currentDataHash{"MoteLab/TOSSIM"},
         $currentDataHash{"Topology Tag"},
         $currentDataHash{"Topology File"},
         $currentDataHash{"Experiment Time"},
         $currentDataHash{"Firing Function"},
         $currentDataHash{"FF Constant"});
}
  # 09 Jan 2005 : GWA : Clean out temporary directory, just in case.
  `rm -f $tempDir/*`;
  
  # 09 Jan 2005 : GWA : Copy over outfile.

  `cp $currentFile $tempDir/`;

  my $tempRootFile = "$tempDir/$fileNameRoot";
 
  # 10 Jan 2005 : GWA : Grabbing the number of motes from the filename
  #               doesn't work with MoteLab where receivers can here from
  #               multiple motes.

  my $numMotes = `zcat $tempRootFile | grep -o -P ^[0-9]+ | sort | uniq`;
  chomp($numMotes);
  my @numMotes = split(/\s/, $numMotes);
  $numMotes = scalar @numMotes;

  # 09 Jan 2005 : GWA : First thing to do is to run the event processing
  #               scripts.
  
  #`$FindBin::Bin/processEvents.pl $tempRootFile`;  
  `$FindBin::Bin/processEvents.pl $tempRootFile ALL`;  

  # 09 Jan 2005 : GWA : Use find to locate the outfiles.

  my $eventAllFile = `find $tempDir/ -name "*EVENT-ALL*"`;
  chomp($eventAllFile);
  my $eventFiles = `find $tempDir/ -name "*EVENT-MOTE*"`;
  chomp($eventFiles);
  my @eventMoteFiles = split(/\s+/, $eventFiles);

  # 09 Jan 2005 : GWA : Next, run our group processing script.

  `$FindBin::Bin/processGroups.pl $eventAllFile $processGroupsBucketSize`;
  
  # 09 Jan 2005 : GWA : Again, find to locate the outfiles.

  my $groupFile = `find $tempDir/ -name "*ALL-GROUPS*"`;
  chomp($groupFile);

  # 09 Jan 2005 : GWA : Processing complete, now the real fun begins.  First
  #               let's get the time to first sync since that's a extremely
  #               useful piece of data for what follows.

  my $evaluateSyncOutput = 
    `$FindBin::Bin/evaluateSynch.pl $groupFile $numMotes`;
  
  if ($evaluateSyncOutput =~ /\nSYNC\n/) {
    $evaluateSyncOutput =~ /\nTime to Sync : ([0-9\.]+)\n/;
    $currentDataHash{"Time to Sync"} = $1;
    $evaluateSyncOutput =~ /\nAfter Spread \(Av StdDev\) : ([0-9\.]+)\n/;
    $currentDataHash{"After Spread (Av StdDev)"} = $1;
    $evaluateSyncOutput =~ /\nAfter Spread \(Max\) : ([0-9\.]+)\n/;
    $currentDataHash{"After Spread (Max)"} = $1;
    $evaluateSyncOutput =~ /\nAfter Group Frequency : ([0-9\.]+)\n/;
    $currentDataHash{"After Group Frequency"} = $1;
    $evaluateSyncOutput =~ /\nAfter Spread 90 : ([0-9\.]+)\n/;
    $currentDataHash{"After Spread 90"} = $1;
    $evaluateSyncOutput =~ /\nAfter Spread 50 : ([0-9\.]+)\n/;
    $currentDataHash{"After Spread 50"} = $1;
  } elsif ($evaluateSyncOutput =~ /\nNOSYNC\n/) {
    $currentDataHash{"Time to Sync"} = 0;
    $currentDataHash{"After Spread (Av StdDev)"} = 0;
    $currentDataHash{"After Group Frequency"} = 0;
  } else {
    
    # 09 Jan 2005 : GWA : If we can't find the tag, we're in trouble.  Must
    #               be a problem with a script along the way.  Bail.

    print <<OOPS;
Could not find sync tag in output.  Exiting.
OOPS
    exit(1);
  }
  $evaluateSyncOutput =~ /\nLargest Group : ([0-9\.]+)\n/;
  $currentDataHash{"Largest Group"} = $1;

  # 09 Jan 2005 : GWA : Most of the data is in there, so I think that we're
  #               good at this point.  Time to clean up.

  `rm -f $tempDir/*`;

  # 09 Jan 2005 : GWA : Store our results in the array.
  #
  # 13 Mar 2005 : GWA : One of the world's worst ideas.
  
  foreach my $printKey (@keysInOrder) {
    print OUTPUT $currentDataHash{"$printKey"};
    print OUTPUT "\t";
  }
  print OUTPUT "\n";
  
  print STDERR "Done with file " . ($currentFileNumber + 1) . "\n";
  $currentFileNumber++;
}

# 09 Jan 2005 : GWA : Blow away the temporary directory.
`rm -rf $tempDir`;
exit();
