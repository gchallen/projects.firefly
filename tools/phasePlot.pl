#!/usr/bin/perl

## Geetika Tewari
## Takes in a raw data file and computes the phase plot
## of all the motes of in the data and allows the user to
## plot that
##
## Phase is defined as the sent time mod the period
##
## To visualize:
## plot "node-phase-1.txt" using 1:2, "node-phase-2.txt" using 1:2, "node-phase-3.txt" using 1:2; set xrange[1:20]
## gnuplot> replot
##

######################################################
##                                                  ##
##                  PACKAGES                        ##
##                                                  ##
######################################################

use strict;
use util;
use FindBin;
use File::Temp qw/ tempfile tempdir /;
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib $FindBin::Bin;

######################################################
##                                                  ##
##                  CONSTANTS                       ##
##                                                  ##
######################################################

# A note about indices: they start from 0, hence for instance
# FFC_INDEX is the 10th label, but you can access in the string
# array at position 9, since array indices start from 0.
use constant MOTEID_INDEX     => 0;
use constant SENTTIME_INDEX   => 2;
use constant MODULOTIME_INDEX => 3;
use constant PERIOD           => 1000000;

######################################################
##                                                  ##
##                GLOBAL VARIABLES                  ##
##                                                  ##
######################################################

my @keysInOrder = ("Sent Time", "Phase (SentTime mod Period)" );
my $rawDataFile = $ARGV[0];
my @rawDataFile;
my $outputFile = "node-phase";
my $numMotes;
my @dataArray;
my @myarr;
my $maxMoteID;


print "This script has to be run from tools directory! \n";
print "Double check indices in result files for Motes: ". MOTEID_INDEX . " SENTTIME: " . SENTTIME_INDEX . " \n";

if ((@ARGV < 1) ||
    (@ARGV > 2)) {
    print <<DONE;
First: ./processEvents <dataFile> ALL
(This generates outputFile)
Usage $0 outputFile
DONE
exit(1);
}

##print "hello: " . $rawDataFile . "\n";

if ($rawDataFile =~ /gz$/) {
    $numMotes = `zcat $rawDataFile | grep -o -P ^[0-9]+ | sort -n | uniq`;
} else {
    $numMotes = `grep -o -P ^[0-9]+ $rawDataFile | sort -n | uniq`;
}

@myarr = split(/\s/, $numMotes);
print "Mote IDs: \n";
print $numMotes;
$maxMoteID = ($#myarr);
##print "max: " . $maxMoteID . "\n";
$|++; 

if ($rawDataFile =~ /gz$/) {
    $rawDataFile = `zcat $rawDataFile`;
    @rawDataFile = split("\n", $rawDataFile);
    if (@rawDataFile < 20) {
print <<OOPS;
Problem with data file: shorter than 20 lines! This is probably a problem. Exiting.
OOPS
exit(1);
    }
    open(INPUT, "zcat $ARGV[0]|");
}
else{
    ####print "hello \n";
    open(INPUT, "$rawDataFile");
}

######################################################
##                                                  ##
##        Read in each FFC relevant values          ##
##                                                  ##
######################################################

my $lineNum = 0;
my $moteID;
my $sentTime;
my $moduloTime;
my @openedFiles;
my $j;

for($j=0; $j<=$maxMoteID; $j++){
    @openedFiles[$j] = 0;
}

#foreach my $line (@rawDataFile) {    
while(my $line = <INPUT>) {
    chomp;
    if ($line =~ /^\#/) {
	$lineNum++;
	#print "Skipping line ... \n";
	next;
    }
    
    #print "Line is " . $line . "\n";
    my @fields = split /\s+/, $line;
    
    $moteID = @fields[MOTEID_INDEX];
    $sentTime = @fields[SENTTIME_INDEX];
    $moduloTime = @fields[MODULOTIME_INDEX];
    ##print "Read moteID: " . $moteID . " sentTime: " . $sentTime . " modTime: " . $moduloTime . " \n";

    if(@openedFiles[$moteID] == 0){
	open(OUTPUT, ">>$outputFile-$moteID.txt") or die "Can't open output file!\n";    
    }
    print OUTPUT "$sentTime\t$moduloTime\n";  
    $lineNum++;
    
    #if($lineNum > 20) { 
    #exit();
    #}
}


close INPUT;

for($j=0; $j<=$maxMoteID; $j++){
    close OUTPUT-$j; 
}



exit();
