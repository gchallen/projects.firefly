#!/usr/bin/perl -w

# FileName:    plot.pl
# Date:        January 5, '05
#
# Description: Generate plots based on tts report

# Input:  tts report
# Output: If synch    group spread & period plots
#         Otherwise   group size plot

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


##########################
#                        #
#  Compute Group Spread  #
#                        #
##########################

while ( my $line = <INPUT> ) {
  chomp( $line );

  # skip comments
  if ( $line =~ /^\#/ ) {
    next;
  }

  my ($dataset, $motes, $tts) = split(/\t/, $line);

  my ($date) = $line =~ /([0-9][0-9]-Dec-2004-[0-9]).*/;

  my $data_base   = "/local/fits/CS266Project/data/$date/$dataset";
  my $data_spread = "$data_base-GROUP-SPREAD\.out";
  my $data_period = "$data_base-GROUP-PERIOD\.out";
  my $data_size   = "$data_base-GROUP-SIZE\.out";

  my $script      = "/local/fits/plots/$dataset\.plot";

  my $plot_base   = "/local/fits/plots/$dataset";
  my $plot_spread = "$plot_base-GROUP-SPREAD\.eps";
  my $plot_period = "$plot_base-GROUP-PERIOD\.eps";
  my $plot_size   = "$plot_base-GROUP-SIZE\.eps";

  open(PLOT, ">$script")
    or die "Unable to open input file $plot_spread ($!)";

#  print PLOT "# $dataset\n";

  if ( 0 == $tts ) {
#    print PLOT "# Size Plot\n";
    print PLOT "set term postscript eps color\n";
    print PLOT "set title \"$dataset size plot\"\n";
    print PLOT "set output '$plot_size'\n";
    print PLOT "plot '$data_size'\n";
    print PLOT "\n";

  } else {
#    print PLOT "# Spread Plot\n";
    print PLOT "set title \"$dataset spread plot\"\n";
    print PLOT "set term postscript eps color\n";
    print PLOT "set output '$plot_spread'\n";
    print PLOT "plot '$data_spread'\n";
    print PLOT "\n";
#    print PLOT "# Period Plot\n";
    print PLOT "set title \"$dataset period plot\"\n";
    print PLOT "set output '$plot_period'\n";
    print PLOT "plot '$data_period'\n";
  }

  print PLOT "quit\n";

  close PLOT;

  system "gnuplot $script";
}

close INPUT;
