use strict;
use ExtUtils::testlib;
use Storable::AMF0 qw(parse_option);
use Data::Dumper;

my $total = 4+ 
	+ 6*2 # One option 
	+ 5+4 + 4
	+ 6 ;# - sign;
#*CORE::GLOBAL::caller = sub { CORE::caller($_[0] + $Carp::CarpLevel + 1) }; 
use warnings;
eval "use Test::More tests=>$total;";
warn $@ if $@;


is( parse_option(''), 0, "parse empty==0");
is( parse_option(' '), 0, "parse empty==0");
is( parse_option(','), 0, "parse empty==0");
is( parse_option('&'), 0, "parse empty==0");


is( parse_option('strict'), 1, "parse strict==1");
is( parse_option('utf8_decode'), 2, "parse utf8_decode==2");
is( parse_option('utf8_encode'), 4, "parse utf8_encode=4");
is( parse_option('raise_error'), 8, "parse raise_error==8");
is( parse_option('millisecond_date'), 16, "parse millisecond_date==16");
is( parse_option('prefer_number'), 32, "parse prefer_number==32");

is( parse_option('+strict'), 1, "parse strict==1");
is( parse_option('+utf8_decode'), 2, "parse utf8_decode==2");
is( parse_option('+utf8_encode'), 4, "parse utf8_encode=4");
is( parse_option('+raise_error'), 8, "parse raise_error==8");
is( parse_option('+millisecond_date'), 16, "parse millisecond_date==16");
is( parse_option('+prefer_number'), 32, "parse prefer_number==32");

is( parse_option(' strict'), 1, "-parse strict==1");
is( parse_option('& utf8_decode'), 2, "-parse utf8_decode==2");
is( parse_option('#utf8_encode'), 4, "-parse utf8_encode=4");
is( parse_option('raise_error%'), 8, "-parse raise_error==8");
is( parse_option('millisecond_date,'), 16, "-parse millisecond_date==16");


# All options && with +
is( parse_option('strict,utf8_encode,utf8_decode,raise_error,,millisecond_date,'), 31, "-parse all==31");
is( parse_option(',strict,% utf8_encode,utf8_decode,raise_error,,millisecond_date'), 31, "-parse all==31");
is( parse_option('+strict,+utf8_encode,+utf8_decode,+raise_error,,+millisecond_date,'), 31, "-parse all==31");
is( parse_option(',+strict,% +utf8_encode,+utf8_decode,+raise_error,,+millisecond_date'), 31, "-parse all==31");


fail_parse_ok( 'strict_' );
fail_parse_ok( 'abc' );
fail_parse_ok( 'utf8_decode1' );
fail_parse_ok( '_raise_erro' );




is( parse_option("$_ -$_"), 0, "parse $_ -$_" ) for qw(strict);
is( parse_option("$_ -$_"), 0, "parse $_ -$_" ) for qw(utf8_decode);
is( parse_option("$_ -$_"), 0, "parse $_ -$_" ) for qw(utf8_encode);
is( parse_option("$_ -$_"), 0, "parse $_ -$_" ) for qw(raise_error);
is( parse_option("$_ -$_"), 0, "parse $_ -$_" ) for qw(millisecond_date);
is( parse_option("$_ -$_"), 0, "parse $_ -$_" ) for qw(prefer_number);

sub fail_parse_ok{
	use Carp;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	local $@;
	my $s = eval{ parse_option($_[0]) };
	ok( !defined && $@, "fail parse '$_[0]'");
}
