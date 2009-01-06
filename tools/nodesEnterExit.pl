#!/usr/bin/perl

# FileName:    nodesEnterExit.pl
# Date:        December 30, 2004
#
# Description: Monitors nodes that are entering or leaving a group:
#              Identifies missing/duplicate group members
#              Determines if skipped or duplicate packets

# Input:  Output of processGroups.pl

# Use seq numbers to determine:
# When a fire was missed vs. not recorded
# When duplicate packets received

use FindBin;
use lib $FindBin::Bin;

use strict;
use util;
use set_util;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 2 > @ARGV ) {
    die "Usage $0 infile outfile";
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
  $outfile .= "ENTER-EXIT.out";
}

open(OUTPUT, ">$outfile")
    or die "Unable to open output file $outfile ($!)";

my $logfile = $outfile;
$logfile =~ s/\.out/\.log/;

open(LOGFILE, ">$logfile")
  or die "Unable to open log file $logfile ($!)";

print LOGFILE "# Motes\tBest Match\tAdded\tRemoved\n";

###############################
#                             #
#  Compute Nodes Enter Exit   #
#                             #
###############################

my $num_motes = unique_motes($ARGV[0]);
print OUTPUT "# motes\t$num_motes\n";

my (@groups);

while ( my $line = <INPUT> ) {
  my ( @motes, $match, @added, @removed, $ref_group );

  chomp ($line);

  # skip comments
  if ( $line =~ /^\#/ ) {
    next;
  }

  @motes = &motes_from_group($line);

  if ( 0 == @motes ) {
    next;
  }

  #
  # uniquify motes
  #

  my %hsh;
  undef @hsh{@motes};
  @motes = keys %hsh;

  @motes = sort { $a <=> $b } @motes;

  $match = &best_match( @motes );

  # Did this match anything?
  #
  # If not: we have never seen any of these motes before
  #   add the group to groups

  if ( -1 == $match ) {
    print OUTPUT "CREATING  <@motes>\n";
    push( @groups, \@motes );
    next;
  }

  # This group overlaps with an existing group
  # at least one mote is common
  #
  # Some motes have been added to the group and some have been removed
  @added = &set_added( \@motes, $groups[$match] );
  @removed = &set_removed( \@motes, $groups[$match] );

  $ref_group = $groups[$match];
  print LOGFILE "<@motes>\t<@$ref_group>\t<@added>\t<@removed>\n";

  # How about the added motes?
  # We have to remove them from wherever they were
  for ( my $i = 0; $i <= $#groups; ++$i ) {
    my @intersection = &set_intersection(\@added,$groups[$i]);

    if ( @intersection ) {
      my @reduced_group = &set_subtract($groups[$i],\@intersection);
      my $ref = $groups[$i];

      print OUTPUT "PRUNING   <@intersection> FROM <@$ref> RESULT <@reduced_group>\n";

      $groups[$i] = \@reduced_group;
    }
  }

  # any removed motes, are a group unto themselves
  # we know they are not in another group
  # because they were removed from a current group
  #   and groups do not overlap

  if ( 0 != @removed ) {
    print OUTPUT "REMOVED   <@removed> FROM <@$ref_group> ";
    @$ref_group = &set_subtract($ref_group,\@removed);
    print OUTPUT "RESULT <@motes>\n";

    print OUTPUT "SPLIT-OFF <@removed>\n";
    push( @groups, \@removed );
  }

  if ( 0 != @added ) {
    print OUTPUT "ADDING    <@added> TO <@$ref_group> ";

    foreach ( @added ) {
      push( @$ref_group, $_ );
      @$ref_group = sort { $a <=> $b } @$ref_group;
    }

    print OUTPUT "RESULT <@$ref_group>\n";
  }

}

sub best_match {
  my $best_score = 0;
  my $best_score_index = -1;
  my $score;
  my (@set) = @_;

  for ( my $i = 0; $i <= $#groups; ++$i ) {
    $score = &set_intersection(\@set, $groups[$i]);

    if ( $score > $best_score ) {
      $score = $best_score;
      $best_score_index = $i;
    }
  }

  return $best_score_index;
}

close INPUT;
close OUTPUT;
