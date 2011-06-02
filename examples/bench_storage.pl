#!/usr/bin/perl -I/home/sites/combats.ru/slib
#===============================================================================
#
#         FILE:  bench_targ.pl
#
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#       AUTHOR:  Grishayev Anatoliy (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/05/2011 12:59:56 PM
#     REVISION:  ---
#===============================================================================

use strict;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze parse_serializator_option thaw);
use Storable::AMF qw(freeze3 dclone);
use Benchmark qw(cmpthese);
use Data::Dumper;


my $obj = [ 1 .. 10, { a=> "Hello", b=> "Word", c=> "Mother" }, "Litrebol" ];
my $bobj = [ map dclone( $obj ), 1..10 ];
my $sobj = { a =>1, b=>1, c=>1 } ;
my $opt_targ = parse_serializator_option( "+targ" );
my $opt_def  = parse_serializator_option( "-targ" );
my $option   = parse_serializator_option( "+prefer_number" );

my $storage = Storable::AMF0::amf_tmp_storage( $option );
my $ff_obj   = freeze( $obj ); 
my $ff_sobj   = freeze( $sobj ); 
my $ff_bobj   = freeze( $bobj ); 
#( $ff_obj , $ff_sobj ) = ( $ff_sobj,  $ff_obj  );

print Dumper( thaw( $ff_obj),thaw($ff_sobj));

printf "%d<=>%d\n", $opt_targ, $opt_def, "\n";

cmpthese( -1,{
        bobj_1   =>  sub { 
            my $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
            $s = thaw( $ff_bobj, $option);
                
        },
        bobj_st   => sub { 
            my $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
            $s = thaw( $ff_bobj, $storage) ;
        },
});
cmpthese( -1,{
        obj_1   =>  sub { 
            my $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
            $s = thaw( $ff_obj, $option);
                
        },
#        obj_0   =>  sub { 
#            my $s = thaw( $ff_obj);
#            $s = thaw( $ff_obj);
#            $s = thaw( $ff_obj);
#            $s = thaw( $ff_obj);
#            $s = thaw( $ff_obj);
#            $s = thaw( $ff_obj);
#            $s = thaw( $ff_obj);
#                
#        },
        obj_st   => sub { 
            my $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
            $s = thaw( $ff_obj, $storage) ;
        },
});


cmpthese( -1,{
        sobj_1   =>  sub { 
            my $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
            $s = thaw( $ff_sobj, $option) ;
        },
        
        sobj_st   => sub { 
            my $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
            $s = thaw( $ff_sobj, $storage) ;
        },
        }
        );








