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

my $fitsReceivedTable = $ARGV[0] . "_2401";
my $fitsInfoTable = $ARGV[0] . "_2409";
my $fitsFiringTable = $ARGV[0] . "_2403";
my $ourDB = DBI->connect($_DSN)
  or die "Couldn't connect to database: $DBI::errstr\n";

# 13 Dec 2004 : GWA : Output some useful data about the experiment
#               parameters, namely which motes were used for what purpose.

my $getInfoQuery = "select sourceaddr, firetime, fireSeqNo, synced from " .
                   $fitsReceivedTable;
my $getInfoStatement;
$getInfoStatement = $ourDB->prepare($getInfoQuery)
  or die "Couldn't prepare query '$getInfoQuery':" .
         "$DBI::errstr\n";
$getInfoStatement->execute();

while (my $getSourceRef = $getInfoStatement->fetchrow_hashref()) {
  my $getMoreInfoQuery = "select * from $fitsInfoTable where myseqno=" .
                         $getSourceRef->{'fireSeqNo'} . " and myaddr=" .
                         $getSourceRef->{'sourceaddr'};
  my $getMoreInfoStatement;
  $getMoreInfoStatement = $ourDB->prepare($getMoreInfoQuery)
    or die "Couldn't prepare query '$getMoreInfoQuery':" .
           "$DBI::errstr\n";
  $getMoreInfoStatement->execute();
  my $numHeard = 0;
  my $numProcessed = 0;
  my $numEarlySkips = 0;
  my $numTooClose = 0;
  my $numNoDelay = 0;
  my $error = 0;
  my $numError = 0;
  my $friendsString = "";
  while (my $getMoreInfoRef = $getMoreInfoStatement->fetchrow_hashref()) {
    if ($getMoreInfoRef->{'ignored'} != 0) {
      printf ("%d\t%f\t%f\t%d\t%f\n",
              $getSourceRef->{'sourceaddr'},
              ($getMoreInfoRef->{'FTSPStamp'} -
              $getMoreInfoRef->{'sentdelay'}) / 921600,
              $getMoreInfoRef->{'FTSPStamp'} / 921600,
              $getMoreInfoRef->{'ignored'},
              (abs(($getMoreInfoRef->{'FTSPStamp'} -
              $getMoreInfoRef->{'sentdelay'}) - $getSourceRef->{'firetime'}) 
              / 921600) - 2);
    }
  }
}
