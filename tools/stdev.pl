#!/usr/bin/perl

# FileName:    stdev.pl 
# Date:        December 31, 2004
#
# Description: Computes the standard deviation of a bunch of numbers
# Usage:       ./stdev.pl <inputfile>
#              <input file> can have numbers in any order on multiple lines

# Input:  A row of numbers
# Output: Std. Dev value


use strict;
#use Statistics::Basic::StdDev;

my @numbers = ();
my @input = ();

while(@input = split(' ', <STDIN>)){
    ##print "read line: @lines \n";
    push(@numbers, @input);
}

if ($#numbers == 0) {       
## Only 1 number?
    print "Not Enough information to calculate a\n";
    print "standard deviation\n\n"; 
    exit;
}
#print "Read $#numbers+1 numbers: @numbers \n";

# Use the Perl module
#my $stddev = new Statistics::Basic::StdDev(\@numbers);
#print "Stdev (computed from Perl Module) = ", $stddev->query, "\n";


# Compute manually

## Calculate the average                                                                                             

my $sum = 0;                   
my $n = 0;
for $n (@numbers) { $sum = $sum + $n; }
my $average = $sum / ($#numbers + 1); 
#print "The average is $average\n";

## Calculate the standard deviation 

my $stddev = 0;
for $n (@numbers) {
    $stddev = $stddev + ($n - $average) ** 2;
}
$stddev = sqrt($stddev / $#numbers);
#print "The Standard Deviation (computed manually): ";
print "$stddev\n";          
