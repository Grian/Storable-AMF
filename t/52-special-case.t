use ExtUtils::testlib;
use lib 't';
use strict;
use warnings;
use Storable::AMF0 qw(freeze thaw);
use Data::Dumper;
use Test::More tests=>4;
my @r = ();


eval{
    thaw(undef);
};
ok($@);
eval{
    Storable::AMF3::thaw(undef);
};
ok($@);
eval {
    my $s = chr(300);
    #print Dumper($s, utf8::is_utf8($s), utf8::is_utf8(chr(15)));
    Storable::AMF0::thaw(chr(300));
    #print Dumper($@);
};
ok($@);
eval {
    my $s = chr(300);
    #print Dumper($s, utf8::is_utf8($s), utf8::is_utf8(chr(15)));
    Storable::AMF0::thaw(chr(300));
    #print Dumper($@);
};
ok($@);
*{TODO} = *Test::More::TODO;
