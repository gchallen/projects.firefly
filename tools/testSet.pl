#!/usr/bin/perl -w

# FileName:    testSet.pl
# Date:        January 3, '05
#
# Description: tests set operations

use strict;
use set_util;

my @one_thru_ten = 1..10;
my @five_thru_ten = 5..10;
my @five_thru_fifteen = 5..15;
my @eleven_thru_fifteen = 11..15;
my @eleven_thru_twenty = 11..20;
my @result;

#
# Test is_in_set
#
if ( &is_in_set(0,\@one_thru_ten) ) {
  warn "0 is should not be in @one_thru_ten";
}

if ( &is_in_set(11,\@one_thru_ten) ) {
  warn "11 is should not be in @one_thru_ten";
}

foreach ( @one_thru_ten ) {
  if ( ! &is_in_set($_,\@one_thru_ten) ) {
    warn "$_ should be in @one_thru_ten";
  }
}

#
# Test intersection
#
@result = &set_intersection(\@one_thru_ten,\@eleven_thru_twenty);

if ( 0 != @result ) {
  warn "@one_thru_ten should not intersect with 11..20 but we returned @result";
}

@result = &set_intersection(\@one_thru_ten,\@five_thru_fifteen);

if ( 6 != @result ) {
  warn "@one_thru_ten should not intersect with @five_thru_fifteen but we returned @result";
}

@result = &set_intersection(\@five_thru_fifteen,\@eleven_thru_twenty);

if ( 5 != @result ) {
  warn "@five_thru_fifteen should not intersect with @eleven_thru_twenty but we returned @result";
}
