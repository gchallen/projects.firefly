#!/usr/bin/perl

## Geetika Tewari
## Aug 24, 2005
## 1. Computes the average metric (either TTS or GS) over multiple runs
## 2. This code is written for the lossy link experiments.
## 3. FFC should be constant for these experiments


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

######################################################
##                                                  ##
##                  CONSTANTS                       ##
##                                                  ##
######################################################

# A note about indices: they start from 0, hence for instance
# FFC_INDEX is the 10th label, but you can access in the string
# array at position 9, since array indices start from 0.
use constant FFC_INDEX     => 9;
use constant TTS_INDEX     => 13;
use constant GS50_INDEX    => 16;
use constant GS90_INDEX    => 17;
use constant TOPOLOGY_FILE_INDEX    => 5;
use constant SYNCHED_TIME  => 1500;   ## An upper limit on the synched time

######################################################
##                                                  ##
##                GLOBAL VARIABLES                  ##
##                                                  ##
######################################################

my @keysInOrder = ("FF Constant", "Time To Sync", "Group Spread 50", "Group Spread 90", "Std. Dev", "Topology");

## Store the TTS, and GS according to the FFC values
my @ffConstant;
my @ttsAllRuns;
my @gs50AllRuns;
my @gs90AllRuns;
my @topologyFile;

## Metric averages over all runs for each firing func constant value
my @avgTTS;
my @avgGS50;
my @avgGS90;

print "This script has to be run from tools directory! \n";
print "Double check indices in result files for FFC: ". FFC_INDEX . " TTS: " . TTS_INDEX . " GS50: " . GS50_INDEX . " GS90: ". GS90_INDEX . " \n";

if ((@ARGV < 3) ||
    (@ARGV > 4)) {
    print <<DONE;
Usage $0 <data directory> <TTS(0) GS-50th(1) GS-90th(2)> <print FFC(f) or print Topology Tag(t)>
DONE
exit(1);
}

my $processDirectory = $ARGV[0];
my $metricChoice = $ARGV[1];
my $printChoice = $ARGV[2];
my $dataFiles = "result.txt";
my @dataArray;

# 09 Jan 2005 : GWA : First thing to do is find files to process.
my $processFiles = `find $processDirectory -type f -name "*.txt"`;
my @processFiles = split("\n", $processFiles);
my $numFiles = $#processFiles;

print STDERR ($numFiles + 1) .  " files to process.\n";

######################################################
##                                                  ##
##               GO OVER EACH FILE                  ##
##   Each file is a separate run of the experiment  ##
##   Count values over all runs and average         ##
##                                                  ##
######################################################

# Step through the array, processing as we go.
my $currentFile;
my $currentFileNumber = 0;

foreach my $currentFile (@processFiles) {

    print "Processing  $currentFile \n";

    # CurrentFile contains directory name appended to front- need to remove it!
    
    my @fileNameMunge = split("/", $currentFile);
    my %currentDataHash;
    
    # Filename should be last part, directory name before
    # it.  We need at least that much of the path, so if we don't
    # get it we have to bail.
    
    my $fileName = $fileNameMunge[@fileNameMunge - 1];
    $currentDataHash{"Directory"} = $fileNameMunge[@fileNameMunge - 2];
    my $fileNameRoot = $fileName;
    
    open(INPUT,  "$currentFile")
	or die "Unable to open $currentFile ($!)";
    print "Succesfully opened file $currentFile... \n";
    
    
    ######################################################
    ##                                                  ##
    ##        Read in each FFC relevant values          ##
    ##                                                  ##
    ######################################################
    
    my $lineNum = 0;
    my @tts;
    my @gs50;
    my @gs90;

    while (my $line = <INPUT>) {
	
	chomp;
	my $where = rindex($fileName, ".");
	my $fileShortName = substr($fileName,0, $where);
	##print $fileShortName;

	#if ($line !~/$fileShortName/) {
	if ($line =~ m{Directory\D*}){
	    $lineNum++;
	    #print "Skipping line ... \n";
	    next;
	}

	#print "Line is " . $line . "\n";
	my @fields = split /\s+/, $line;
       	#print "Processing.... \n";

	# Store the FFConstant as is
	@ffConstant[$lineNum] = @fields[FFC_INDEX];
	@topologyFile[$lineNum] = @fields[TOPOLOGY_FILE_INDEX];

	# Store the TTS for each FFC value
	@tts[$lineNum] = @fields[TTS_INDEX];
	@gs50[$lineNum] = @fields[GS50_INDEX];
	@gs90[$lineNum] = @fields[GS90_INDEX];
	#print "Got: FFC:" . $ffConstant[$lineNum] . " topology: " . $topologyFile[$lineNum] . " " . $tts[$lineNum] . " " . $gs50[$lineNum] . " " . $gs90[$lineNum] . "\n"; 

	$lineNum++;
    }
    
    ## Store this Run's TTS values for all the FFCs
    $ttsAllRuns[$currentFileNumber] = \@tts;
    $gs50AllRuns[$currentFileNumber] = \@gs50;
    $gs90AllRuns[$currentFileNumber] = \@gs90;

    ## Move to the next file, and close this file
    $currentFileNumber++;
    close INPUT;
} #end loop over each file




## Begin Debug stuff

# &printDebug(@ttsAllRuns);
# exit();

## End Debug stuff

##



######################################################
##                                                    ##
##            PRINT THE AVERAGES                      ##
##                                                    ##
########################################################

open(OUTPUT, ">$dataFiles") or die "Can't open output file!\n";

my ($avg, $stdVals, $ffcVals, $topoTags);

print OUTPUT "#";
if($printChoice eq "f"){
    print OUTPUT "$keysInOrder[0]\t";
}
elsif($printChoice eq "t"){
    print OUTPUT "$keysInOrder[5]\t";
}

if($metricChoice == 0){
    print OUTPUT "$keysInOrder[1]\t";
    ($avg, $stdVals, $ffcVals, $topoTags) = &computeStats(\@ttsAllRuns, \@ttsAllRuns);
}
elsif($metricChoice == 1){
    print OUTPUT "$keysInOrder[2]\t";
    ($avg, $stdVals, $ffcVals, $topoTags) = &computeStats(\@gs50AllRuns, \@ttsAllRuns);
}
else{
    print OUTPUT "$keysInOrder[3]\t";
    ($avg, $stdVals, $ffcVals, $topoTags) = &computeStats(\@gs90AllRuns, \@ttsAllRuns);
}
print OUTPUT "$keysInOrder[4]\t";
print OUTPUT "\n";

#print " ----- PRINTING AVGS -------- \n";
#print "Returned @$avg \n";
#print "Returned @$ffcVals \n";

## Note: in loop below you can either print FFC constant or
## just the counter value k or the Topo file 

my $k = 0;
foreach my $ffcVal (@$ffcVals) {
    #print OUTPUT "$k\t@$avg[$k] \n";
    #print OUTPUT "@$topoTags[$k]\t@$avg[$k] \n";
    #print OUTPUT "@$topoTags[$k]\t@$avg[$k]\t@$stdVals[$k]\n";
    if($printChoice eq "f"){
	print OUTPUT "$ffcVal\t@$avg[$k]\t@$stdVals[$k]\n";
    }
    elsif($printChoice eq "t"){
	print OUTPUT "@$topoTags[$k]\t@$avg[$k]\t@$stdVals[$k]\n";
    }
    $k++;
}				
close OUTPUT;

########################################################
##                                                    ##
##                 SUBROUTINES                        ##
##                                                    ##
########################################################

sub printDebug {
    my @dataArray = @_;
    my $j;
    my $k;

    print "\n\n\n\n";
    print "Start printDebug -------------------------***********************-------------------------------- \n";
    # For all FFC values
    for ($j=0; $j<=($#{$dataArray[0]}); $j++) {
	my @tmp = ();
	
	print "For FFC: $ffConstant[$j] and Topology: $topologyFile[$j]:  \n";
	
	# For all runs
	for ($k=0; $k<=($#dataArray); $k++) {
	    print $dataArray[$k][$j] . " ";
	}
	print "\n";
    }
    print "End printDebug -------------------------***********************-------------------------------- \n";
}


sub computeStats {
    my $j;
    my $k;
    my @myList;
    my @avgArray;
    my @stdDevArray;
    my @ffcVals;
    my @topoTags;
    my (@dataArray) = @{$_[0]};
    my (@ttsArray)  = @{$_[1]};

    # For all FFC values
    for ($j=0; $j<= ($#{$dataArray[0]}) + 1; $j++) {
	my @tmp = ();

	# For all runs
	for ($k=0; $k<= ($#dataArray); $k++) {
	    #print $dataArray[$k][$j] . " ";
	    if($dataArray[$k][$j] != 0  & $ttsArray[$k][$j] < SYNCHED_TIME){
		push @tmp, $dataArray[$k][$j];
	    }
	}

	print "For loss/ffc=$topologyFile[$j], averaging over " . ($#tmp+1) . " values: @tmp ; AVG = ";
	if($#tmp ge 0){
	    print average(@tmp);
	    push @avgArray, average(@tmp);
	    if($#tmp ge 1){
		push @stdDevArray, stdev(@tmp);  ## using my hand written routine in util.pm
		                                 ## Checked against matlab - correct output
	    }else{
		push @stdDevArray, 0;
	    }
	    push @ffcVals, $ffConstant[$j]; 
	    push @topoTags, $topologyFile[$j];
	} 
	print "\n";
    }
    
    $myList[0] = \@avgArray;
    $myList[1] = \@stdDevArray;
    $myList[2] = \@ffcVals;
    $myList[3] = \@topoTags;
    return @myList; ##(@avgArray, @ffcVals);
}

exit();
