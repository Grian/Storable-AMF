use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
use GrianUtils;

my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->list_content($directory, qr/^25-/);

my $total = @item*2;
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
	
	is_deeply(unpack("H*", Storable::AMF3::freeze(eval $eval)), unpack( "H*",$image_amf3), "name: ". $item.":".$eval);
	is_deeply(Storable::AMF3::thaw($image_amf3), eval($eval), "thaw name: ". $item. ":".$eval);
}


