#!/usr/bin/perl
# read Soft00Cmt.txt on stdin and generate two files. The name of the files
# is $1.edb and $1_dim.edb, where $1 refers to the first (and only) argument
# to this script.
#
# $1.edb will contain only those comets which might ever be brighter than
# $dimmag (set below); the remaining comets are saved in $1_dim.edb.
#
# Soft00Cmt.txt is a service of the Minor Planet Center,
# http://cfa-www.harvard.edu/iau/Ephemerides/Comets/Soft00Cmt.txt
#
# Copyright (c) 2000 Elwood Downey

# grab RCS version
$ver = '$Revision: 1.3 $';
$ver =~ s/\$//g;

# setup cutoff mag
$dimmag = 13;			# dimmest mag to be saved in "bright" file

# require exactly one arg
&usage() if (@ARGV != 1 or $ARGV[0] eq "-help");

# create files
$fnbase = $ARGV[0];
$brtfn = "$fnbase.edb";		# name of file for bright comets
open BRT, ">$brtfn" or die "Can not create $brtfn\n";
$dimfn = "$fnbase"."_dim.edb";# name of file for dim comets
open DIM, ">$dimfn" or die "Can not create $dimfn\n";

# build some common boilerplate
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime;
$year += 1900;
$mon += 1;
$from = "# Data is from http://cfa-www.harvard.edu/iau/Ephemerides/Comets\n";
$what = "# Generated by mpccomet2edb.pl $ver, (c) 2000 Elwood Downey\n";
$when = "# Processed $year-$mon-$mday $hour:$min:$sec UTC\n";

# add boilerplate to each file
print BRT "# Comets ever brighter than $dimmag.\n";
print BRT $from;
print BRT $what;
print BRT $when;
print DIM "# Comets never brighter than $dimmag.\n";
print DIM $from;
print DIM $what;
print DIM $when;

# process each Soft00Cmt.txt entry
while (<STDIN>) {
    chomp();
    next if (length() < 100);

    # build the name
    $name = &s(103, length());
    $name =~ s/[\(\)]//g;
    $name =~ s/^ *//;
    $name =~ s/ *$//;
    next if ($name eq "");

    # gather the orbital params
    $i = &s(71,79) + 0;
    $O = &s(61,69) + 0;
    $o = &s(51,59) + 0;
    $q = &s(31,39) + 0;
    $e = &s(41,49) + 0;
    $M = 0;
    $E = &s(20,21) . "/" . &s(23,29) . "/" . &s(15,18);	# Y/M/D
    $E =~ s/ //g;
    $H = &s(97,100) + 0;
    $G = &s(91,95) + 0;

    # decide whether it's ever brighter than $dimmag
    $aph = $e == 1 ? $q : $q*(1+$e)/(1-$e);
    if ($q < 1.1 && $aph > .9) {
	$fd = BRT;	# might be in the back yard some day :-)
    } else {
	$maxmag = $H + 5*&log10($q*&absv($q-1));
	$fd = $maxmag > $dimmag ? DIM : BRT;
    }

    # print, depending on eccentricity
    if ($e < .99) {
	# elliptical orbit
	# better to avoid if e is getting very close to 1
	$a = $q/(1-$e);
	print $fd "$name,e,$i,$O,$o,$a,0,$e,$M,$E,2000.0,$H,$G\n";
    } elsif ($e > 1) {
	# hyperbolic orbit
	print $fd "$name,h,$E,$i,$O,$o,$e,$q,2000.0,$H,$G\n";
    } else {
	# parabolic orbit
	print $fd "$name,p,$E,$i,$o,$q,$O,2000.0,$H,$G\n";
    }
}

# like substr($_,first,last), but one-based.
sub s
{
    substr ($_, $_[0]-1, $_[1]-$_[0]+1);
}

# return log base 10
sub log10
{
    .43429*log($_[0]);
}

# return absolute value
sub absv
{
    $_[0] < 0 ? -$_[0] : $_[0];
}

# return min of two values
sub min
{
    $_[0] < $_[1] ? $_[0] : $_[1];
}

# print usage message then die
sub usage
{
    print "Usage: $0 <base> < Soft00Cmt.txt\n";
    print "$ver\n";
    print "Purpose: convert Soft00Cmt.txt file to .edb format.\n";
    print "Creates two files:\n";
    print "  <base>.edb:     all comets ever brighter than $dimmag\n";
    print "  <base>_dim.edb: all comets never brighter than $dimmag\n";
    print "Nothing occurs on our stdout and stderr except error messages.\n";

    exit 1;
}

