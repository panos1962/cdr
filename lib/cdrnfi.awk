#!/usr/bin/env awk -f

BEGIN {
	FS = "/"
	dbload = cdr_basedir "/bin/cdrload -r "
}

$NF !~ /^c[md]r_StandAloneCluster_0[12]_2[0-9]{11}_[0-9]+$/ {
	next
}

{
	fname = $NF

	split(fname, a, "_")

	etos = substr(a[4], 1, 4)
	minas = substr(a[4], 5, 2)

	dir = (a[1] == "cmr" ? maincmrdir : maincdrdir) "/" etos

	if (system("test -d " dir)) {
		if (system("mkdir " dir " 2>/dev/null")) {
			print progname ": " dir ": cannot create directory" >"/dev/stderr"
			exit(2)
		}
	}

	dir = dir "/" minas

	if (system("test -d " dir)) {
		if (system("mkdir " dir " 2>/dev/null")) {
			print progname ": " dir ": cannot create directory" >"/dev/stderr"
			exit(2)
		}
	}

	if ((a[1] == "cdr") && system(dbload $0 " 2>/dev/null")) {
		print progname ": " $0 ": database load failed" >"/dev/stderr"
		next
	}

	if (system("mv " $0 " " dir)) {
		print progname ": " $0 ": cannot move file" >"/dev/stderr"
		exit(2)
	}

	if (verbose)
	print $0
}
