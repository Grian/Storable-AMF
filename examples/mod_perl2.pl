#!/usr/bin/perl -I/home/sites/combats.ru/slib
#===============================================================================
#
#         FILE:  mod_perl2.pl
#
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#       AUTHOR:  Grishayev Anatoliy (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/04/2011 12:21:34 PM
#     REVISION:  ---
#===============================================================================
package MyApacheHandler;
use Storable::AMF3 ();

use strict;
sub handler {
	my $r = shift;
	my $data = get_data_for_flash();
	$r->content_type('application/octet-stream'); # may be we also need content-length here?
	$r->print(Storable::AMF3::freeze($data));
}




