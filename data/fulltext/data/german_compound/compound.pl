#!/usr/bin/perl -w

# Copyright (c) 2005 Frank Wittig
# Weiﬂhuhn & Weiﬂhuhn Berlin
# may be freely distributed and modified keeping the copyright intact

use strict;
use Getopt::Std;
use IO::File;

$ENV{'PATH'} = '/bin:/usr/bin';
delete $ENV{'ENV'};
delete $ENV{'BASH_ENV'};

# import options
my %opts;
getopts('i:o:',\%opts);

my $MINLEN = 3;
my $MAXLEN = 10;

# file holen
my $INFILE  = $opts{'i'} || undef;
my $OUTFILE = $opts{'o'} || undef;
unless ($INFILE and $OUTFILE) {
  print "provide option: -i <infile>\n" unless ($INFILE);
  print "provide option: -o <outfile>\n" unless ($OUTFILE);
  exit 1;
}

# open files
my $in  = new IO::File;
my $out = new IO::File;
exit 1 unless $in->open("< $INFILE");
exit 1 unless $out->open("> $OUTFILE");

# read line of file in loop
while (my $line = <$in>) {
  if (is_dupe($line)) {
    $line =~ s/\s+$//;
    # if no / - add one
    $line = "${line}/" unless ($line =~ m/(\/)/);
    print $out "${line}z\n";
  }
  else {
    print $out $line;
  }
}

# check, if line is a dupe
sub is_dupe {
  my $string = shift;

  # extract word
  return undef unless ($string = ($string =~ m/^([a-zˆ‰¸ﬂ]+)\/?.*/i)[0]);
  # eject, if too short or long
  return undef unless (length($string) >= $MINLEN and length($string) <= $MAXLEN);
  # check number of lines
  my $count = `fgrep -i $string $INFILE | wc -l`;
  return 1 if ($count > 1);
  return undef;
}

