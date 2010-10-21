use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0;
eval 'use Test::More tests => 16;';

use GrianUtils;
use File::Spec;
$FindBin::Bin = 't';
sub data{
	my $file = File::Spec->catfile( $FindBin::Bin, $_[0] );
	my @values = Storable::thaw(GrianUtils->my_readfile($file));
	if (@values> 1) {
		print STDERR "many returned values\n";
	};
	return {data =>	( @values ? $values[0] : "DEEDBEEF")};
};

sub get_file{
	my $file = File::Spec->catfile( $FindBin::Bin, $_[0] );
	return GrianUtils->my_readfile($file);
}

sub serialize{
	my @values = Storable::AMF0::freeze($_[0]);
	if (@values > 1) {
		print STDERR "many returned values\n";
	}
	return $values[0];
}
package Test::Bless;

sub new{
	bless {foo => 'bar'};
}

package main;
sub MyDump{
	join "", map { ord >31 ? $_ : "\\x". unpack "H*", $_ }  split "", $_[0];
}
my $obj = Test::Bless->new();
sub copy_test{
	my $val = shift;
	my $copy = Storable::AMF0::dclone($val);
	is_deeply($copy, $val);
}
#print STDERR Data::Dumper->Dump([$bank]), MyDump($bank), "\n";
#print STDERR MyDump(serialize({foo=>'bar'})), "\n";
my @objects = (undef, 0, 1, 2, 3, "hello world", "Ïðèâåò", \(my $s= "hello"), \(my $r=0), \(my $p = \(my $q)));
copy_test($_) foreach @objects;
@objects = ([], {}, [1], {a=> 2}, bless({}, "Test::Bless"), bless([], "Test::Bless"));
copy_test($_) foreach @objects;


