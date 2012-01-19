#! /usr/bin/awk -f
# Copyright (C) 2011, 2012 Jan Viktorin

BEGIN {
	width  = -1
	height = -1
	maxval = -1
	n      =  0
	pxnum  =  0
	px[0]  = -1
	px[1]  = -1
	px[2]  = -1
	total  =  0
}

END {
	print_rgb()

	if(total != 640 * 480)
		error("Invalid pixels count: " total " (should be " (640 * 480) ")")
}

# every line
{
	k = 1
}

# skip comments and empty lines
/^#/ || NF == 0 {next}

# process header
n < 4 {
	for(; k <= NF && n < 4; ++k) {
		if(n == 0) {
			format = $k
			n += 1	
		}
		else if(n == 1) {
			width = $k
			n += 1
		}
		else if(n == 2) {
			height = $k
			n += 1
		}
		else if(n == 3) {
			maxval = $k
			n += 1
		}
	}
}


# process fields
k <= NF {
	if(format != "P3")
		error("Unknown format: '" format "'");
	if(width == -1)
		error("Unknown width");
	if(height == -1)
		error("Unknown height");
	if(maxval == -1)
		error("Unknown maxval");

	for(; k <= NF; ++k) {
		print_rgb()
		px[pxnum] = $k
		pxnum += 1
	}
}

function print_rgb()
{
	if(pxnum == 3) {
		print px[0], px[1], px[2]
		pxnum = 0
		total += 1
	}
}

function error(msg)
{
	print msg > "/dev/stderr"
	exit 1
}
