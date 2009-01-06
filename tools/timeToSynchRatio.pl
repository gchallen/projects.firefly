#!/usr/bin/perl -w

# FileName:    timeToSynchRatio.pl
# Date:        December 30, 2004
#
# Description: Determines the time taken to achieve synchronization
# Can work for multiple groups or a group of 2 nodes
#

# Params: % in window to consider synched, {begin, end, avg} for computing group time
# Input:  Output of processGroups.pl
# Output: Time (taken to attain synchronization)

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
      . "  infile    output of processGroups.pl\n"
      . "  outfile   where to put the output\n"
      . "  threshold we're synchronized when this fraction of motes are in one group\n"
      . "  window      how long do they have to stabilize for (in entry numbers)\n"
      . "  grouping  begin, end or average\n"
      . "      how to compute the group firing time\n";

}

my $threshold = 1;
my $window      = 1;
my $grouping = "avg";

if ( 2 < @ARGV ) {
    $threshold = $ARGV[2];
}

if ( 3 < @ARGV ) {
  $window = $ARGV[3];
}

if ( 4 < @ARGV ) {
    $grouping = $ARGV[4];
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
  $outfile .= "SYNC.out";
}

open(OUTPUT, ">$outfile")
    or die "Unable to open output file $outfile ($!)";

###########################
#                         #
#  Compute time to synch  #
#                         #
###########################

my $all_file  = $ARGV[0];
$all_file =~ s/EVENT-ALL-GROUPS/EVENT-ALL/;

my $num_motes = unique_motes($all_file);
print OUTPUT "# Processing $ARGV[0] -> $outfile\n";
print OUTPUT "# motes\t$num_motes\n";
print OUTPUT "# time to synchronization\n";

my $line_num = 0;
my $streak   = 0;

while ( my $line = <INPUT> ) {
    my ($time_to_synch, @times);

    $line_num++;

    chomp( $line );

    # skip comments
    if ( $line =~ /^\#/ ) {
        next;
    }

    # compute number of motes in group
    @times = &times_from_group($line);

    # Does the number of motes in this group exceed the threshold?
    if ( (@times / $num_motes) >= $threshold ) {
      $streak++;
    } else {
      $streak = 0;
    }

    if ( $streak >= $window ) {
        $time_to_synch = &group_fire_time($grouping,@times);
        print OUTPUT "# synch on fire number\t$line_num\n";
	printf OUTPUT "$time_to_synch\n";
        exit;
    }
}

# Never attained synchronization
printf OUTPUT "# Never attained synchronization\n";
printf OUTPUT "0\n\n";

close INPUT;
close OUTPUT;
