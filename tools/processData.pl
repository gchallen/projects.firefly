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
use File::Spec;

use strict;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 2 > @ARGV ) {
    die "Usage $0 infile interval\n"
      . "  infile   converted data file\n"
      . "  interval for processGroups\n";
}

my $infile   = $ARGV[0];
my $interval = $ARGV[1];

my $basefile = $ARGV[0];

$basefile = File::Spec->rel2abs($basefile);

$basefile =~ s/\.gz//;
$basefile =~ s/\.out//;

system "$FindBin::Bin/processEvents.pl $infile ALL";
system "$FindBin::Bin/processGroups.pl $basefile-EVENT-ALL\.out $interval";
system "$FindBin::Bin/groupSpread.pl $basefile-EVENT-ALL-GROUPS\.out auto";
system "$FindBin::Bin/groupPeriod.pl $basefile-EVENT-ALL-GROUPS\.out auto";
system "$FindBin::Bin/groupSize.pl $basefile-EVENT-ALL-GROUPS\.out auto";
system "$FindBin::Bin/ttsRatio.pl $basefile-EVENT-ALL-GROUPS\.out 0.9 3 >> tts\.txt";
