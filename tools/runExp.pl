#!/usr/bin/perl

# Runs each row of the base matrix
# Datadir FFConstant TopologyFile NumMotes Time TopologyTag RandomSeed Makefile ProcessDelay SendDelay IgnorePeriod (ExtraTag)
# 11-Mar-2005-GWA 10      -       2       3600    ALLTOALL        350     packetMakefile  250     25      10

use strict;

my $k;
my $ffc;
my $min = 3600;  ## Run it for 30 minutes
my @ffcVal=(10, 20, 50, 70, 100, 150, 300, 500, 750, 1000);
my $topology="ALL-TO-ALL";
my $randomSeed = 350;
my $numMotes=2;
my $dateStr = "20-Mar";

############################
#                          #
# Process Input parameters #
#                          #
############################

if ( 3 > @ARGV ) {
    die "Usage $0 numMotes time randomSeed (topology) \n";
}
#print "Size of argv: @ARGV \n";


if( 2 < @ARGV ){
    $numMotes = $ARGV[0];
    $min = $ARGV[1];
    $randomSeed = $ARGV[2];
    
    if( 3 < @ARGV ){
	$topology = $ARGV[3];
    }
}

############################
#                          #
# Print Output String      #
#                          #
############################



for ($k= 0; $k <= ($#ffcVal); $k++){
    $ffc = $ffcVal[$k];
    
    my $commandString = "$dateStr-2005-GT $ffc \t- \t$numMotes \t$min \t$topology \t$randomSeed \tpacketMakefile  250     25      10\n";
    print $commandString;	
    
}



