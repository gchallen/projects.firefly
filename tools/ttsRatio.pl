#!/usr/bin/perl -w

# FileName:    ttsRatio.pl
# Date:        January 6, '05
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

if ( 1 > @ARGV ) {
    die "Usage $0 infile threshold window grouping\n"
      . "  infile    output of processGroups.pl\n"
      . "  threshold we're synchronized when this fraction of motes are in one group\n"
      . "  window      how long do they have to stabilize for (in entry numbers)\n"
      . "  grouping  begin, end or average\n"
      . "      how to compute the group firing time\n";

}

my $threshold = 1;
my $window      = 1;
my $grouping = "avg";

if ( 1 < @ARGV ) {
    $threshold = $ARGV[1];
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

my $all_file  = $ARGV[0];
$all_file =~ s/EVENT-ALL-GROUPS/EVENT-ALL/;

my $num_motes = unique_motes($all_file);

my $line_num = 0;
my $streak   = 0;

while ( my $line = <INPUT> ) {
    my ($time_to_synch, @times, $group_size, $group_ratio);

    $line_num++;

    chomp( $line );

    # skip comments
    if ( $line =~ /^\#/ ) {
        next;
    }

    # compute number of motes in group
    @times = &times_from_group($line);

    $group_size = @times;
    $group_ratio = ($group_size / $num_motes);


    # Does the number of motes in this group exceed the threshold?
    if ( $group_ratio >= $threshold ) {
      $streak++;
    } elsif ( $group_ratio > (1 - $threshold) ) {
      $streak = 0;
    }

    if ( $streak >= $window ) {
        $time_to_synch = &group_fire_time($grouping,@times);
        print "$ARGV[0]\t$num_motes\t$time_to_synch\n";
        exit;
    }
}

# Never attained synchronization
print "$ARGV[0]\t$num_motes\t0\n";

close INPUT;
