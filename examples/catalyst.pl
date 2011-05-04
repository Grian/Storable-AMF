#!/usr/bin/perl -I/home/sites/combats.ru/slib
#===============================================================================
#
#         FILE:  catalyst.pl
#
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#       AUTHOR:  Grishayev Anatoliy (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/04/2011 12:23:28 PM
#     REVISION:  ---
#===============================================================================

use strict;
use Storable::AMF3;
sub some_action : Local {
    my ( $self, $c ) = @_;
    my $data = $self->get_data_for_flash($c);
    $c->res->content_type('application/octet-stream');
    $c->res->body( Storable::AMF3::freeze($data) );
}




