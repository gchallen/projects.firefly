#!/usr/bin/perl -w

# FileName:    nodePeriod.pl 
# Date:        December 30, 2004
#
# Description: Determines the periods between which this node is firing
# over time.

# Input:  Output of processEvents.pl scripts
# Output: Periods between fires over time

use FindBin;
use lib $FindBin::Bin;

use strict;
use util;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 2 != @ARGV ) {
    die "Usage $0 infile outfile\n"
        . " infile  the output from processEvents.pl for one mote\n"
        . " outfile where to put the output\n";
}

#######################
#                     #
#  Open file handles  #
#                     #
#######################
open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";

my ($mote) = ($ARGV[0] =~ /.*-EVENT-MOTE(\d*)\.out/);

my $outfile = $ARGV[1];
if ( $outfile =~ /auto/i ) {
  $outfile = $ARGV[0];
  $outfile =~ s/\.out//;
  $outfile =~ s/EVENT-MOTE\d*//;
  $outfile .= "PERIOD-MOTE$mote.out";
}

open(OUTPUT, ">$outfile")
    or die "Unable to open output file $outfile ($!)";

##################
#                #
#  Write Header  #
#                #
##################

print OUTPUT "# mote $mote\n";
print OUTPUT "# firing time\tperiod\tskipped\n";

#########################
#                       #
#  Compute node Period  #
#                       #
#########################

my ($prev_fire, $prev_seqno);

while ( my $line = <INPUT> ) {
    my (@entry, $fire, $seqno, $period, $skipped);

    chomp( $line );

    # skip comments
    if ( $line =~ /^\#/ ) {
        print "skipping line $line";
        next;
    }

    @entry = split(/\t/,$line);

    ($seqno, $fire) = @entry[0,1];

    if ( not defined $prev_fire ) {
        $prev_fire  = $fire;
        $prev_seqno = $seqno;
        next;
    }

    # Compute period between fire times

    $period = $fire - $prev_fire;

    if ( $seqno - 1 == $prev_seqno ) {
        $skipped = "";
    } else {
        $skipped = "SKIPPED";
    }

    $prev_fire  = $fire;
    $prev_seqno = $seqno;

    # Print period, time
    printf OUTPUT "$fire:$period:$skipped\n";
}

close INPUT;
close OUTPUT;
