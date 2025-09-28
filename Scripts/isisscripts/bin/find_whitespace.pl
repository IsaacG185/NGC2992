#!/usr/bin/perl
use strict;

my $filename = $ARGV[0];

if(! -e $filename)
{
  print "File '$filename' does not exist\n";
  exit;
}

open(F, "< $filename");
my $i =1;
while(my $line = <>)
{
  chomp($line);
  if($line =~ /(\s+)$/)
  {
    print "jed $filename -g $i  # to remove white space '$1' at the end of the line\n";
  }
  $i++;
}
close(F);
