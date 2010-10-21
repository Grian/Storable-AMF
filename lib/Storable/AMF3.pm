package Storable::AMF3;
use strict;
use warnings;
use Fcntl qw(:flock);
our $VERSION = '0.80';
use subs qw(freeze thaw);
use Exporter 'import';
use Carp qw(croak);
use Storable::AMF0 ();

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = (
    'all' => [
        qw(
          freeze thaw	dclone retrieve lock_retrieve lock_store lock_nstore store nstore
          ref_clear ref_lost_memory
          deparse_amf new_amfdate perl_date
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

sub retrieve($) {
    my $file = shift;
    my $lock = shift;

    open my $fh, "<:raw", $file or croak "Can't open file \"$file\" for read.";
    flock $fh, LOCK_SH if $lock;
    my $buf;
    sysread $fh, $buf, (( sysseek $fh, 0, 2 ), sysseek $fh, 0,0)[0] ;
    return thaw($buf);
}

sub lock_retrieve($) {
    $_[1] = 1;
    goto &retrieve;
}

sub store($$) {
    my ( $object, $file, $lock ) = @_;

    my $freeze = \freeze($object);
    unless (defined $$freeze ){
        croak "Bad object";
    }
    else  {
	open my $fh, ">:raw", $file or croak "Can't open file \"$file\" for write.";
        flock $fh, LOCK_EX if $lock;
        print $fh $$freeze if defined $$freeze;
    };
}

sub lock_store($$) {
    $_[2] = 1;
    goto &store;
}
{{
    no warnings 'once';
    *nstore = \&store;
    *lock_nstore = \&lock_store;
}};
require XSLoader;
XSLoader::load( 'Storable::AMF', $VERSION );
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Storable::AMF3 - serializing/deserializing AMF3 data

=head1 SYNOPSIS

  use Storable::AMF3 qw(freeze thaw); 

  $amf3 = freeze($perl_object);
  $perl_object = thaw($amf3);

	
  # Store/retrieve to disk amf3 data
	
  store $perl_object, 'file';
  $restored_perl_object = retrieve 'file';


  use Storable::AMF3 qw(nstore freeze thaw dclone);

  
  # Advisory locking
  use Storable::AMF3 qw(lock_store lock_nstore lock_retrieve)
  lock_store \%table, 'file';
  lock_nstore \%table, 'file';
  $hashref = lock_retrieve('file');

  # Deparse one object
  use Storable::AMF0 qw(deparse_amf); 

  my( $obj, $length_of_packet ) = deparse_amf( my $bytea = freeze($a1) . freeze($a) ... );

  - or -
  $obj = deparse_amf( freeze($a1) . freeze($a) ... );

=cut

=head1 DESCRIPTION

This module is (de)serializer for Adobe's AMF3 (Action Message Format ver 3).
This is only module and it recognize only AMF3 data. 
Almost all function implemented in C for speed. 
And some cases faster then Storable( for me always)

=cut

=head1 EXPORT
  
  None by default.

=cut

=head1 FUNCTIONS
=cut

=over

=item freeze($obj) 
  --- Serialize perl object($obj) to AMF3, and return AMF data

=item thaw($amf3)
  --- Deserialize AMF data to perl object, and return the perl object

=item store $obj, $file
  --- Store serialized AMF3 data to file

=item nstore $obj, $file
  --- Same as store

=item retrieve $obj, $file
  --- Retrieve serialized AMF3 data from file

=item lock_store $obj, $file
  --- Same as store but with Advisory locking

=item lock_nstore $obj, $file
  --- Same as lock_store 

=item lock_retrieve $file
  --- Same as retrieve but with advisory locking

=item dclone $file
  --- Deep cloning data structure

=item ref_clear $obj
  --- cleaning  arrayref and hashref. (Usefull for destroing complex objects)

=item ref_lost_memory $obj
  --- test if object contain lost memory fragments inside.
  (Example do { my $a = []; @$a=$a; $a})

=item deparse_amf $bytea 
  --- deparse from bytea one item
  Return one object and number of bytes readed
  if scalar context return object

=back


=head1 LIMITATION

At current moment and with restriction of AMF0/AMF3 format referrences to scalar are not serialized,
and can't/ may not serialize tied variables.

=head1 SEE ALSO

L<Data::AMF>, L<Storable>, L<Storable::AMF3>

=head1 AUTHOR

Anatoliy Grishaev, <grian at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
=cut
