use lib 't';
use ExtUtils::testlib;
use Storable::AMF3 qw(freeze thaw ref_lost_memory ref_clear);
use Scalar::Util qw(refaddr);
use GrianUtils qw(ref_mem_safe);
use strict;
use warnings;
no warnings 'once';
use Data::Dumper;
our $msg;
sub tt(&);
sub tt(&){
    my $sub = shift;
    my $s = ref_mem_safe( $sub );
    $msg = $s;
    return $s if $s;
    return undef;
}


my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->list_content($directory);

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
		
		my $obj = eval $eval;
        use strict;

        my $freeze = $image_amf3;        
        my $a1 = $freeze.'0';
        my $a2 = $freeze;
        chop ($a2);
        
        ok(tt { my $a = thaw ( $a1 );},  "thaw $item extra - $msg");
        ok(tt { my $a = thaw ( $a2 );},  "thaw without one char $item - $msg");
}


