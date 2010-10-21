use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve);
use GrianUtils;

my $total;

my $obj = '"", "Hello World", "Favotite world!!!"';
$obj=~s/\s+$//;

my @item = split /,\s*/, $obj;



@item = @item[0,1,2], ;
$total = 4*@item;
eval "use Test::More tests=>$total;";
warn $@ if $@;

foreach (@item){
	my $image;
	my $obj = eval $_;
	my $new_obj;

	ok(defined($image = Storable::AMF3::freeze($obj)), "freeze: $_");
	ok(defined($new_obj = Storable::AMF3::thaw($image)), "defined thaw: $_");
	
	#print STDERR "#:", Data::Dumper->Dump([ unpack( "H*", $image), $new_obj]), "\n";
 	is_deeply($new_obj, $obj, "primitive: $_");
 	is(unpack( "H*", Storable::AMF3::freeze($new_obj)), unpack( "H*", $image), "test image: $_");
}



