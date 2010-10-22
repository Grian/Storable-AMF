#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id: Build.PL 285 2008-04-17 02:36:34Z $
#
# Build.PL for Storable::AMF
#---------------------------------------------------------------------

use strict;
use warnings;

use FindBin;

#$use lib "$FindBin::Bin/tools";

use Module::Build;    # Our customized version of Module::Build
if ( $] < 5.008 ) {
    warn "perl version $] not supported";
    exit(0);
}

#~ my $ENDIAN =  unpack('S', pack('C2', 0, 1)) == 1 ? 'BIG' : 'LITTLE';
#~ my $DEFINE = "-D${ENDIAN}_END";

my $builder = Module::Build->new(
    dist_name => 'Storable-AMF',
    license   => 'perl',

    dist_abstract      => 'serializing/deserializing AMF0/AMF3 data',
    dist_author       => 'Grishaev Anatoliy  <grian@cpan.org>',
    dist_version_from => 'lib/Storable/AMF0.pm',
    requires          => {
        perl     => '5.8.0',
        XSLoader => 0,
    },

    #  extra_compiler_flags   => [ $DEFINE ],
    build_requires => {
        'File::Spec'         => 0,
        'FindBin'            => 0,
        'Module::Build'      => '0.21',
        'ExtUtils::ParseXS'  => 0,        # Had problems with 5.8.8's xsubpp
        'ExtUtils::CBuilder' => '0.15',
        'Test::More'         => 0,
    },

    # create_makefile_pl => 'passthrough',
    dynamic_config => 0,
    build_class => 'Module::Build',
    meta_merge     => {

      #~      no_index  => { directory => [ 'tools' ] },
      #~      resources => { homepage => 'http://code.google.com/p/libwin32/' },
    },
);

$builder->create_build_script();

