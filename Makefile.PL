use strict;
use ExtUtils::MakeMaker;
use File::Copy;
use Cwd;
use constant { MIN_PERL_VERSION => 5.008001 };
use Config;

my $a = eval {
    require Module::Build::Compat;
    require ExtUtils::CBuilder;
    require ExtUtils::ParseXS;
};
#~ if ( not $@ and ( $Config{osname} ne 'MSWin32' ) ) {
#~     Module::Build::Compat->run_build_pl( args => \@ARGV );
#~     Module::Build::Compat->write_makefile();
#~     exit();
#~ }

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
exit if ( @ARGV && $ARGV[0] eq '--stop' );
# Perl 5.6.2 or less not supported
if ( $] < MIN_PERL_VERSION  ) {
    print "Perl $] not supported by this module\n";
    exit(0);
}

for my $file ( 'lib/Storable/AMF.xs', 'lib/Storable/ppport.h', ){
	my $un;
	s/.*\/// for $un = $file;
	unlink $un;
	link $file, './'.$un and next;
	copy( $file, '.' );
};

our %MyModule = (
    PREREQ_PM => { 
        'Module::Build::Compat' => 0.02, 
        'Module::Build' => 0.2,
	'File::Copy'    => 0,
	'Cwd'    => 0,
        }
    ,    # e.g., Module::Name => 1.1
    #DISTVNAME => './Storable-AMF-0.65',
    ABSTRACT => 'serializing/deserializing AMF0/AMF3 data',
    AUTHOR => 'Grishaev Anatoliy  <grian@cpan.org>',
    $ExtUtils::MakeMaker::VERSION >= 6.48 ?  (MIN_PERL_VERSION => MIN_PERL_VERSION) : (),
    $ExtUtils::MakeMaker::VERSION >= 6.46 ?  (
		META_MERGE =>{
		resources => {
			'git://github.com/Grian/Storable-AMF.git',
		}
		}) : (),
    $ExtUtils::MakeMaker::VERSION >= 6.31 ?  ( LICENSE => 'perl') : (),
    NAME         => 'Storable::AMF',
    VERSION_FROM => 'lib/Storable/AMF0.pm',    # finds $VERSION
    INC    => '-I.',    # e.g., '-I. -I/usr/include/other'
                        # Un-comment this if you add C files to link with later:
			# OBJECT            => '$(O_FILES)', # link all the C files too
    OPTIMIZE  => "-O3 -pipe -fomit-frame-pointer ",
	realclean => { FILES => 'AMF.xs' },
	
);
delete $MyModule{OPTIMIZE}
  if ( $Config{osname} =~ /solaris/
    or $Config{cc} eq 'cl' );
if ( $Config{cc} eq 'gcc' ||  $Config{gccversion}) {
	if ($Config{osname}!~m/Win32/i ){
		for (   $MyModule{CCFLAGS} ){
			$_ .= ' -Wunused'; 
			$_ .= ' -Wuninitialized'; 
			$_ .= ' -Wall'; 
		#$_  .= ' -Wunreachable-code';
		#$_  .= ' -Wunsafe-loop-optimizations';
		};
	}
      #$MyModule{CCFLAGS} = '-Wunused-variable -Wunused-label -Wunused-function -Wuninitialized -Wunused-value'

}

WriteMakefile(%MyModule);

# -march=opteron -O3 -pipe -fomit-frame-pointer
