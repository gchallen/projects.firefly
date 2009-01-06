#!/usr/bin/perl

while (<>) {
  if ($_ =~ /^#/) {
    next;
  }
  ($unused, $unused, $unused, $unused, $delay) = split;
  printf("%f\n", ($delay / 921600) * 1000);
}
