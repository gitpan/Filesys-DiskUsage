package Filesys::DiskUsage;

use warnings;
use strict;

use File::Basename;

=head1 NAME

Filesys::DiskUsage - Estimate file space usage (similar to `du`)

=cut

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
        'all' => [ qw(
                        du
                ) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Filesys::DiskUsage qw/du/;

  # basic
  $total = du(qw/file1 file2 directory1/);

or

  # no recursion
  $total = du( { recursive => 0 } , <*> );

or

  # max-depth is 1
  $total = du( { 'max-depth' => 1 } , <*> );

or

  # get an array
  @sizes = du( @files );

or

  # get a hash
  %sizes = du( { 'make-hash' => 1 }, @files_and_directories );

=head1 FUNCTIONS

=head2 du

Estimate file space usage.

Get the size of files:

  $total = du(qw/file1 file2/);

Get the size of directories:

  $total = du(qw/file1 directory1/);

=head3 OPTIONS

=over 6

=item dereference

Follow symbolic links. Default is 0.

Get the size of a directory, recursively, following symbolic links:

  $total = du( { dereference => 1 } , $dir );

=item exclude => PATTERN

Exclude files that match PATTERN.

Get the size of every file except for dot files:

  $total = du( { exclude => qr/^\./ } , @files ); 

=item human-readable

Return sizes in human readable format (e.g., 1K 234M 2G)

  $total = du ( { 'human-readable' => 1 } , @files );

=item Human-readable

Return sizes in human readable format, but use powers of 1000 instead
of 1024.

  $total = du ( { 'Human-readable' => 1 } , @files );

=item make-hash

Return the results in a hash.

  %sizes = du( { 'make-hash' => 1 } , @files );

=item max-depth

Sets the max-depth for recursion. A negative number means there is no
max-depth. Default is -1.

Get the size of every file in the directory and immediate
subdirectories:

  $total = du( { 'max-depth' => 1 } , <*> );

=item recursive

Sets whether directories are to be explored or not. Set to 0 if you
don't want recursion. Default is 1. Overrides C<max-depth>.

Get the size of every file in the directory, but not directories:

  $total = du( { recursive => 0 } , <*> );

=item truncate-readable => NUMBER

Human readable formats decimal places are truncated by the value of
this option. A negative number means the result won't be truncated at
all. Default if 2.

Get the size of a file in human readable format with three decimal
places:

  $size = du( { 'human-readable' => 1 , 'truncate-readable' => 3 } , $file);

=back

=cut

sub du {
  # options
  my %config = (
    'dereference'       => 0,
    'exclude'           => undef,
    'human-readable'    => 0,
    'Human-readable'    => 0,
    'make-hash'         => 0,
    'max-depth'         => -1,
    'recursive'         => 1,
    'truncate-readable' => 2,
  );
  if (ref($_[0]) eq 'HASH') {%config = (%config, %{+shift})}
  $config{human} = $config{'human-readable'} || $config{'Human-readable'};

  my %sizes;

  # calculate sizes
  for (@_) {
    if (defined $config{exclude} and -f || -d) {
      my $filename = basename($_);
      next if $filename =~ /$config{exclude}/;
    }
    if (-l) { # is symbolic link
      if ($config{'dereference'}) { # we want to follow it
        $sizes{$_} = du( { 'recursive' => $config{'recursive'},
                           'exclude'   => $config{'exclude'},
                         }, readlink($_));
      }
      else {
        next;
      }
    }
    elsif (-f) { # is a file
      $sizes{$_} = -s;
    }
    elsif (-d) { # is a directory
      $sizes{$_} = -s;
      if ($config{recursive} && $config{'max-depth'}) {
        opendir(DIR,$_);
        my $dir = $_;
        $sizes{$_} += du( { 'recursive' => $config{'recursive'},
                            'max-depth' => $config{'max-depth'} -1,
                            'exclude'   => $config{'exclude'},
                          }, map {"$dir/$_"} grep {! /^\.\.?$/} readdir DIR );
      }
    }
  }

  # return sizes
  if ( $config{'make-hash'} ) {
    for (keys %sizes) {$sizes{$_} = _convert($sizes{$_}, %config)}

    return wantarray ? %sizes : \%sizes;
  }
  else {
    if (wantarray) {
      return map {_convert($_, %config)} @sizes{@_};
    }
    else {
      my $total = 0;
      for (values %sizes) {$total += $_}

      return _convert($total, %config);
    }
  }

}

# convert size to human readable format
sub _convert {
  defined (my $size = shift) || return undef;
  my $config = {@_};
  $config->{human} || return $size;
  my $block = $config->{'Human-readable'} ? 1000 : 1024;
  my @args = qw/B K M G/;

  while (@args && $size > $block) {
    shift @args;
    $size /= $block;
  }

  if ($config->{'truncate-readable'} > 0) {
    $size = sprintf("%.$config->{'truncate-readable'}f",$size);
  }

  "$size$args[0]";
}

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-disk-usage@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Filesys::DiskUsage
