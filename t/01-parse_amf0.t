use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve);
use GrianUtils;
use Data::Dumper;
my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->my_items($directory);
my $total = @item*4;
#1) defined freeze
#2) defind  thaw freeze
#3) is_deeply thaw freeze
#4) is types are equal
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: for my $packet (@item){
    my ($name, $image_amf3, $image_amf0, $eval, $obj) = @$packet{qw(name amf3 amf0 eval obj)};
	if ($eval =~m/use\s+utf8/) {
		SKIP: {
			no strict;
			skip("utf8 convert is not supported mode", 4);
		}
	}
	else {
		my $new_obj;
		ok(defined(Storable::AMF0::freeze($obj)), "defined ($name) $eval");
		ok(defined(Storable::AMF0::thaw(Storable::AMF0::freeze($obj)) xor not defined $obj), "full duplex $name");
		is_deeply($new_obj = Storable::AMF0::thaw($image_amf0), $obj, "thaw name: ". $name. "(amf0):\n\n".$eval) 
		   or print STDERR Data::Dumper->Dump([$new_obj, $obj, unpack("H*", $image_amf0)]);
		is(ref $new_obj, ref $obj, "type of: $name :: $eval");
	}
}


