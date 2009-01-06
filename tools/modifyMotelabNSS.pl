#!/usr/bin/perl

## Geetika Tewari
## Computes the average metric per number of lossy links
## For a fixed FFC and time and topology

######################################################
##                                                  ##
##                  PACKAGES                        ##
##                                                  ##
######################################################

use strict;
#use util;
use FindBin;
use File::Temp qw/ tempfile tempdir /;
#use Statistics::Basic::Mean;
#use Statistics::Basic::StdDev;

######################################################
##                                                  ##
##                  CONSTANTS                       ##
##                                                  ##
######################################################
use constant FROM_INDEX     => 0;
use constant TO_INDEX     => 1;
use constant LOSS_INDEX     => 2;

######################################################
##                                                  ##
##                GLOBAL VARIABLES                  ##
##                                                  ##
######################################################

if ((@ARGV < 1) ||
    (@ARGV > 4)) {
    print <<DONE;
Usage $0 <data file> <loss-tolerance>
DONE
exit(1);
}

my $inFile = $ARGV[0];
my $outFile = "motelab-final.nss";
my $lossTolerance = 1;
if(@ARGV == 2){
    $lossTolerance = $ARGV[1];
}


######################################################
##                                                  ##
##                   OPEN THE FILE                  ##
##                                                  ##
######################################################

open(INPUT,  "$inFile")
    or die "Unable to open $inFile ($!)";
print "Succesfully opened file $inFile... \n";
    
    
######################################################
##                                                  ##
##        Read in each FFC relevant values          ##
##                                                  ##
######################################################
    
my $lineNum = 0;
my @fromNSS;
my @toNSS;
my @lossNSS;
my $maxLines = 0;

while (my $line = <INPUT>) {
    chomp;
    if ($line =~ m{\#\D*}){
	print "Skipping line ... \n";
	next;
    }
    
    #print "Line is " . $line . "\n";
    my @fields1 = split /\s+/, $line;
    my @fields = split /:/, $fields1[0];

    # Store the FFConstant as is
    @fromNSS[$lineNum] = @fields[FROM_INDEX];
    @toNSS[$lineNum] = @fields[TO_INDEX];
    @lossNSS[$lineNum] = @fields[LOSS_INDEX];
    
    $lineNum++;
}
$maxLines = $lineNum;
close INPUT;
    

########################################################
##                                                    ##
##       PRINT OUT NEW MOTELAB TOPOLOGY FILE          ##
##                                                    ##
########################################################

open(OUTPUT, ">$outFile") or die "Can't open output file!\n";

for(my $j=0; $j<$maxLines; $j++){
    # TEMP hack to eliminate disconnected nodes:
    # Disconnected nodes are 8, 10, 14, 15, 17
    if($fromNSS[$j]+1 == 8 || $fromNSS[$j]+1 == 10 || $fromNSS[$j]+1 == 14 || $fromNSS[$j]+1 == 15 || $fromNSS[$j]+1 == 17){
	print OUTPUT "$fromNSS[$j]:$toNSS[$j]:0.000\n";
    }
    else{
	if($lossNSS[$j] <= $lossTolerance){
  	    print OUTPUT "$fromNSS[$j]:$toNSS[$j]:$lossNSS[$j]\n";
	    #my $from = $fromNSS[$j] + 1;
	    #my $to = $toNSS[$j] + 1;
	    #print OUTPUT "$from:$to:$lossNSS[$j]\n";
	}
	else{
	    print OUTPUT "$fromNSS[$j]:$toNSS[$j]:0.000\n";
	}
    }
}				
close OUTPUT;

