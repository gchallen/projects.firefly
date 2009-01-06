#!/usr/bin/perl -w

# FileName:    genPlots.pl
# Date:        January 6, '05
#
# Description: Generate plots based on tts report

# Input:  tts report
# Output: If synch    group spread & period plots
#         Otherwise   group size plot

use File::Spec;

use strict;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 2 > @ARGV ) {
    die "Usage $0 infile outdir\n"
      . "  infile   output of genTTSReport.pl\n"
      . "  outdir   where to put the plots\n";
}

my $outdir = $ARGV[1];
$outdir =~ s/\/$//;

#######################
#                     #
#  Open file handles  #
#                     #
#######################
open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";


####################
#                  #
#  Generate Plots  #
#                  #
####################

while ( my $line = <INPUT> ) {

  chomp( $line );

  # skip comments
  if ( $line =~ /^\#/ ) {
    next;
  }

  my ($datasetpath, $motes, $tts) = split(/\t/, $line);
  $datasetpath = File::Spec->rel2abs($datasetpath);

  my ($volume,$directories,$file) = File::Spec->splitpath( $datasetpath );
  my $dataset = $file;
  $dataset =~ s/-EVENT-ALL-GROUPS\.out//;

  my $data_base = $datasetpath;
  $data_base =~ s/-EVENT-ALL-GROUPS\.out//;

  my $data_spread = "$data_base-GROUP-SPREAD\.out";
  my $data_period = "$data_base-GROUP-PERIOD\.out";
  my $data_size   = "$data_base-GROUP-SIZE\.out";

  my $script      = "$outdir\/$dataset\.plot";

  my $plot_base   = "$outdir\/$dataset";
  my $plot_spread = "$plot_base-GROUP-SPREAD\.eps";
  my $plot_period = "$plot_base-GROUP-PERIOD\.eps";
  my $plot_size   = "$plot_base-GROUP-SIZE\.eps";

  open(PLOT, ">$script")
    or die "Unable to open input file $plot_spread ($!)";

  if ( 0 == $tts ) {
    # size plot
    print PLOT "set term postscript eps color\n";
    print PLOT "set title \"$dataset size plot\"\n";
    print PLOT "set output '$plot_size'\n";
    print PLOT "plot '$data_size'\n";
    print PLOT "\n";

  } else {
    # spread plot
    print PLOT "set title \"$dataset spread plot\"\n";
    print PLOT "set term postscript eps color\n";
    print PLOT "set output '$plot_spread'\n";
    print PLOT "plot '$data_spread'\n";
    print PLOT "\n";
    # period plot
    print PLOT "set title \"$dataset period plot\"\n";
    print PLOT "set output '$plot_period'\n";
    print PLOT "plot '$data_period'\n";
  }

  print PLOT "quit\n";

  close PLOT;

  system "gnuplot $script";
}

close INPUT;
