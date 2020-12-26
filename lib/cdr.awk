BEGIN {
	cdr_init()
}

function cdr_init(			dir, nfile, tfile, f, err, i) {
	if (!cdr_progname)
	cdr_progname = "cdr"

	if (!(cdr_basedir = ENVIRON["CDR_BASEDIR"]))
	cdr_basedir = "/var/opt/cdr"

	dir = cdr_basedir "/lib"
	nfile = "cdr.colnames"
	tfile = "cdr.coltypes"

	f = dir "/" nfile

	cdr_colcount = 0

	while ((err = (getline < f)) > 0) {
		cdr_colcount++
		cdr_colname[cdr_colcount] = $0
	}

	if (err)
	cdr_error(f ": cannot read file", 1);

	close(f)

	f = dir "/" tfile

	i = 0

	while ((err = (getline < f)) > 0) {
		i++
		cdr_coltype[i] = $0
	}

	if (err)
	cdr_error(f ": cannot read file", 1);

	close(f)

	if (i != cdr_colcount)
	cdr_error("incompatible columns/types (check files " \
		nfile " and " tfile " in " dir ")")
}

function cdr_isnumcol(i) {
	return (cdr_coltype[i] == "INTEGER")
}

function cdr_humantime(t) {
	return strftime("%d-%m-%Y %H:%M:%S", t)
}

function cdr_s2hms(x,		m, h, s) {
	s = x % 60

	x = (x - s) / 60
	m = x % 60

	h = (x - m) / 60

	x = ""

	if (h)
	x = x h "h"

	if (m)
	x = x m "m"

	if (s)
	x = x s "s"

	if (!x)
	x = "0s"

	return x
}

function cdr_error(msg, stat) {
	if (!msg)
	msg = "ERROR"

	print cdr_progname ": " msg >"/dev/stderr"

	if (stat)
	exit(stat)

	return 1
}
