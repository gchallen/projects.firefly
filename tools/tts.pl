#!/usr/bin/perl -w

# FileName:    tts.pl
# Date:        January 5, '05
#
# Description: Format time to fire results

# Input:  Output of time to synch script
# Output: Data file name
#         number of motes
#         time to synch

use strict;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 1 > @ARGV ) {
    die "Usage $0 infile\n"
      . "  infile   output of processGroups.pl\n";
}

#######################
#                     #
#  Open file handles  #
#                     #
#######################
open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";

my $outfile = $ARGV[0];
$outfile =~ s/.txt/.rpt/;

open(OUTPUT, ">$outfile")
    or die "Unable to open output file $outfile ($!)";

my $genfile = $ARGV[0];
$genfile =~ s/.txt/.gen/;

open(GENFILE, ">$genfile")
    or die "Unable to open output file $outfile ($!)";

##########################
#                        #
#  Compute Group Spread  #
#                        #
##########################

my ($dataset, $motes) = ("NULL",-1);
while ( my $line = <INPUT> ) {
  my $tts = 0;

  chomp( $line );

  # skip comments
  if ( $line =~ /^\#/ ) {
    if ( $line =~ /^# Processing/ ) {
      ($dataset) = $line =~ /^# Processing .*\/([A-Za-z0-9\-]*)-EVENT-ALL-GROUPS.out ->.*/;
    }
    if ( $line =~ /^# motes/ ) {
      ($motes) = $line =~ /^# motes\s([0-9]+)/;
    }

    next;
  }

  if ( $line =~ /^[0-9\.]+/ ) {
    ($tts) = $line =~ /^([0-9\.]+)/;

    # Print for report
    printf OUTPUT "%-25s %5s   %-20s\n", $dataset, $motes, $tts;
    print GENFILE "$dataset\t$motes\t$tts\n";
  }
}

close INPUT;
close OUTPUT;
