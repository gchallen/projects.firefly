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

my $fitsReceivedTable = $ARGV[0] . "_3000";
#my $fitsReceivedTable = $ARGV[0] . "_2982";
my %seqnoHash;
my $ourDB = DBI->connect($_DSN)
  or die "Couldn't connect to database: $DBI::errstr\n";

# 13 Dec 2004 : GWA : Output some useful data about the experiment
#               parameters, namely which motes were used for what purpose.

my $getInfoQuery = "select sourceaddr, firetime, synced from " .
                   $fitsReceivedTable;
my $getInfoStatement;
$getInfoStatement = $ourDB->prepare($getInfoQuery)
  or die "Couldn't prepare query '$getInfoQuery':" .
         "$DBI::errstr\n";
$getInfoStatement->execute();

# 13 Dec 2004 : GWA : FIXME FINISH

print <<DONE;
# MOTEID\tSEQNO\tRECEIVETIME\tSENTTIME\tSENTDELAY
# JIFFIES 921600
# MOTELAB
# FTSP
DONE

while (my $getSourceRef = $getInfoStatement->fetchrow_hashref()) {
  printf ("%d\t%d\t%d\t%d\t%d\t%d\n",
                 $getSourceRef->{'sourceaddr'},
                 $seqnoHash{$getSourceRef->{'sourceaddr'}}++,
                 $getSourceRef->{'firetime'},
                 $getSourceRef->{'firetime'},
                 0,
                 $getSourceRef->{'synced'});
}
