use ExtUtils::testlib;
use strict;
use warnings;
no warnings 'once';
eval 'use Test::More tests=>24';
use Storable::AMF3 qw(freeze);
use Data::Dumper;

sub my_test(){
    $@ = undef;
    ok(! defined scalar freeze($_), ref $_);
    ok($@, "has error for ".ref $_);
};

my_test for sub{};
my_test for \my $a;
my_test for bless sub {}, 'a';
my_test for bless \my $b, 'a';
my_test for \*freeze;
my_test for bless \*freeze, 'a';

my $d = \$a;

my_test for \$d;
my_test for bless \$d, 'a';
my_test for qr/\w+/;
my_test for bless qr/\w+/, 'a';
my_test for *STDERR{IO};
my_test for bless *STDERR{IO}, 'a';
