use strict;
use warnings;
#use ExtUtils::testlib;
use Storable::AMF0;
eval 'use Test::More tests=>1;';

my @a;$a[5] =1;
ok(Storable::AMF0::freeze(\@a));


