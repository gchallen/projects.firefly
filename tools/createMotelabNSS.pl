#!/usr/bin/perl

use strict;
use DBI;

my $_DSN = 
  "DBI:mysql:auth;mysql_socket=/tmp/mysql.sock:host=motelab.eecs.harvard.edu:user=werner:password=marybeth"; 

my $groupSpread = 0;
if (@ARGV > 0) {
  $groupSpread = $ARGV[0];
}

my $groupNumber = 0;
if (@ARGV > 1) {
  $groupNumber = $ARGV[1];
}

my $ourDB = DBI->connect($_DSN)
  or die "Couldn't connect to database: $DBI::errstr\n";

if ($groupNumber == 0) {
  my $groupNumberQuery = 
    "select groupno from connectivity order by groupno desc limit 1";
  my $groupNumberStatement;
  $groupNumberStatement = $ourDB->prepare($groupNumberQuery)
    or die "Couldn't prepare query '$groupNumberQuery':" .
           "$DBI::errstr\n";
  $groupNumberStatement->execute();
  my $groupNumberRef = $groupNumberStatement->fetchrow_hashref();
  $groupNumber = $groupNumberRef->{'groupno'};
}

my $selectInfoQuery =
  "select sum(num_samp) as num_samp, sum(num_heard) as num_heard, tomote, " .
  "frommote from connectivity where groupno<=$groupNumber " .
  "and groupno>=" . ($groupNumber - $groupSpread) . " group by tomote, frommote";
my $selectInfoStatement;
$selectInfoStatement = $ourDB->prepare($selectInfoQuery)
  or die "Couldn't prepare query '$selectInfoQuery':" .
         "$DBI::errstr\n";
$selectInfoStatement->execute();

my $maxMote = 0;
my $minMote = 100;
my @dataArray;
while (my $selectInfoRef = $selectInfoStatement->fetchrow_hashref()) {
  $dataArray[$selectInfoRef->{'frommote'}][$selectInfoRef->{'tomote'}] =
    ($selectInfoRef->{'num_heard'} / $selectInfoRef->{'num_samp'});
  if ($selectInfoRef->{'frommote'} > $maxMote) {
    $maxMote = $selectInfoRef->{'frommote'};
  }
  if ($selectInfoRef->{'tomote'} > $maxMote) {
    $maxMote = $selectInfoRef->{'tomote'};
  }
  if ($selectInfoRef->{'frommote'} < $minMote) {
    $minMote = $selectInfoRef->{'frommote'};
  }
  if ($selectInfoRef->{'tomote'} < $minMote) {
    $minMote = $selectInfoRef->{'tomote'};
  }
  if (!defined($dataArray[$selectInfoRef->{'tomote'}][$selectInfoRef->{'frommote'}])) {
    $dataArray[$selectInfoRef->{'tomote'}][$selectInfoRef->{'frommote'}] = 0;
  }
}

my @aliveArray;

for (my $i = 0; $i <= $maxMote; $i++) {
  if (!defined($dataArray[$i])) {
    for (my $j = $minMote; $j <= $maxMote; $j++) {
      $dataArray[$i][$j] = 0;
    }
  } else {
    $aliveArray[$i] = 1;
    for (my $j = 0; $j <= $maxMote; $j++) {
      if (!defined($dataArray[$i][$j])) {
        $dataArray[$i][$j] = 0;
      } else {
        $aliveArray[$j] = 1;
      }
    }
  }
}

# 05 Apr 2005 : GWA : Kill off problem motes.

foreach my $currentBadMote (8,10,14,15,17) {
  $aliveArray[$currentBadMote] = 0;
}

my $columnSkipCount = 0;
for (my $i = 0; $i <= $maxMote; $i++) {
  if (!($aliveArray[$i])) {
    $columnSkipCount++;
    next;
  }
  my $rowSkipCount = 0;
  for (my $j = 0; $j <= $maxMote; $j++) {
    if (!($aliveArray[$j])) {
      $rowSkipCount++;
      next;
    }
    if ($i == $j) {
      next;
    }
    printf("%d:%d:%.3f\n", 
           $i - $columnSkipCount, 
           $j - $rowSkipCount, 
           1 - $dataArray[$i][$j]);
  }
}
