#!/usr/bin/perl -w

# FileName:    groupSize.pl
# Date:        January 5, '05
#
# Description: Determines how many motes are in each group

# Params: {begin,end,avg} for computing group fire time
# Input:  Output of processGroups.pl
# Output: group fire time
#         group size

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
  $outfile .= "GROUP-SIZE.out";
}

open(OUTPUT, ">$outfile")
    or die "Unable to open output file $outfile ($!)";

##################
#                #
#  Write Header  #
#                #
##################
print OUTPUT <<DONE;
# GroupSize: $ARGV[0] -> $outfile
# firing time\tgroup size
DONE

##########################
#                        #
#  Compute Group Spread  #
#                        #
##########################

while ( my $line = <INPUT> ) {
    my ($fire_time, @times, $num_times, @motes, $num_motes );

    chomp( $line );

    # skip comments
    if ( $line =~ /^\#/ ) {
        next;
    }

    @motes = &motes_from_group($line);
    @times = &times_from_group($line);

    if ( 0 == @times ) {
      next;
    }

    #
    # uniquify motes
    #

    my %hsh;
    undef @hsh{@motes};
    @motes = keys %hsh;

    $num_motes = @motes;

    # Compute group fire time
    $fire_time = &group_fire_time(@times);
    $num_times = @times;

    # Print both for plot
    printf OUTPUT "$fire_time\t$num_motes\n";
}

close INPUT;
close OUTPUT;
