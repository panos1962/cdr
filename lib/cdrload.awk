#!/usr/bin/env awk -f

# Το παρόν αποτελεί την «καρδιά» του προγράμματος "cdrload" που χρησιμοποιείται
# για την εισαγωγή των CDRs στην database. Όλες οι παράμετροι που απαιτούνται
# για τη λειτουργία του παρόντος λαμβάνονται ως awk variables μεταβλητές από
# το shell script "cdrload".
#
# Προκειμένου να λάβουν χώρα οι απαραίτητες database ενέργειες (insert, delete
# κλπ), θα πρέπει να έχει καθοριστεί το database password του χρήστη "cucmadm"
# στο environment του προγράμματος στη enviroment variable "CDR_DBPASS", π.χ.
#
#	CDR_DBPASS="xxx" cdrload -i test1 test2
#
# ή καλύτερα
#
#	export CDR_DBPASS="xxx"
#	cdrload -i test1 test2
#
# προκειμένου να μην δημοσιοποιείται το passwword μέσω της εντολής ps κλπ.
#
# Το πρόγραμμα δεν μπορεί να διαβάζει από το standard input αλλά μόνο από
# αρχεία τα ονόματα των οποίων πρέπει να πληρούν συγκεκριμένες προδιαγραφές.
# Πιο συγκεκριμένα, τα αρχεία τα οποία διαβάζει το πρόγραμμα πρέπει να έχουν
# προκύψει από τον CUCM και ως εκ τούτου τα ονόματά τους θα είναι της μορφής:
#
#	cdr_StandAloneCluster_XX_YYYYMMDDHHMM_N
#
# όπου "XX" είναι το CUCM server id, "YYYY", "MM", "DD", "HH", "MM" είναι το
# έτος, ο μήνας, η ημέρα, η ώρα και το λεπτό παραγωγής τους αρχείου, και "N"
# είναι αριθμητικό id, π.χ.
#
#	cdr_StandAloneCluster_02_202012260557_476630
#	cdr_StandAloneCluster_02_202012260558_476631
#	cdr_StandAloneCluster_02_202012260936_476745
#	cmr_StandAloneCluster_02_202012260632_476659
#	cmr_StandAloneCluster_02_202012260642_476662
#	cmr_StandAloneCluster_02_202012260844_476716
#
# Ως primary key κάθε CDR που εισάγεται στην database χρησιμοποιείται το
# όνομα του αρχείου και ο αριθμός γραμμής του CDR μέσα στο αρχείο. Ωστόσο
# τα ονόματα των αρχείων δεν εισάγονται αυτούσια αλλά μετατρέπονται σε MD5·
# αυτό γίνεται για λόγους οικονομίας.
#
# Κάθε φορά που αλλάζει το input file, το πρόγραμμα ελέγχει αν το νέο input
# file έχει ήδη εισαχθεί στην database. Αν πρόκειται για νέο αρχείο, τότε
# τα CDRs του αρχείου εισάγονται στην database. Αν όμως το αρχείο έχει ήδη
# εισαχθεί στην database, τότε το πρόγραμμα μπορεί είται να διαγράψει από
# την database τα ήδη εισαχθέντα CDRs και να τα εισαγάγει εκ νέου (replace
# mode), είτε να αγνοήσει το νέο αρχείο (insert mode).

BEGIN {
	OFS = " "

	spawk_verbose = 0

	spawk_sesami["dbname"] = "cucm"
	spawk_sesami["dbuser"] = "cucmadm"
	spawk_sesami["dbpassword"] = ENVIRON["CDR_DBPASS"]

	# Η global μεταβλητή "curfile" περιέχει ανά πάσα στιγμή το basename
	# του τρέχοντος input file.

	curfile = ""

	# Η global μεταβλητή "skipfile" δείχνει αν τα CDRs του τρέχοντος
	# input file θα εισαχθούν στον database ή όχι.

	skipfile = 1

	totalrows = 0
	rejected = 0
	processed = 0

	process = "cdr_" (dbmode ? "dbload" : "print")
}

{
	totalrows++
	cdr_checkfile()

	# Αν κατά τον έλεγχο του ονόματος του αρχείου εντοπιστεί
	# οποιοδήποτε σφάλμα, τότε τίθεται η flag "skipfile" και
	# οι εγγραφές του συγκεκριμένου αρχείου απορρίπτονται.

	if (skipfile) {
		rejected++
		next
	}

	@process()
	processed++

	if (verbose && ((processed % 1000) == 0)) {
		printf "%d rows processed\n", processed
		fflush()
	}
}

END {
	if (verbose)
	printf "%d total rows processed, total %d rows rejected\n", \
		totalrows, rejected
	exit(0)
}

function cdr_checkfile(			n, a) {
	n = split(FILENAME, a, "/")

	if (a[n] == curfile)
	return

	# Θέτουμε την global μεταβλητή "curfile" στο basename του τρέχοντος
	# input file.

	curfile = a[n]

	# Αρχικά θεωρούμε ότι το τρέχον input file δεν είναι αποδεκτό.
	# Το input file θα θεωρηθεί αποδεκτό μόνο εφόσον «περάσει» τους
	# σχετικούς ελέγχους.
	
	skipfile = 1

	if (curfile !~ /^cdr_StandAloneCluster_0[12]_2[0-9]{11}_[0-9]+$/)
	return cdr_error(FILENAME ": bad file name")

	spawk_submit("SELECT MD5('" curfile "')")

	spawk_fetchone(a)
	curfilemd5 = a[1]

	if (length(curfilemd5) != 32)
	return cdr_error(FILENAME ": MD5 filename conversion failed")

	# Στο σημείο αυτό, το όνομα του αρχείου έχει ελεγχθεί και είναι
	# αποδεκτό. Επομένως είναι η κατάλληλη στιγμή να ελεγχθεί αν τα
	# CDRs του εν λόγω αρχείου έχουν ήδη εισαχθεί στην database,
	# ενδεχομένως σε παλαιότερη εισαγωγή. Ελέγχουμε λοιπόν αν το
	# όνομα του αρχείου βρίσκεται ήδη καταχωρημένο στην database.

	spawk_submit("SELECT `onomasia` FROM `arxio` " \
		"WHERE `kodikos` = '" curfilemd5 "'")

	# Αν το αρχείο είναι ήδη καταχωρημένο στην database θα πρέπει
	# να γίνουν περαιτέρω έλεγχοι που αφορούν σε ανεπιθύμητα MD5
	# collisions κλπ.

	if (spawk_fetchone(a)) {
		# Αν το όνομα του ήδη εισαχθέτος αρχείου δεν είναι ίδιο
		# με το όνομα του τρέχοντος input file, τότε έχουμε MD5
		# collision και αυτή είναι μια κατάσταση που το πρόγραμμα
		# δεν αντιμετωπίζει επαρκώς.

		if (a[1] != curfile)
		return cdr_error(FILENAME ": ERROR: " curfilemd5 \
			": MD5 filename collision (file rejected)");

		# Το αρχείο που έχει ήδη εισαχθεί φέρει το ίδιο όνομα με
		# το τρέχον input file, επομένως είναι απολύτως λογικό να
		# θεωρήσουμε ότι πρόκειται για το ίδιο αρχείο το οποίο έχει
		# εισαχθεί στην database σε προγενέστερο χρόνο. Σ' αυτήν την
		# περίπτωση θα πρέπει είτε να προσπεράσουμε τα δεδομένα τού
		# τρέχοντος input file (insert mode)…

		if (dbmode == "insert")
		return cdr_error(FILENAME ": file already loaded")

		# …είτε να διαγράψουμε τα παλαιά CDRs από την database και
		# να προχωρήσουμε στην εισαγωγή των νέων CDRs από το τρέχον
		# input file.

		if (dbmode && spawk_submit("DELETE FROM `cdr` " \
			"WHERE `arxio` = '" curfilemd5 "'") != 2)
		return cdr_error(FILENAME ": cannot delete old CDRs for file")
	}

	# Αν το τρέχον input file δεν έχει ήδη εισαχθεί στην database, τότε
	# το εισάγουμε τώρα εφόσον το πρόγραμμα τρέχει σε mode ενημέρωσης της
	# database.

	else if (dbmode) {
		if (spawk_submit("INSERT INTO `arxio` (" \
			"`kodikos`, " \
			"`onomasia`" \
		") VALUES ('" curfilemd5 "', '" curfile "')") != 2)
		return cdr_error(FILENAME ": insert file failed")
	}

	# Στο σημείο αυτό έχουν γίνει οι απαραίτητοι έλεγχοι και το τρέχον
	# input file έχει γίνει αποδεκτό.

	skipfile = 0
}

function cdr_dbload(mode,			a, query) {
	query = "INSERT INTO `cdr` (" \
		"`arxio`, " \
		"`lineno`, " \
		"`globalCallID_callManagerId`, " \
		"`globalCallID_callId`, " \
		"`dateTimeOrigination`, " \
		"`origNodeId`, " \
		"`origIpAddr`, " \
		"`callingPartyNumber`, " \
		"`callingPartyUnicodeLoginUserID`, " \
		"`destIpAddr`, " \
		"`originalCalledPartyNumber`, " \
		"`finalCalledPartyNumber`, " \
		"`dateTimeConnect`, " \
		"`dateTimeDisconnect`, " \
		"`huntPilotPattern`" \
	") VALUES (" \
		"'" curfilemd5 "', " \
		FNR ", " \
		globalCallID_callManagerId ", " \
		globalCallID_callId ", " \
		"FROM_UNIXTIME(" dateTimeOrigination "), " \
		origNodeId ", " \
		spawk_escape(cdr_ipconvert(origIpAddr)) ", " \
		spawk_escape(callingPartyNumber) ", " \
		spawk_escape(callingPartyUnicodeLoginUserID) ", " \
		spawk_escape(cdr_ipconvert(destIpAddr)) ", " \
		spawk_escape(originalCalledPartyNumber) ", " \
		spawk_escape(finalCalledPartyNumber) ", " \
		(dateTimeConnect ? "FROM_UNIXTIME(" dateTimeConnect ")" : "NULL") ", " \
		"FROM_UNIXTIME(" dateTimeDisconnect "), " \
		spawk_escape(huntPilotPattern) \
	")"

	if (spawk_submit(query) != 2) {
		print spawk_sqlerrno, spawk_sqlerror >"/dev/stderr"
		return 1
	}

	return 0
}

function cdr_print() {
	if (check)
	return

	printf "%s", globalCallID_callManagerId
	printf OFS "%s", globalCallID_callId
	printf OFS "%s", cdr_humantime(dateTimeOrigination)
	printf OFS "%s", origNodeId
	printf OFS "%s", cdr_ipconvert(origIpAddr)
	printf OFS "%s", callingPartyNumber
	printf OFS "%s", callingPartyUnicodeLoginUserID
	printf OFS "%s", cdr_ipconvert(destIpAddr)
	printf OFS "%s", originalCalledPartyNumber
	printf OFS "%s", finalCalledPartyNumber
	printf OFS "%s", cdr_humantime(dateTimeConnect)
	printf OFS "%s", cdr_humantime(dateTimeDisconnect)
	printf OFS "%s", cdr_s2hms(dateTimeDisconnect - dateTimeConnect)
	printf OFS "%s", huntPilotPattern
	print ""
}
