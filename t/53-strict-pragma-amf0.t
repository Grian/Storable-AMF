use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve ref_lost_memory);
use GrianUtils;
use Data::Dumper;
my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->list_content($directory);

my $total = @item*1;
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
    {
		no strict;
		my $obj = eval $eval;
		my $new_obj;
        if (ref_lost_memory($obj)){
            ok(! defined(thaw($image_amf0, 1)), "thaw(strict) recurrent $item");
        }
        else {
            if (defined($obj)){
                ok( defined(thaw($image_amf0, 1)) , "thaw(strict) non-recurrent $item") 
            }
            else {
                ok(1);
            }
        }
	}
}


