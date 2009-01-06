#!/usr/bin/perl

# 15 Dec 2004 : GT : Computes a moving average
#               Works, but not sure if useful


use strict;

my $cnt=0;
my ($i, $p);
my @pts;
my @x;
my $mov_avg_pts=$ARGV[0];
open(FILE, "$ARGV[1]") or die "Crap\n";
my $total=0;

while(<FILE>)
{
    chomp;
      ($i, $p, my $unused) = split(/\t/,$_);
      if ($i eq "") {
        next;
      }
      push @x, $i;
        push @pts, $p;
          $cnt++;
}

for ($i=0; $i<$mov_avg_pts; $i++)
{
    $total += $pts[$i]
}

for ($i=$mov_avg_pts; $i<$#pts; $i++)
{
    print $x[$i]," ",$total/$mov_avg_pts,"\n";
      $total += $pts[$i]-$pts[$i-$mov_avg_pts];
}
