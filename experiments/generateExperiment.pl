#!/usr/bin/perl

# 09 Jan 2005 : GWA : Just a quick a dirty hack to generate the experiment
#               files.  Don't bother committing changes since this script
#               should be rewritten every five minutes :-).

for ($FFMult = 1; $FFMult <= 100; $FFMult++) {
  $FFConstant = 10 * $FFMult;
  for ($numMotes = 2; $numMotes <= 20; $numMotes++) {
    print "08-Jan-2005-6 $FFConstant - $numMotes 3600 ALLTOALL\n";
  }
  for ($numMotes = 2; $numMotes <= 20; $numMotes++) {
    print "08-Jan-2005-6 $FFConstant ./topos/LINE$numMotes.nss $numMotes 3600 LINE\n";
  }
  for ($numMotes = 2; $numMotes <= 20; $numMotes++) {
    print "08-Jan-2005-6 $FFConstant ./topos/RING$numMotes.nss $numMotes 3600 RING\n";
  }
  for ($numMotes = 2; $numMotes <= 10; $numMotes++) {
    print "08-Jan-2005-6 $FFConstant ./topos/GRID$numMotes" . "x" .  "$numMotes.nss " . $numMotes**2 . " 3600 GRID\n";
  }
}
