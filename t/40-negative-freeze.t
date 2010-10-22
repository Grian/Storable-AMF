use ExtUtils::testlib;
use strict;
use warnings;
use Test::More tests=>60; #'no_plan';
use Storable::AMF0 qw(freeze thaw );
use Data::Dumper;

sub my_test(){
    $@ = undef;
    ok(! defined scalar Storable::AMF3::freeze($_), ref $_);
    ok($@, "has error for3 ". ref $_);
    ok(! defined scalar Storable::AMF0::freeze($_), ref $_);
    ok($@, "has error for0 ". ref $_);
};
sub my_ok(){
    ok( defined scalar Storable::AMF0::freeze($_), $@);
    is_deeply(Storable::AMF0::thaw(Storable::AMF0::freeze $_), $_, $@);
	TODO: {
		local $TODO = "AMF3::freeze::scalar";
		my $s = defined Storable::AMF3::freeze($_);
		ok( $s  );
		is_deeply(scalar Storable::AMF3::thaw(Storable::AMF3::freeze $_ or ''), $_,);
#print Dumper(defined scalar Storable::AMF3::freeze($_));
#ok( $s , Dumper($_,$s)||'undef');
#is_deeply(Storable::AMF3::thaw(Storable::AMF3::freeze $_ or ''), $_, Dumper($_));
	}
}

my_test for sub{};
my_ok for \(my ($a, $b, $c, $d) = (undef, 'a', 1,  ));

my_test for bless sub {}, 'a';
my_test for bless \my $e, 'a';
my_test for \*freeze;
my_test for bless \*freeze, 'a';

my $f = \ my $z;

my_ok for \$f;
my_test for bless \$f, 'a';
my_test for qr/\w+/;
my_test for bless qr/\w+/, 'a';
my_test for *STDERR{IO};
my_test for bless *STDERR{IO}, 'a';



