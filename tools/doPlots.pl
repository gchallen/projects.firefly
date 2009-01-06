#!/usr/bin/perl -w

# FileName:    tts.pl
# Date:        January 6, '05
#
# Description: Format time to fire results

# Input:  converted data file
# Output: Data file name
#         number of motes
#         time to synch

use FindBin;
use strict;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 1 > @ARGV ) {
    die "Usage $0 plotsdir\n"
      . "  infile    converted data file\n"
      . "  plotsdir  where to put the plots\n";
}

my $plotsdir = $ARGV[0];

system "$FindBin::Bin/genTTSReport.pl tts\.txt";
system "$FindBin::Bin/genPlots.pl tts\.gen $plotsdir";
