use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
use GrianUtils;
use constant test_per_item=>2;

my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->list_content($directory, qr/^26/);

my $total = @item*test_per_item;
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
	no strict;
	
	my $obj = eval $eval;
	my $new_obj;
	is_deeply(unpack("H*", Storable::AMF3::freeze($obj)), unpack( "H*",$image_amf3), "name: ". $item.":".$eval);
	is_deeply($new_obj = Storable::AMF3::thaw($image_amf3), $obj, "thaw name: ". $item. ":".$eval);
}


