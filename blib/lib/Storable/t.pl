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
#      CREATED:  10/19/2010 05:57:46 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use ExtUtils::testlib;

use Storable::AMF0 qw(freeze thaw new_date perl_date);
use Storable::AMF3 qw(perl_date);
use Data::Dumper;

print Dumper( Storable::AMF::new_date(0));
print Dumper( new_date(1));
print Dumper( "ok=".perl_date( new_date(1)));


print Dumper( length(freeze(new_date(0))));
print Dumper( perl_date thaw( freeze( new_date($_)  ))) for 0, 1, 10;


package A;
use Data::Dumper;
use Storable::AMF3 qw(freeze thaw new_date perl_date);
print Dumper( length(freeze(new_date(0))));
print Dumper( unpack( "H*", freeze(new_date(0))));

#print Dumper( perl_date thaw( freeze( new_date($_)  ))) for 0, 1, 10;

