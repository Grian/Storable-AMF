#!/usr/bin/perl -I/home/sites/combats.ru/slib
#===============================================================================
#
#         FILE:  cgi.pl
#       AUTHOR:  Grishayev Anatoliy (), 
#      VERSION:  1.0
#      CREATED:  05/04/2011 12:18:46 PM
#     REVISION:  ---
#===============================================================================

use strict;
use Storable::AMF3 qw(freeze);
print STDOUT "Content-Type: application/octet-stream\n\n";
print STDOUT freeze( {greeting=>'Hello from Cgi\n'}); # or other usefull object
exit();




