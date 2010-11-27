use strict;
use warnings;
use lib 't';
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw parse_option);
use Scalar::Util qw(dualvar);
eval 'use Test::More tests => 6;';
my $pref_option = parse_option( '-prefer_number' );
my $pref_option_plus = parse_option( '+prefer_number' );
my $s0 = freeze dualvar(15, "Hello World!!!");
my $s1 = freeze dualvar(15, "Hello World!!!"), $pref_option;
my $s2 = freeze dualvar(15, "Hello World!!!"), $pref_option_plus;

my $s3 = Storable::AMF3::freeze dualvar(15, "Hello World!!!");
my $s4 = Storable::AMF3::freeze dualvar(15, "Hello World!!!"), $pref_option;
my $s5 = Storable::AMF3::freeze dualvar(15, "Hello World!!!"), $pref_option_plus;

is(Storable::AMF0::thaw($s0), 15, "Dual var is number (D)");
is(Storable::AMF0::thaw($s1), "Hello World!!!", "Dual var is string(-N)");
is(Storable::AMF0::thaw($s2), 15, "Dual var is number (+N)");

is(Storable::AMF3::thaw($s3), 15, "Dual var is number (D)");
is(Storable::AMF3::thaw($s4), "Hello World!!!", "Dual var is string (-N)");
is(Storable::AMF3::thaw($s5), 15, "Dual var is number (+N)");


