#!/usr/bin/env awk -f

BEGIN {
	FS = "/"
	dbload = cdr_basedir "/bin/cdrload -r "
}

cdr_invalidfname($NF) {
	next
}

lockfile() {
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
			unlockfile()
			print progname ": " dir ": cannot create directory" >"/dev/stderr"
			exit(2)
		}
	}

	dir = dir "/" minas

	if (system("test -d " dir)) {
		if (system("mkdir " dir " 2>/dev/null")) {
			unlockfile()
			print progname ": " dir ": cannot create directory" >"/dev/stderr"
			exit(2)
		}
	}

	if ((a[1] == "cdr") && system(dbload $0 " 2>/dev/null")) {
		unlockfile()
		print progname ": " $0 ": database load failed" >"/dev/stderr"
		next
	}

	if (system("mv " $0 " " dir)) {
		unlockfile()
		print progname ": " $0 ": cannot move file" >"/dev/stderr"
		exit(2)
	}

	unlockfile()

	if (verbose)
	print $0
}

# Προκειμένου να αποφύγουμε ταυτόχρονη διαχείριση των εισερχομένων αρχείων
# από περισσότερα του ενός NFI processes, «κλειδώνουμε» το εκάστοτε ανά
# χείρας file.

function lockfile(				lock) {
	lock = $0 ".lck"

	# Αν υπάρχει ήδη το κλείδωμα επιστρέφουμε ανεπιτυχώς.

	if (!system("[ -d " lock " ]"))
	return 1

	return system("mkdir " lock)
}

function unlockfile() {
	system("rmdir " $0 ".lck")
}
