#!/usr/bin/perl -w

# FileName:    groupSpread.pl 
# Date:        December 30, 2004
#
# Description: Determines how spread out are the firing times of a bunch
# of motes in one group.

# Params: {begin,end,avg} for computing group fire time
# Input:  Output of processGroups.pl
# Output: stddev of group spread
#         group fire time

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
    die "Usage $0 infile outfile \[begin\|end\|avg\]\n"
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
  $outfile .= "GROUP-SPREAD.out";
}

open(OUTPUT, ">$outfile")
    or die "Unable to open output file $outfile ($!)";

##################
#                #
#  Write Header  #
#                #
##################
print OUTPUT <<DONE;
# GroupSpread $ARGV[0] -> $outfile
# firing time\tstandard deviation
DONE

##########################
#                        #
#  Compute Group Spread  #
#                        #
##########################

while ( my $line = <INPUT> ) {
    my ($fire_time, $deviation, @times, $num_times);

    chomp( $line );

    # skip comments
    if ( $line =~ /^\#/ ) {
        next;
    }

    # Compute group fire time
    @times = &times_from_group($line);

    if ( 0 == @times ) {
      next;
    }

    $fire_time = &group_fire_time(@times);

    # Compute the standard deviation of the firing times of the members of this group
    $num_times = @times;
    if ( 1 == $num_times ) {
      $deviation = 0;
    } else {
      $deviation = &stdev(@times);
    }

    # Print both for plot
    printf OUTPUT "$fire_time\t$deviation\n\n";
}

close INPUT;
close OUTPUT;
