use strict;
use ExtUtils::testlib;
use Storable::AMF0 qw(parse_option freeze thaw);
use Data::Dumper;

my $total = 8 ;
#*CORE::GLOBAL::caller = sub { CORE::caller($_[0] + $Carp::CarpLevel + 1) }; 
use warnings;
eval "use Test::More tests=>$total;";
warn $@ if $@;
my $nop = parse_option('prefer_number');

ok( !is_amf_string( 1 ),  "plain number");
ok( !is_amf_string( 1 , $nop),  "plain number");
ok( is_amf_string( "1" ), "plain string");
ok( is_amf_string( "1", $nop ), "plain string");
$a = 1;
$b = "$a";
ok( is_amf_string($a)         , "number converted is string" );
ok( is_amf_string($a, $nop)   , "number converted is double(-)" );

$a = "1";
$b = $a + 0;

ok( is_amf_string($a)         , "string converted is string" );
ok( is_amf_string($a, $nop)   , "string converted is double(-)" );

#ok( is_amf_string($a)   , "number converted is string" );


sub is_amf_string{
	ord( freeze( $_[0], $_[1]||0 )) == 2;
}
