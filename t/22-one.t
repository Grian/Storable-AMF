use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve);
use GrianUtils;

my $total;

my $obj = '1, 2, 3, -4, 1.5, 2.0, 4.0 , -4.25';
$obj=~s/\s+$//;

my @item = split /,\s*/, $obj;




$total = 4*@item;
eval "use Test::More tests=>$total;";
warn $@ if $@;

foreach (@item){
	my $image;
	my $obj = eval $_;
	my $new_obj;

	ok(defined($image = Storable::AMF3::freeze($obj)), "freeze: $_");
	ok(defined($new_obj = Storable::AMF3::thaw($image)), "defined thaw: $_");

	is($new_obj, $obj, "primitive: $_");
	is(unpack( "H*", Storable::AMF3::freeze($new_obj)), unpack( "H*", $image), "test image: $_");
}



