#!/usr/bin/perl

# 15 Dec 2004 : GT : Performs a simple linear regression


use strict;

if (@ARGV < 3) {
  print STDERR "Usage\n";
  exit();
}

open(INPUT, "$ARGV[0]");

my $X = $ARGV[1];
my $Y = $ARGV[2];
my $start;
if (@ARGV == 4) {
  $start = $ARGV[3];
} else {
  $start = 0;
}

my @processArray;
my @currentArray;
my $i;

while (my $currentLine = <INPUT>) {
  @currentArray = split(/\s/, $currentLine);
  my @tempArray;
  if ($currentArray[$X] > $start) {
    $tempArray[0] = $currentArray[$X];
    $tempArray[1] = $currentArray[$Y];
    @processArray[$i++] = \@tempArray;
  }
}

my $dataArray = &linfit(\@processArray);
print "Slope: $dataArray->[0], Intercept: $dataArray->[1]\n";

sub linfit {
  my $arrayRef = shift;
  my $s = 0; 
  my ($del, $b, $a);
  my ($sx, $sy, $sxx, $sxy);

  foreach my $currentRef (@{$arrayRef}) {
    $sx += $currentRef->[0];
    $sy += $currentRef->[1];
    $sxx += ($currentRef->[0] * $currentRef->[0]);
    $sxy += $currentRef->[0] * $currentRef->[1];
    $s++;
  }

  $del = $s*$sxx - $sx*$sx;

  if ($del) {
    $b = ($sxx*$sy - $sx*$sxy) / $del;
    $a = ($s*$sxy - $sx*$sy) / $del;
  } 
  my @tempArray = ($a, $b);
  return \@tempArray;
}
