#!/usr/bin/perl

# 13 Dec 2004 : GWA : Grabs data from MoteLab experiments and rewrites it in
#               our format.  For now this only works in single-receiver
#               experiments.  I'll have to figure out something smarter to do
#               when we start with the multi-hop stuff and there are multiple
#               receivers with different timebases that need translation.
#
# Filename: convertMotelab.pl

use strict;
use DBI;

my $_DSN = 
  "DBI:mysql:werner;mysql_socket=/tmp/mysql.sock:host=motelab.eecs.harvard.edu:user=werner:password=marybeth"; 

my $tableRoot = $ARGV[0];

my $fitsReceivedTable = $ARGV[0] . "_2429";
my $fitsInfoTable = $ARGV[0] . "_2431";
my $fitsFiringTable = $ARGV[0] . "_2430";
my $ourDB = DBI->connect($_DSN)
  or die "Couldn't connect to database: $DBI::errstr\n";

# 13 Dec 2004 : GWA : Output some useful data about the experiment
#               parameters, namely which motes were used for what purpose.

my $getInfoQuery = "select distinct sourceaddr, fireseqno from " .
                   $fitsReceivedTable . 
                   " where synced=1";
my $getInfoStatement;
$getInfoStatement = $ourDB->prepare($getInfoQuery)
  or die "Couldn't prepare query '$getInfoQuery':" .
         "$DBI::errstr\n";
$getInfoStatement->execute();
  
while (my $getSourceRef = $getInfoStatement->fetchrow_hashref()) {
  my $getMoreInfoQuery = "select * from $fitsInfoTable where sourceaddr=" .
                         $getSourceRef->{'sourceaddr'} . " and seqno=" .
                         $getSourceRef->{'fireseqno'} . " and FTSPSynced=1";
  my $getMoreInfoStatement;
  $getMoreInfoStatement = $ourDB->prepare($getMoreInfoQuery)
    or die "Couldn't prepare query '$getMoreInfoQuery':" .
           "$DBI::errstr\n";
  $getMoreInfoStatement->execute();
  my @fireTimeArray = ();
  while (my $getMoreInfoRef = $getMoreInfoStatement->fetchrow_hashref()) {
    push(@fireTimeArray, $getMoreInfoRef->{'FTSPStamp'});
  }
  if (@fireTimeArray < 2) {
    next;
  }
  @fireTimeArray = sort {$a <=> $b} @fireTimeArray;
  my $maxDiff = $fireTimeArray[@fireTimeArray - 1] - $fireTimeArray[0];
  printf("%f\t%f\n", $fireTimeArray[0] / 921600, $maxDiff / 921600);
}
