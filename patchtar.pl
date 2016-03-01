#! /usr/bin/perl

use strict;
use warnings;

use POSIX qw(ceil);
use Data::Dumper;

my $manifest;
open($manifest, "<", $ARGV[0]) or die "can't open $ARGV[0]: $!";

my $buf;
my $skip=0;
while(read(STDIN, $buf, 512) == 512) {
	if($skip > 0) {
		print $buf;
		$skip--;
		next;
	}
	my @data = unpack('Z100Z8Z8Z8Z12Z12Z8Z1Z100Z6Z2Z32Z32Z8Z8Z155', $buf);
	my ($name, $mode, $uid, $gid, $size, $mtime, $chksum, $typeflag,
		$linkname, $magic, $version, $uname, $gname, $devmajor, $devminor,
		$prefix) = @data;
	
	if(($typeflag eq "\0") || ($magic ne 'ustar ')) {
		print $buf;
		next;
	}

	my $line = <$manifest>;
	chomp $line;

	my ($newmode, $newuid, $newgid, $newmtime, $newuname, $newgname, $fname)
		= split(/ /, $line, 7);
	
	die "line [$line] broken / file mismatch, expected $name" 
		unless($fname eq $name);

	#printf("$mode $uid $gid $mtime $uname/$gname $name\n");
	$data[1] = $newmode;
	$data[2] = $newuid;
	$data[3] = $newgid;
	$data[5] = $newmtime;
	$data[6] = ' ' x 8;
	$data[11] = $newuname;
	$data[12] = $newgname;
	my $out = pack('a100a8a8a8a12a12a8a1a100a6a2a32a32a8a8a155', @data);
	my $sum = 0;
	map { $sum += $_ } unpack('C*', $out);
	$data[6] = sprintf("%06o\0 ", $sum);
	$out = pack('a100a8a8a8a12a12a8a1a100a6a2a32a32a8a8a155', @data);

	my $outlen = length($out);
	die "invalid length $outlen" unless $outlen == 500;
	$out .= "\0" x 12;
	print $out;
	
	$size = oct($size);
	if($size > 0) {
		$skip = ceil($size / 512);
	}
}

