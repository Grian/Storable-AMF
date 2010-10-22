use lib 't';
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw ref_lost_memory ref_clear);
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


my @objs;
my @recurrent;
for my $item (@item){
	my $packet  = GrianUtils->read_pack($directory, $item);
    my $eval = $packet->{eval};
    my $obj;
	no strict;
	$obj = eval $eval;
	die $@ if $@;
    push @recurrent, $item if ref_lost_memory($obj);
    push @objs, $item, next if !ref_lost_memory($obj);
}
my $total = @item*1 + @objs*4 + @recurrent;
eval "use Test::More tests=>$total;";
warn $@ if $@;


TEST_LOOP: for my $item (@recurrent){
    my $packet = GrianUtils->read_pack($directory, $item);
    my ($image_amf3, $image_amf0, $eval) = @$packet{qw(amf3 amf0 eval)};
		no strict;
		my $obj = eval $eval;
        use strict;
        my $freeze = freeze $obj;        
        
        ok(tt { my $a = thaw $image_amf0, 1;; 1}, "thaw $item - $msg - recurrent");
};

TEST_LOOP: for my $item (@item){
    my $packet = GrianUtils->read_pack($directory, $item);
    my ($image_amf3, $image_amf0, $eval) = @$packet{qw(amf3 amf0 eval)};
		no strict;
		
		my $obj = eval $eval;
        use strict;

        my $freeze = freeze $obj;        
        
        # ok(tt { my $a = thaw $image_amf0;ref_clear($a); 1}, "thaw destroy $item - $msg");
        ok(tt { my $a = thaw( $image_amf0);ref_clear($a); 1}, "thaw(strict) destroy $item - $msg");
}
TEST_LOOP: for my $item (@objs){
    my $packet = GrianUtils->read_pack($directory, $item);
    my ($image_amf3, $image_amf0, $eval) = @$packet{qw(amf3 amf0 eval)};
		no strict;
		
		my $obj = eval $eval;
        use strict;

        my $freeze = freeze $obj;        
        my $a1 = $freeze;
        my $a2 = $freeze;
        
        ok(tt { my $a = thaw $image_amf0; 1}, "thaw $item - $msg");
        ok(tt { my $a = freeze $obj; 1},  "freeze $item - $msg");
        ok(tt { my $a = thaw freeze $obj;$a = undef;1},  "thaw freeze $item - $msg");
        ok(tt { my $a = freeze thaw $image_amf0;1 },  "freeze thaw $item - $msg");
}


