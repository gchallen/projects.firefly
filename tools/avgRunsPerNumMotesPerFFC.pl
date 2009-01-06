#!/usr/bin/perl

## Geetika Tewari
## Computes the average TTS, GS values
## over several runs
## for varying FFC, numMotes

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
use constant NUMMOTES_INDEX     => 2;
use constant TTS_INDEX     => 13;
use constant GS50_INDEX    => 16;
use constant GS90_INDEX    => 17;
use constant TOPOLOGY_FILE_INDEX    => 5;
use constant SYNCHED_TIME => 1500;

######################################################
##                                                  ##
##                GLOBAL VARIABLES                  ##
##                                                  ##
######################################################

my @keysInOrder = ("FF Constant", "Time To Sync", "Group Spread 50", "Group Spread 90", "Percent Synched", "Std. Dev");

## Store the TTS, and GS according to the FFC values
my @numMotes;
my @ffConstant;
my @ttsAllRuns;
my @gs50AllRuns;
my @gs90AllRuns;
my @topologyFile;
my @invalidFFCVals;
my $totalRuns;

## Metric averages over all runs for each firing func constant value
my @avgTTS;
my @avgGS50;
my @avgGS90;
my @headersPrinted;

print "This script has to be run from tools directory! \n";
print "Double check indices in result files for FFC: ". FFC_INDEX . " TTS: " . TTS_INDEX . " GS50: " . GS50_INDEX . " GS90: ". GS90_INDEX . " \n";

if ((@ARGV < 2) ||
    (@ARGV > 4)) {
    print <<DONE;
Usage computeAverageMetrics.pl <data directory> <TTS(0) GS-50th(1) GS-90th(2)> [<optional>]
Name of the input file matters a lot!
DONE
exit(1);
}

my $processDirectory = $ARGV[0];
my $metricChoice = $ARGV[1];
my $dataFiles = "result.txt";
my $outputFile = "motes";
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
	print "fileShortName: $fileShortName \n";

	#if ($line !~/$fileShortName/) {
	if ($line =~ m{Directory\D*}){
	    #$lineNum++;
	    print "Skipping line ... $line \n";
	    next;
	}

	#print "Line is " . $line . "\n";
	my @fields = split /\s+/, $line;
       	#print "Processing.... \n";

	# Store the FFConstant as is
	@ffConstant[$lineNum] = @fields[FFC_INDEX];
	@topologyFile[$lineNum] = @fields[TOPOLOGY_FILE_INDEX];
	@numMotes[$lineNum] = @fields[NUMMOTES_INDEX];

	# Store the TTS for each FFC value
	# If the system synchronized
	if(@fields[TTS_INDEX] != 0 && @fields[GS50_INDEX] != 0 && @fields[GS90_INDEX] != 0){
	    if(@fields[TTS_INDEX] < SYNCHED_TIME){
		@tts[$lineNum] = @fields[TTS_INDEX];
		@gs50[$lineNum] = @fields[GS50_INDEX];
		@gs90[$lineNum] = @fields[GS90_INDEX];
		print "Got: numM:@numMotes[$lineNum], ffc:" . $ffConstant[$lineNum] . " " . $tts[$lineNum] . " " . $gs50[$lineNum] . " " . $gs90[$lineNum] . "\n"; 
	    }
	}
	else{
	    print "I found tts/gs values eq to 0, numM:@numMotes[$lineNum], ffc: " . $ffConstant[$lineNum] . " " . $fields[TTS_INDEX] . " " . $fields[GS50_INDEX] . " " . $fields[GS90_INDEX] . "\n"; 
	}
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

print "Averaged over $currentFileNumber runs \n";
$totalRuns = $currentFileNumber;


########################################################
##                                                    ##
##            PRINT THE AVERAGES                      ##
##                                                    ##
########################################################

my ($avg, $stdVals, $ffcVals, $topoTags, $motes);
if($metricChoice == 0){
    ($avg, $stdVals, $ffcVals, $topoTags, $motes) = &computeStats(@ttsAllRuns);
}
elsif($metricChoice == 1){
    ($avg, $stdVals, $ffcVals, $topoTags, $motes) = &computeStats(@gs50AllRuns);
}
elsif($metricChoice == 2){
    ($avg, $stdVals, $ffcVals, $topoTags, $motes) = &computeStats(@gs90AllRuns);
}
elsif($metricChoice == 3){
    ($avg, $stdVals, $ffcVals, $topoTags, $motes) = &computePercentSynched(@ttsAllRuns);
}

#print " ----- PRINTING AVGS -------- \n";
#print "Returned @$avg \n";
#print "Returned @$ffcVals \n";

## Note: in loop below you can either print FFC constant or
## just the counter value k or the Topo file 

print "INVALID VALS -----------------------------------------------------------------\n";
foreach my $invalidVal (@invalidFFCVals){
    print " " . $invalidVal;
}
print " \n";

my $k = 0;
my $moteID;
foreach my $ffcVal (@$ffcVals) {
    #print OUTPUT "@$topoTags[$k]\t@$avg[$k]\t@$stdVals[$k]\n";
    #print OUTPUT "$ffcVal\t@$topoTags[$k]\t@$avg[$k]\t@$stdVals[$k]\n";
    #print OUTPUT "$k\t@$avg[$k]\t@$stdVals[$k]\n";
    $moteID = @$motes[$k];
    print "moteID: " . $moteID . "\n";
    if(@headersPrinted[$moteID] ne 1){
	&printHeader($moteID, $keysInOrder[$metricChoice+1]);
	@headersPrinted[$moteID] = 1;
    }
    open(OUTPUT2, ">>$outputFile-@$motes[$k].txt") or die "Can't open output file!\n";    
    if($ffcVal == 70 || $ffcVal == 100 || $ffcVal == 500 || $ffcVal == 750 || $ffcVal == 1000){
	if($metricChoice == 3){
	    print OUTPUT2 "$ffcVal\t@$avg[$k]\t@$stdVals[$k]\n";
	    ##print OUTPUT2 "$ffcVal\t@$avg[$k]\n";
	}
	else{
	    print OUTPUT2 "$ffcVal\t@$avg[$k]\t@$stdVals[$k]\n";
	}
    }
    close OUTPUT2;
    
    #my $invalidVal = "0"; ##&isInValid($ffcVal);
    #if($invalidVal eq "0"){
    #	if(@headersPrinted[$moteID] ne 1){
	#    &printHeader($moteID, $keysInOrder[$metricChoice+1]);
	#    @headersPrinted[$moteID] = 1;
	#}
	#open(OUTPUT2, ">>$outputFile-@$motes[$k].txt") or die "Can't open output file!\n";    
	#print OUTPUT2 "$ffcVal\t@$avg[$k]\t@$stdVals[$k]\n";
	#close OUTPUT2;
    #}
    #else{
	##print $ffcVal . " value is invalid \n";
    #    }
    $k++;
}				


########################################################
##                                                    ##
##                 SUBROUTINES                        ##
##                                                    ##
########################################################

sub printHeader {
    my ($moteID, $tag)  = @_;
    open(OUTPUT, ">$outputFile-$moteID.txt") or die "Can't open output file!\n";    
    print OUTPUT "#";
    print OUTPUT "$keysInOrder[0]\t";
    print OUTPUT "$tag\t";
    if($metricChoice != 3){
	print OUTPUT "$keysInOrder[5]\t";
    }
    print OUTPUT "\n";
    close OUTPUT;
}


sub isInValid {
    my ($currentVal) = @_;
    #print $currentVal . "  \n";
    foreach my $invalidVal (@invalidFFCVals){
	if($currentVal eq $invalidVal){
	    ##print "Returning true ... \n";
	    return 1;
	}
    } 
    return 0;
}


sub computeStats {
    my $j;
    my $k;
    my @myList;
    my @avgArray;
    my @stdDevArray;
    my @ffcVals;
    my @finalNumMotes;
    my @topoTags;
    my @dataArray = @_; ## Arguments to this function Either alTTS, allGS{50/90}

    # For all FFC values
    for ($j=0; $j<=$#{$dataArray[0]}; $j++) {
	my @tmp = ();

	# For all runs
	for ($k=0; $k<=$#dataArray; $k++) {
	    #print $dataArray[$k][$j] . " ";
	    if($dataArray[$k][$j] != 0){
		push @tmp, $dataArray[$k][$j];
	    }
	}
	print "For loss/ffc=$j, averaging over " . ($#tmp+1) . " values: @tmp ; AVG = ";
	if($#tmp ge 0){
	    print average(@tmp);
	    push @avgArray, average(@tmp);
	    print "  StdDev: ";
	    if($#tmp ge 1) {
		push @stdDevArray, stdev(@tmp);  ## using my hand written routine in util.pm
	                                     ## Checked against matlab - correct output
		print  stdev(@tmp) . " \n";
	    }
	    else{
		push @stdDevArray, 0; 
		print "0 \n";
	    }
	    push @finalNumMotes, $numMotes[$j];
	    push @ffcVals, $ffConstant[$j]; 
	    push @topoTags, $topologyFile[$j];
	} 
        else{
	    push @invalidFFCVals, $ffConstant[$j];
	    print "Invalid FFC $ffConstant[$j] -------------------------------------- \n";
	}
	print "\n";
    }

    ## Do post processing to be consistent in only printing
    ## FFC values that have valid (i.e. convergence) entries for all mote numbers.

    
    $myList[0] = \@avgArray;
    $myList[1] = \@stdDevArray;
    $myList[2] = \@ffcVals;
    $myList[3] = \@topoTags;
    $myList[4] = \@finalNumMotes;
    return @myList; ##(@avgArray, @ffcVals);
}


sub computePercentSynched {
    my $j;
    my $k;
    my @myList;
    my @avgArray;
    my @stdDevArray;
    my @ffcVals;
    my @finalNumMotes;
    my @percentSynchedVals;
    my @topoTags;
    my $percentSynched;
    my @dataArray = @_; ## Arguments to this function Either alTTS, allGS{50/90}

    # For all FFC values
    for ($j=0; $j<=$#{$dataArray[0]}; $j++) {
	my @tmp = ();

	# For all runs
	for ($k=0; $k<=$#dataArray; $k++) {
	    #print $dataArray[$k][$j] . " ";
	    if($dataArray[$k][$j] != 0){
		push @tmp, $dataArray[$k][$j];
	    }
	}
	print "For loss/ffc=$j, averaging over " . ($#tmp+1) . " values: @tmp ; AVG = ";
	if($#tmp ge 0){
	    $percentSynched = (($#tmp+1) / $totalRuns) * 100;
	} 
        else{
	    $percentSynched = 0;
	    push @invalidFFCVals, $ffConstant[$j];
	    print "Invalid FFC $ffConstant[$j] -------------------------------------- \n";
	}
	push @stdDevArray, 0; 
	push @percentSynchedVals, $percentSynched;
	push @finalNumMotes, $numMotes[$j];
	push @ffcVals, $ffConstant[$j]; 
	push @topoTags, $topologyFile[$j];
	print "\n";
    }

    $myList[0] = \@percentSynchedVals;
    $myList[1] = \@stdDevArray;
    $myList[2] = \@ffcVals;
    $myList[3] = \@topoTags;
    $myList[4] = \@finalNumMotes;
    return @myList; 
}

exit();
