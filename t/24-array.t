use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve);
use GrianUtils;

my $total;

my $obj = '[]: [1]: [1, "Favotite world!!!", 1.5]: ["Fav", 15, "Fav"]: do {$a = []; $$a[505] = 10; $a}:
	do {my @a = (1,2,4, undef); \@a} : do {my @a = (1,2,3,4); @a = 1; \@a}:
	do {my @a; @a= \@a; \@a}:
	do {my $a; @$a=($a, $a, 1, $a); $a} ';
$obj=~s/\s+$//;

my @item = split /:\s*/, $obj;



#@item = @item[0,1,2], ;
$total = 4*@item;
eval "use Test::More tests=>$total;";
warn $@ if $@;
my $count =0 ;
(eval $_  ||  1) && $@ && die $@ foreach @item;
foreach (@item){
	my $image;
	my $obj = eval $_;
	my $new_obj;
	#ok(not $@);
	#print STDERR "$count\n";
	ok(defined($image = Storable::AMF3::freeze($obj)), "freeze: $_");
	#print STDERR "$count.freeze\n";
	ok(defined($new_obj = Storable::AMF3::thaw($image)), "defined thaw: $_");
	#print STDERR "$count.thaw\n";
	#print STDERR "#:", Data::Dumper->Dump([ unpack( "H*", $image), $new_obj]), "\n";
 	is_deeply($new_obj, $obj, "primitive: $_");
 	is(unpack( "H*", Storable::AMF3::freeze($new_obj)), unpack( "H*", $image), "test image: $_");
	#print STDERR Data::Dumper->Dump([$obj, $new_obj]), "\n";
	$count++;
}



