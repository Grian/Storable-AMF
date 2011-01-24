#===============================================================================
#
#         FILE:  66-boolean-3.t
#         COMMENT code taken from boolean-patch 
#===============================================================================


use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(parse_option freeze thaw new_amfdate);
use Data::Dumper;
use Devel::Peek;
#use JSON::XS;

sub boolean{
	return bless \(my $s = $_[0]), 'boolean';
}
sub true(){
	return boolean(1); 
}
sub false(){
	return boolean('');
}
sub JSON::XS::true{
	return bless \(my $o = 1), "JSON::XS::Boolean" ;
}
sub JSON::XS::false{
	return bless \(my $o = 0), "JSON::XS::Boolean";
}

my $total = 19;
eval "use Test::More tests=>$total;";
warn $@ if $@;
my $nop = parse_option('prefer_number, json_boolean');
our $var;
#goto ABC;

# constants
ok( !is_amf_boolean ( ! !1 ),    'perl bool context not converted(t)');
ok( !is_amf_boolean ( ! !0 ),    'perl bool context not converted(f)');
ok( is_amf_boolean ( true ),   '"boolean" true');
ok( is_amf_boolean ( false ),   '"boolean" false');
ok( is_amf_boolean ( JSON::XS::true ),   'JSON::XS::true');
ok( is_amf_boolean ( JSON::XS::false ),   'JSON::XS::false');

# Vars
ok( !is_amf_boolean ( $a = 4 ),      'int var');
ok( !is_amf_boolean ( $a = 4.0 ), 'double var');
ok( !is_amf_boolean ( $a = "4" ),     'str var');
ok( is_amf_boolean (  $a = JSON::XS::true ),  'JSON::XS bool var');
ok( is_amf_boolean (  $a = true ),  'boolean var');
ok( is_amf_boolean (  $a = JSON::XS::false ),  'JSON::XS bool var');
ok( is_amf_boolean (  $a = false ),  'boolean var');


ABC:
my $json_true = JSON::XS::true;
my $json_false = JSON::XS::false;
#print Dumper( $json_true );
#print Dumper( amf_roundtrip( $json_true ));
#print Storable::AMF0->VERSION, "\n";
#exit;
# booleans cannot be referenced in amf
my $object = {
    a => {a => 1},
    jxb1 => $json_true,
    jxb2 => $json_true,
    c => {a => 1, jxb3 => $json_true },
};
is_deeply( amf_roundtrip($object), $object, "roundtrip multi-bool" );
is_deeply( amf_roundtrip( true ), $json_true, '"boolean" comes back as JSON::XS' );

# Added more accurate tests
isa_ok( amf_roundtrip( true ) , "JSON::XS::Boolean" );
isa_ok( amf_roundtrip( $json_true ) , "JSON::XS::Boolean" );
isa_ok( amf_roundtrip( false ) , "JSON::XS::Boolean" );
isa_ok( amf_roundtrip( $json_false ) , "JSON::XS::Boolean" );

sub is_amf_boolean{
	ord( freeze( $_[0], )) == 1;
}
sub amf_roundtrip {
    my $src = shift;
    #use Data::Dumper;
	my $amf = freeze( $src );
    #diag( "stored: $amf" );
    #diag( "stored(hex): ", unpack("H*", $amf) );
    my $struct = thaw($amf, $nop);
    return $struct;
}
