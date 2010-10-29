#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  t.pl
#
#        USAGE:  ./t.pl  
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
#      CREATED:  10/25/2010 12:54:35 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use ExtUtils::testlib;
use RefCount;

print RefCount::show_double( "afasdf" );
print RefCount::show_double( 1  );
print RefCount::show_double( [ 1, "2", 3.0, {a=>4}]  );
exit;

show( my $s = "afasdf" );
my $m = { a=>1 };
show( $m );
my $n = [ undef, 1,2.0, "m", { x => 1},1, {y=>[]}];
show( $n );

show(my $n = [ undef, 1,2.0, "m", { x => 1},1, {y=>[]}]);



