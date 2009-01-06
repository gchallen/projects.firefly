#!/usr/bin/perl -w

# FileName:    max.pl
# Date:        January 6, '05
#

use FindBin;
use lib $FindBin::Bin;

use strict;
use util;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 2 > @ARGV ) {
    die "Usage $0 file column\n";
}

my $file   = $ARGV[0];
my $column = $ARGV[1];

#######################
#                     #
#  Open file handles  #
#                     #
#######################
open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";

#################
#               #
#  Compute Max  #
#               #
#################

my (@vals, $max_val);

while ( my $line = <INPUT> ) {
  my (@entry, $val);

  chomp( $line );

  # skip comments
  if ( $line =~ /^\#/ ) {
    next;
  }

  @entry = split(/\t/, $line);

  if ( $column > @entry ) {
    next;
  }

  $val = $entry[$column];

  push @vals, $val;
}

$max_val = &max(@vals);

print "$file $column max: $max_val\n";

close INPUT;
