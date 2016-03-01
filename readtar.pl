#! /usr/bin/perl

use strict;
use warnings;

use POSIX qw(ceil);
use Data::Dumper;

my $buf;
my $skip=0;
while(read(STDIN, $buf, 512) == 512) {
	if($skip > 0) {
		$skip--;
		next;
	}
	my @data = unpack('Z100Z8Z8Z8Z12Z12Z8ZZ100Z6Z2Z32Z32Z8Z8Z155', $buf);
	my ($name, $mode, $uid, $gid, $size, $mtime, $chksum, $typeflag,
		$linkname, $magic, $version, $uname, $gname, $devmajor, $devminor,
		$prefix) = @data;
	
	next if($typeflag eq '');
	next if($magic ne 'ustar ');

	printf("$mode $uid $gid $mtime $uname $gname $name\n");
	
	$size = oct($size);
	if($size > 0) {
		$skip = ceil($size / 512);
	}
}
