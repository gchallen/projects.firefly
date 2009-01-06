#!/usr/bin/perl

use strict;

# 13 Dec 2004 : GWA : No more SKEW or FIRE crap.  Just RAW data, without the
#               RAW.
# 15 Dec 2004 : GT  : Not used anymore. Only used to fix initial files.



print "# MOTEID\tSEQNO\tRECEIVETIME\tSENTTIME\tSENTDELAY\n";
while (my $currentLine = <STDIN>) {
  my @currentArray = split("\t", $currentLine);
  if ($currentArray[0] eq "RAW") {
    shift(@currentArray);
    my $newLine = join("\t", @currentArray);
    print "$newLine";
  }
}
