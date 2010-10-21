use ExtUtils::testlib;
use strict;
use warnings;
eval 'use Test::More tests=>30;';
use Storable::AMF0 qw(freeze thaw store retrieve);
use Data::Dumper;

sub my_test(){
    $@ = undef;
    ok(! defined scalar freeze($_), ref $_);
    ok($@, "has error for ". ref $_);
};
sub my_ok(){
    ok( defined scalar freeze($_), $@);
    is_deeply( thaw(freeze $_), $_, $@);
}

#~ store (\(my $g='a'), 't/hello');
#~ print Dumper(retrieve 't/hello');
my_test for sub{};
my_ok for \(my ($a, $b, $c, $d) = (undef, 'a', 1,  ));
my_test for bless sub {}, 'a';
my_test for bless \my $e, 'a';
my_test for \*freeze;
my_test for bless \*freeze, 'a';

my $f = \$a;

my_ok for \$f;
my_test for bless \$f, 'a';
my_test for qr/\w+/;
my_test for bless qr/\w+/, 'a';
my_test for *STDERR{IO};
my_test for bless *STDERR{IO}, 'a';



