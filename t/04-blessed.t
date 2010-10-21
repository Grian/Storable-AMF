use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0;
eval 'use Test::More tests => 5;';

use GrianUtils;
use File::Spec;
our $TestDir = 't';
sub data{
	my $file = File::Spec->catfile( $TestDir, $_[0] );
	my @values = Storable::thaw(GrianUtils->my_readfile($file));
	if (@values> 1) {
		print STDERR "many returned values\n";
	};
	return {data =>	( @values ? $values[0] : "DEEDBEEF")};
};

sub get_file{
	my $file = File::Spec->catfile( $TestDir, $_[0] );
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
my $bank = serialize($obj);
#print STDERR Data::Dumper->Dump([$bank]), MyDump($bank), "\n";
#print STDERR MyDump(serialize({foo=>'bar'})), "\n";
my $newobj = Storable::AMF0::thaw($bank);
ok(defined($bank));
ok(defined($newobj));
is_deeply( $newobj, $obj);
ok(ref $newobj);

is(ref ($newobj), ref ($obj));
#print STDERR ref $newobj, "\n";

