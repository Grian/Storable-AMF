use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
use GrianUtils;
use Data::Dumper;
my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->list_content($directory);

my $total = @item*8;
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

        my $freeze = freeze $obj;        
        my $a1 = $freeze;
        my $a2 = $freeze;
        chop($a1);
        $a2.='\x01';
        
        $@=undef;
		ok(! defined(thaw ($a1)), "fail of trunked ($item) $eval");
        ok($@, "has error for trunked".$eval);
        $@= undef;
		ok(! defined(thaw ($a2)), "fail of extra   ($item) $eval");
        ok($@, "has error for extra ".$eval);

        $@=undef;
		ok(! defined(Storable::AMF3::thaw ($a1)), "fail of trunked ($item) $eval");
        ok($@, "has error for trunked".$eval);
        $@= undef;
		ok(! defined(Storable::AMF3::thaw ($a2)), "fail of extra   ($item) $eval");
        ok($@, "has error for extra ".$eval);
}


