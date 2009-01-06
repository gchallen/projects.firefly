#!/usr/bin/perl -w

# FileName:    groupPeriod.pl 
# Date:        December 30, 2004
#
# Description: Determines the period in which a group fires

# Params: {begin,end,avg} for computing group fire time
# Input:  Output of processGroups.pl
# Output: Group period, Group Times (time at which they fire) to be plotted.

use FindBin;
use lib $FindBin::Bin;

use strict;
use util;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 2 > @ARGV ) {
    die "Usage $0 infile outfile threshold grouping\n"
      . "  infile   output of processGroups.pl\n"
      . "  outfile  where to put the output\n"
      . "  grouping begin, end or average\n"
      . "      how to compute the group firing time\n";
}

my $grouping = "avg";

if ( 2 < @ARGV ) {
    $grouping = $ARGV[2];
}

#######################
#                     #
#  Open file handles  #
#                     #
#######################
open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";

my $outfile = $ARGV[1];
if ( $outfile =~ /auto/i ) {
  $outfile = $ARGV[0];
  $outfile =~ s/\.out//;
  $outfile =~ s/EVENT-ALL-GROUPS//;
  $outfile .= "GROUP-PERIOD.out";
}

open(OUTPUT, ">$outfile")
    or die "Unable to open output file $outfile ($!)";

##################
#                #
#  Write Header  #
#                #
##################

print OUTPUT <<DONE;
# GroupPeriod $ARGV[0] -> $outfile
# firing time\tperiod
DONE

##########################
#                        #
#  Compute Group Period  #
#                        #
##########################

my $first_iter = 1;
my $prev_firing_time;

while ( my $line = <INPUT> ) {
    my ($firing_time, $period, @times);

    chomp( $line );

    # skip comments
    if ( $line =~ /^\#/ ) {
        next;
    }

    # Compute when group fires (group fire time)
    @times = &times_from_group($line);

    if ( 0 == @times ) {
      next;
    }

    $firing_time = &group_fire_time(@times);

    if ( $first_iter ) {
        $first_iter = 0;
        $prev_firing_time = $firing_time;
        next;
    }

    # Compute the period between firings
    $period = $firing_time - $prev_firing_time;
    $prev_firing_time = $firing_time;

    # Print both for plot
    printf OUTPUT "$firing_time\t$period\n\n";
}

close INPUT;
close OUTPUT;
