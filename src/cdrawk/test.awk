@load "./cdrawk"

BEGIN {
	FS = ","
}

{
	print cdr_ipconvert($8)
}
