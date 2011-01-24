#===============================================================================
#
#         FILE:  69-to-experimental.t
#===============================================================================

use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0;
use Storable::AMF::Mapper;
eval 'use Test::More tests => 4;';

sub serialize{
	my $mapper = Storable::AMF::Mapper->new(to_amf=>1);
	my @values = Storable::AMF0::freeze($_[0], $mapper);
	if (@values != 1) {
		print STDERR "many returned values\n";
	}
	return $values[0];
}
package Test::ToAMF;

sub new{
	bless {foo => 'bar'};
}

sub TO_AMF {
    return { %{ $_[0] }, a => 1 };
}

package main;
sub MyDump{
	join "", map { ord >31 ? $_ : "\\x". unpack "H*", $_ }  split "", $_[0];
}
my $obj = Test::ToAMF->new();
my $bank = serialize($obj);
my $newobj = Storable::AMF0::thaw($bank);
ok(defined($bank), 'froze ok' );
ok(defined($newobj), 'thawed ok' );

my $expected = { foo => 'bar', a => 1 };
is_deeply( $newobj, $expected, 'thawed TO_AMF version');
is(ref ($newobj), 'HASH', 'TO_AMF version is unblessed' );




