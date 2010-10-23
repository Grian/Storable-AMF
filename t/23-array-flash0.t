use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 ();
use GrianUtils;

my $directory = qw(t/AMF0);
my @item ;
@item = grep $_->{name}=~m/^25-/, GrianUtils->my_items($directory);

my $total = @item*3;
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: for my $item (@item){
    my ($image_amf3, $image_amf0, $eval) = @$item{qw(amf3 amf0 eval)};
	my $name = $item->{name};
	my $pob = $item->{obj};
	
	is_deeply(unpack("H*", Storable::AMF3::freeze( $pob)), unpack( "H*",$image_amf3), "name: ". $name);
	is_deeply(Storable::AMF3::thaw($image_amf3), $pob, "thaw name: ". $name);
	is_deeply(Storable::AMF0::thaw($image_amf0), $pob, "thaw name: ". $name);
}


