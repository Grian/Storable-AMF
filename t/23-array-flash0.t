use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 ();
use GrianUtils;

my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->list_content($directory, qr/^25-/);

my $total = @item*3;
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
	my $pob;
	{{
		no strict;
		$pob = eval $eval;
	 }};
	
	is_deeply(unpack("H*", Storable::AMF3::freeze( $pob)), unpack( "H*",$image_amf3), "name: ". $item.":".$eval);
	is_deeply(Storable::AMF3::thaw($image_amf3), $pob, "thaw name: ". $item. ":".$eval);

# AMF0 array compressed differently
#is_deeply(unpack("H*", Storable::AMF0::freeze( $pob )), unpack( "H*",$image_amf0), "name: ". $item.":".$eval);

	is_deeply(Storable::AMF0::thaw($image_amf0), $pob, "thaw name: ". $item. ":".$eval);
}


