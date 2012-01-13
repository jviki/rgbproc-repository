#! /usr/bin/awk -f

BEGIN {
	WIDTH  = 640
	HEIGHT = 480

	pxnum  =  0
	px[0]  = -1
	px[1]  = -1
	px[2]  = -1

	print_header()
}

NF == 3 {
	print 
}

function print_header()
{
	print "P3"
	print "640 480"
	print "255"
}
