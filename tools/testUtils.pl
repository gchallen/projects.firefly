#!/usr/bin/perl

# FileName:    testUtils.pl 
# Date:        January 2, 2004
#
# Description: 
# Usage:  

# Input:  
# Output: 


use strict;
use util;

my @input = ();
my @numbers = ();
my $average = -1;
my $max = -1;
my $min = -1;
my $stdev = -1;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 1 > @ARGV ) {
    die "Usage: ./testUtils testInputfile (e.g. in.1) \n";
}


#######################
#                     #
#  Open file handles  #
#                     #
#######################
open(INPUT,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";


while(@input = split(' ', <INPUT>)){
    chomp(@input);
    #print "read line: @input \n";
    push(@numbers, @input);
}

close INPUT;


###############################
#                             #
# Test the math utillities in #
# util.pm                     # 
#                             #
###############################

print "Numbers read in: @numbers \n";

$max = max(@numbers);
print "max: $max \n";

$min = min(@numbers);
print "min: $min \n";

$average = average(@numbers);
print "average: $average \n";

$stdev = stdev(@numbers);
print "Std. dev: $stdev \n";
