#!/usr/bin/env awk -f

# Το παρόν αποτελεί την «καρδιά» του προγράμματος "cdrload" που χρησιμοποιείται
# για την εισαγωγή των CDRs στην database. Όλες οι παράμετροι που απαιτούνται
# για τη λειτουργία του παρόντος, περνούν ως μεταβλητές στο παρόν από το
# πρόγραμμα "cdrload".
#
# Προκειμένου να λάβουν χώρα database ενέργειες INSERT ή REPLACE στην database,
# θα πρέπει να έχει καθοριστεί το database password του χρήστη "cucmadm" στο
# environment του προγράμματος στη enviroment variable "CDR_DBPASS", π.χ.
#
#	CDR_DBPASS="xxx" cdrload -i test1 test2

@load "spawk"

BEGIN {
	OFS = " "

	spawk_verbose = 0

	spawk_sesami["dbname"] = "cucm"
	spawk_sesami["dbuser"] = "cucmadm"
	spawk_sesami["dbpassword"] = ENVIRON["CDR_DBPASS"]

	cdr_curfile = ""
	cdr_badfile = 1

	cdr_totalrows = 0
	cdr_processed = 0

	process = "cdr_" (mode ? "load" : "print")
}

{
	cdr_totalrows++
	cdr_checkfile()

	if (cdr_badfile)
	next

	@process()
	cdr_processed++

	if (monitor && ((cdr_processed % 1000) == 0)) {
		printf "%d rows processed\n", cdr_processed
		fflush()
	}
}

END {
	if (monitor)
	printf "%d total rows processed, %d rows skipped\n", \
		cdr_totalrows, cdr_totalrows - cdr_processed
	exit(0)
}

function cdr_load(mode,			a, query) {
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
		"'" cdr_curfilemd5 "', " \
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

function cdr_checkfile(			n, a) {
	n = split(FILENAME, a, "/")

	if (a[n] == cdr_curfile)
	return

	cdr_badfile = 1

	cdr_curfile = a[n]

	if (cdr_curfile !~ /^cdr_StandAloneCluster_0[12]_2[0-9]{11}_[0-9]+$/)
	return cdr_error(FILENAME ": bad file name")

	spawk_submit("SELECT MD5('" cdr_curfile "')")

	spawk_fetchone(a)
	cdr_curfilemd5 = a[1]

	if (length(cdr_curfilemd5) != 32)
	return cdr_error(FILENAME ": MD5 filename conversion failed")

	spawk_submit("SELECT `onomasia` FROM `arxio` " \
		"WHERE `kodikos` = '" cdr_curfilemd5 "'")

	if (spawk_fetchone(a)) {
		if (a[1] != cdr_curfile)
		return cdr_error(FILENAME ": MD5 filename collision");

		if (mode == "insert")
		return cdr_error(cdr_curfile ": file already loaded")

		if (spawk_submit("DELETE FROM `cdr` " \
			"WHERE `arxio` = '" cdr_curfilemd5 "'") != 2)
		return cdr_error("cannot delete CDRs for file '" cdr_curfile "'")
	}

	else {
		if (spawk_submit("INSERT INTO `arxio` (" \
			"`kodikos`, " \
			"`onomasia`" \
		") VALUES ('" cdr_curfilemd5 "', '" cdr_curfile "')") != 2)
		return cdr_error(FILENAME ": insert file failed")
	}

	cdr_badfile = 0
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
