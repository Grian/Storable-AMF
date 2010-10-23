use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw);
use GrianUtils;

my $directory = qw(t/AMF0);
my @item = grep $_->{name}=~m/^27-/, GrianUtils->my_items($directory);
my $total = @item*6;
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: for my $item (@item){
    my ($name, $obj,$image_amf3, $image_amf0, $eval) = @$item{qw(name obj amf3 amf0 eval)};
	my $new_obj;
	ok(defined(Storable::AMF3::freeze($obj)), "defined ($name) $eval");
	ok(defined(Storable::AMF0::freeze($obj)), "defined ($name) $eval");
	is_deeply($new_obj = Storable::AMF3::thaw($image_amf3), $obj, "thaw name: ". $name. ":".$eval);
	is(ref $new_obj, ref $obj, "type of: $name :: $eval");
	is_deeply($new_obj = Storable::AMF0::thaw($image_amf0), $obj, "thaw name: ". $name. ":".$eval);
	is(ref $new_obj, ref $obj, "type of: $name :: $eval");
}


