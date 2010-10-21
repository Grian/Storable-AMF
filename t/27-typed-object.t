use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
use GrianUtils;

my $directory = qw(t/AMF0);
my @item = GrianUtils->list_content($directory, qr/^27/);
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
	no strict;
	
	my $obj = eval $eval;
	my $new_obj;
	ok(defined(Storable::AMF3::freeze($obj)), "defined ($item) $eval");
	is_deeply($new_obj = Storable::AMF3::thaw($image_amf3), $obj, "thaw name: ". $item. ":".$eval);
	is(ref $new_obj, ref $obj, "type of: $item :: $eval");
}


