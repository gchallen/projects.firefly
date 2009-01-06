#!/usr/bin/perl -w

# FileName:    timeToSynch.pl 
# Date:        December 30, 2004
#
# Description: Determines the time taken to achieve synchronization
# Can work for multiple groups or a group of 2 nodes
# 

# Params: % in window to consider synched, {begin, end, avg} for computing group time
# Input:  Output of processGroups.pl
# Output: Time (taken to attain synchronization)

use strict;
use util;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 1 > @ARGV ) {
    die "Usage $0 infile outfile threshold grouping\n"
      . "  infile      output of processGroups.pl\n"
      . "  mote_thresh we're synchronized when this number of motes are in one group\n"
      . "  window      how long do they have to stabilize for (in entry numbers)\n"
      . "  grouping    begin, end or average\n"
      . "      how to compute the group firing time\n";

}

my $num_motes   = unique_motes($ARGV[0]);
my $mote_thresh = $num_motes;
my $window      = 1;
my $grouping    = "avg";

if ( 1 < @ARGV ) {
  $mote_thresh = $ARGV[1];
}

if ( 2 < @ARGV ) {
  $window = $ARGV[2];
}

if ( 3 < @ARGV ) {
  $grouping = $ARGV[3];
}

#######################
#                     #
#  Open file handles  #
#                     #
#######################
open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";

###########################
#                         #
#  Compute time to synch  #
#                         #
###########################

print "# motes\t$num_motes\n";
print "# mote threshold\t$mote_thresh\n";
print "# window\t$window\n";
print "# grouping\t$grouping\n";
print "# time to synchronization\n";

my $line_num = 0;
my $streak = 0;

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
    if ( @times >= $mote_thresh ) {
      $streak++;
    } else {
      $streak = 0;
    }

    if ( $streak >= $window ) { 
        $time_to_synch = &group_fire_time($grouping,@times);
        print "# synch on fire number\t$line_num\n";
	printf "$time_to_synch\n";
        exit;
    }
}

# Never attained synchronization
printf "# Never attained synchronization\n";
printf 0;

close INPUT;
