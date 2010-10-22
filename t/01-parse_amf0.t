use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve);
use GrianUtils;
use Data::Dumper;
my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->list_content($directory);
my $total = @item*4;
#1) defined freeze
#2) defind  thaw freeze
#3) is_deeply thaw freeze
#4) is types are equal
eval "use Test::More tests=>$total;";
warn $@ if $@;

for my $item (@item){
	my $form  = GrianUtils->read_pack($directory, $item);
    my $eval = $form->{eval};
	no strict;
	eval $eval;
	die $@ if $@;
}
TEST_LOOP: for my $item (@item){
    my $packet = GrianUtils->read_pack($directory, $item);
    my ($image_amf3, $image_amf0, $eval) = @$packet{qw(amf3 amf0 eval)};
	if ($eval =~m/use\s+utf8/) {
		SKIP: {
			no strict;
			skip("utf8 convert is not supported mode", 4);
		}
	}
	else {
		no strict;
		
		my $obj = eval $eval;
		my $new_obj;
		ok(defined(Storable::AMF0::freeze($obj)), "defined ($item) $eval");
		ok(defined(Storable::AMF0::thaw(Storable::AMF0::freeze($obj)) xor not defined $obj), "full duplex $item");
		is_deeply($new_obj = Storable::AMF0::thaw($image_amf0), $obj, "thaw name: ". $item. "(amf0):\n\n".$eval) 
		   or print STDERR Data::Dumper->Dump([$new_obj, $obj, unpack("H*", $image_amf0)]);
		is(ref $new_obj, ref $obj, "type of: $item :: $eval");
	}
}


