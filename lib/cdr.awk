#!/usr/bin/env awk -f

# Το παρόν awk script αποτελεί ένα είδος «βιβλιοθήκης» λειτουργιών που
# αφορούν στη διαχείριση και στην επεξεργασία των CDRs. Εμπεριέχονται
# στη βιβλιοθήκη και functions γενικής χρήσης, π.χ. error reporting
# functions, convertion functions κλπ.
#
# Όλα τα global αντικείμενα της βιβλιοθήκης, συμπεριλαμβανομένων των
# function names εκκινούν με το πρόθεμα "cdr_" προκειμένου να αποφύγουμε
# ανεπιθύμητες διπλονομασίες. Εξαίρεση αποτελούν τα ονόματα των πεδίων
# των CDRs τα οποία χρησιμοποιούνται αυτούσια για λόγους απλότητας, αλλά
# κάτι τέτοιο δεν αναμένεται να δημιουργήσει προβλήματα καθώς τα εν λόγω
# ονόματα είναι μεγάλου μήκους και αρκετά εξειδικευμένα ώστε να συμπέσουν
# με άλλα ονόματα του awk.

# Στο BEGIN section επιτελούμε εργασίες αρχικοποίησης που αφορούν κυρίως
# στις τιμές διαφόρων global αντικειμένων της βιβλιοθήκης.

BEGIN {
	# Η global μεταβλητή "cdr_progname" χρησιμοποιείται κυρίως σε
	# μηνύματα λάθους και περιέχει το όνομα του προγράμματος το
	# οποίο τίθεται σε "cdr" εφόσον δεν έχει τεθεί.

	if (!cdr_progname)
	cdr_progname = "cdr"

	# Το directory βάσης της εφαρμογής πρέπει να έχει καθοριστεί στην
	# environment variable "CDR_BASEDIR", αλλά αν δεν έχει καθοριστεί
	# τίθεται by default σε "/var/opt/cdr".

	if (!(cdr_basedir = ENVIRON["CDR_BASEDIR"]))
	cdr_basedir = "/var/opt/cdr"
}

# Η function "cdr_humantime" δέχεται ως παράμετρο ένα timestamp και επιστρέφει
# την αντίστοιχη ημερομηνία και ώρα σε μορφή ημερομηνίας και ώρας.

function cdr_humantime(t) {
	return (t ? strftime("%d-%m-%Y %H:%M:%S", t) : "")
}

# Η function "cdr_s2hms" δέχεται ως παράμετρο ένα χρονικό διάστημα σε
# δευτερόλεπτα και επιστρέφει το διάστημα αυτό σε ώρες, λεπτά και
# δευτερόλεπτα.

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

function cdr_ferror(msg, stat) {
	cdr_error()

	if (FILENAME)
	printf FILENAME ": [" FNR "]" >"/dev/stderr"

	else
	printf "[" NR "]" >"/dev/stderr"

	printf ": " >"/dev/stderr"

	if (!msg)
	return 1

	print msg >"/dev/stderr"

	if (!stat)
	return 1

	exit(stat)
}

# Η function "cdr_error" δέχεται ως πρώτη παράμετρο ένα μήνυμα λάθους το
# οποίο εκτυπώνει στο standard error. Αν δοθεί και δεύτερη παράμετρος,
# αυτή θεωρείται exit status και το πρόγραμμα τερματίζεται με το συγκεκριμένο
# exit status.

function cdr_error(msg, stat) {
	printf cdr_progname ": " >"/dev/stderr"

	if (!msg)
	return 1

	print msg >"/dev/stderr"

	if (!stat)
	return 1

	exit(stat)
}
