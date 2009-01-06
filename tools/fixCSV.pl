#!/usr/bin/perl

open(INPUT, "$ARGV[0]");
open(OUTPUT, ">$ARGV[1]");

while ($line = <INPUT>) {
  if ($line =~ /^Directory/) {
    print OUTPUT $line;
  } else {
    if ($line =~ /(08-Jan-2005-6-\d)/) {
      @line = split(/08-Jan-2005-6-\d\s/, $line);
      shift(@line);
      foreach $currentLine (@line) {
        print OUTPUT "$1\t$currentLine\n";
      }
    }
  }
}
