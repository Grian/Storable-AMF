use strict;
use warnings;
use lib 't';
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
use Scalar::Util qw(dualvar);
eval 'use Test::More tests => 2;';
my $s0 = freeze dualvar(15, "Hello World!!!");
my $s3 = Storable::AMF3::freeze dualvar(15, "Hello World!!!");
is(Storable::AMF0::thaw($s0), "Hello World!!!", "Dual var is string");
is(Storable::AMF3::thaw($s3), "Hello World!!!", "Dual var is string");


