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
      . "  infile   output of ttsRatio.pl\n";
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

open(OUTPUT, ">>$outfile")
    or die "Unable to open output file $outfile ($!)";

my $genfile = $ARGV[0];
$genfile =~ s/.txt/.gen/;

open(GENFILE, ">>$genfile")
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

  $tts = split(/\t/,$line)[2];

  # Print for report
  printf OUTPUT "%-25s %5s   %-20s\n", $dataset, $motes, $tts;
  print GENFILE "$dataset\t$motes\t$tts\n";
}

close INPUT;
close OUTPUT;
