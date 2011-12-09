#! /usr/bin/awk -f

BEGIN {
	i = 0
	FILEOUT = "/dev/stdout"
	l = 0;
}

{
	d = expected(i);
	if($1 != d)
		mismatch(d);

	i += 1;

	if(i == 640) {
		i = 0
		l += 1;
	}
}

function expected(i)
{
	
	if(i == 638 && $i != 0)
		return 0;
	else if(i == 639 && $i != 255)
		return 255;

	return i % 256;
}

function mismatch(e)
{
	print "Expected " e " but the value is " $1 " (line " NR ", frame line " l ")" > FILEOUT
}
