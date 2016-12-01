#!/usr/bin/perl
#
# A simple script to extract an diff the text coming from a google test expect
# output.
if (
    (
        do { local $/; <STDIN> }
    ) =~ /Actual: "(?<a>.*)".*\n.*\nWhich is: "(?<e>.*)".*/m
  )
{
    my $e = $+{e};
    open my $f, '>', '/tmp/actual';
    if ( ( my $aw = $+{a} ) =~ s/(.{0,60})/$1\n/g ) { print $f $aw; }
    open my $f, '>', '/tmp/expected';
    if ( ( my $ew = $e ) =~ s/(.{0,60})/$1\n/g ) { print $f $ew; }
}
`xxdiff /tmp/actual /tmp/expected`
