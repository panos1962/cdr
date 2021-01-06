#!/usr/bin/env awk -f

# Το παρόν awk script αποτελεί ένα είδος «βιβλιοθήκης» λειτουργιών που
# αφορούν στη διαχείριση και στην επεξεργασία των αρχείων που αποστέλλει
# ο CUCM στον server υποδοχής· τα αρχεία αυτά είναι δύο ειδών: CDR και
# CMR που περιέχουν Call Detail Records και Call Management Records
# αντίστοιχα. Τόσο τα CDR όσο και τα MR files είναι CSV και εκκινούν
# αμφότερα με δύο γραμμές metadata.
#
# Το ενδιαφέρον μας περιορίζεται στα αρχεία CDR, τα οποία εκκινούν με δύο
# γραμμές metadata, ενώ το πρώτο πεδίο των υπολοίπων γραμμών έχει τιμή 1
# σε αντίθεση με τα CMRs που έχουν τιμή 2.
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

	# Η global μεταβλητή "cdr_fnamepat" περιέχει το file name pattern
	# που ταιριάζει με τα ονόματα των εισερχομένων CDR/CMR files, ως
	# regular expression. Ακολουθούν ορισμένα παραδείγματα ονομάτων
	# εισερχομένων αρχείων:
	#
	# CDR files
	# ---------
	# cdr_StandAloneCluster_02_202012260557_476630
	# cdr_StandAloneCluster_01_202012260558_476631
	# cdr_StandAloneCluster_02_202012260936_476745
	#
	# CMR files
	# ---------
	# cmr_StandAloneCluster_01_202012260632_476659
	# cmr_StandAloneCluster_02_202012260642_476662
	# cmr_StandAloneCluster_01_202012260844_476716


	cdr_fnamepat = "_StandAloneCluster_0[12]_2[0-9]{11}_[0-9]+$"
}

function cdr_validfname(fname, tipos) {
	if (!tipos)
	tipos = "c[md]r"

	return (fname ~ ("^" tipos cdr_fnamepat))
}

function cdr_invalidfname(fname, tipos) {
	return !cdr_validfname(fname, tipos)
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

# Η function "cdr_ferror" είναι παρόμοια με την function "cdr_error" τη
# διαφορά ότι εκτυπώνεται επιπλέον το όνομα του τρέχοντος input file και
# ο αρθμός τής τρέχουσας input line.

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
