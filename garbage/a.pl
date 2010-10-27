#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  a.pl
#
#        USAGE:  ./a.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  10/27/2010 07:36:02 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Devel::Peek;
use Storable::AMF qw(freeze);
sub first{
	print STDERR substr unpack("H*", freeze($_[0])), 0, 2;
	print STDERR " $_[1]\n";
}

$a = 1;
Dump($a);first($a, '$a');
$b = "$a";
Dump($a);first($a, '$a');
print STDERR "=====\n";


$a = "1";
Dump($a);first($a, '$a');
$b = 0+$a;
Dump($a);first($a, '$a');
$a = 0+$a;
Dump($a);first($a, '$a');

print STDERR "*****************\n";

$a = " +19239232932939232932932392932392932939";
Dump($a);first($a, '$a');
$b = 0+$a;
Dump($a);first($a, '$a');

