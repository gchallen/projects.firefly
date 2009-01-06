#!/usr/bin/perl

while($line = <>) {
  $line =~ /(\d+)\: Setting Timer to (\d+)/;
  printf("%d\t%f\n", $1, $2 * (4000000 / 1024));
}
