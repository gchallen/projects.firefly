#!/usr/bin/perl

# Runs each row of the base matrix
# Datadir FFConstant TopologyFile NumMotes Time TopologyTag RandomSeed Makefile ProcessDelay SendDelay IgnorePeriod (ExtraTag)
# 11-Mar-2005-GWA 10      -       2       3600    ALLTOALL        350     packetMakefile  250     25      10

use strict;

my $k;
my $ffc;
my $fixedffc=0;
my $numExp = 10;
my $min = 3600;  ## Run it for 30 minutes
my $runNumber="1";
my @ffcVal=(10, 20, 50, 70, 100, 150, 300, 500, 750, 1000);
my $topology="ALLTOALL";
my $topologyFile="-";
my $randomSeed = 350;
my $numMotes=2;
my $dateStr = "7-Jul-Drift-ATA";
my $driftFile="";
my $extraTag;

############################
#                          #
# Process Input parameters #
#                          #
############################

if ( 3 > @ARGV ) {
    print "Usage $0 numMotes time randomSeed <run Number> <topology> <topologyFile> <Fixed FFC val> <number of expts> \n";
    die "Eg. /createExpFile-FixedFFC.pl 16 3600 10 1 - - 500 10 18-Aug-ATA \n";
}
########print "Size of argv: $#ARGV \n";


if( 2 < @ARGV ){
    $numMotes = $ARGV[0];
    $min = $ARGV[1];
    $randomSeed = $ARGV[2];
    
    if( 3 < @ARGV ){
	$runNumber = $ARGV[3];
    }

    if( 4 < @ARGV ){
	if($ARGV[4] ne "-"){
	    $topology = $ARGV[4];
	}
    }

    if( 5 < @ARGV ){
	if($ARGV[5] ne "-"){
	    $topologyFile = $ARGV[5];
	}
    }

    ## Fixed FFC
    if( 6 < @ARGV ){
	$fixedffc = $ARGV[6];
    }

    ## Number of experiments (default is 10)
    if( 7 < @ARGV ){
	$numExp = $ARGV[7];
    }

    ## Date / File name Tag
    if( 8 < @ARGV ){
	if($ARGV[8] ne "-"){
	    $dateStr = $ARGV[8];
	}
    }

}

############################
#                          #
# Print Output String      #
#                          #
############################

## Keep the FFC fixed and do 10 runs
for ($k=0; $k<$numExp; $k++){
    my $commandString = "$dateStr-$runNumber\t$fixedffc\t$topologyFile\t$numMotes\t$min\t$topology\t$randomSeed\tpacketMakefile\t250\t25\t10\n";
    print $commandString;	
}

