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

my $fitsReceivedTable = $ARGV[0] . "_1700";
my $fitsDelayTable = $ARGV[0] . "_1698";

my %infoHash;


my $ourDB = DBI->connect($_DSN)
  or die "Couldn't connect to database: $DBI::errstr\n";

# 13 Dec 2004 : GWA : Output some useful data about the experiment
#               parameters, namely which motes were used for what purpose.

my $getInfoQuery = "select distinct motelabmoteid from " .
                   $fitsReceivedTable;
my $getInfoStatement;
$getInfoStatement = $ourDB->prepare($getInfoQuery)
  or die "Couldn't prepare query '$getInfoQuery':" .
         "$DBI::errstr\n";
$getInfoStatement->execute();

# 13 Dec 2004 : GWA : FIXME FINISH

while (my $getSourceRef = $getInfoStatement->fetchrow_hashref()) {
  my $currentReceiver = $getSourceRef->{'motelabmoteid'};
  open(OUTPUT, ">RECEIVER$currentReceiver") or
    die "Can't open output file\n";

  my $getDataQuery = "select table1.sourceaddr, table1.seqno," .
                     " table1.senttime, table1.sentdelay," .
                     " table2.receivedtime from " .
                     $fitsDelayTable . " as table1, " .
                     $fitsReceivedTable . " as table2" .
                     " where table1.seqno=table2.seqno and" .
                     " table1.sourceaddr=table2.sourceaddr and" .
                     " table1.motelabmoteid=$currentReceiver";
  my $getDataStatement;
  $getDataStatement = $ourDB->prepare($getDataQuery)
    or die "Couldn't prepare query '$getDataQuery':" .
           "$DBI::errstr\n";
  $getDataStatement->execute();

  print OUTPUT <<DONE;
# MOTEID\tSEQNO\tRECEIVETIME\tSENTTIME\tSENTDELAY
# JIFFIES 921600
# MOTELAB
DONE

  while (my $getDataRef = $getDataStatement->fetchrow_hashref()) {

    # 13 Dec 2004 : GWA : We're just going to print RAW data now.

    print OUTPUT "$getDataRef->{'sourceaddr'}\t" .
          "$getDataRef->{'seqno'}\t$getDataRef->{'receivedtime'}\t" .
          "$getDataRef->{'senttime'}\t$getDataRef->{'sentdelay'}\n";
  }
  close OUTPUT;
}
