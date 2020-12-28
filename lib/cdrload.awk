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

	if (mode) {
		process = "cdr_load"

		spawk_verbose = 0
		spawk_sesami["dbname"] = "cucm"
		spawk_sesami["dbuser"] = "cucmadm"
		spawk_sesami["dbpassword"] = ENVIRON["CDR_DBPASS"]

		cdr_inserted = 0
		cdr_updated = 0
	}

	else {
		process = "cdr_print"
		monitor = 0
	}
}

{
	@process()

	if ((NR % 1000) == 0)
	cdr_monitor()
}

END {
	cdr_monitor()
	exit(0)
}

function cdr_load(			query) {
	query = mode " INTO `cdr` (" \
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

	if (spawk_affected == 1)
	cdr_inserted++

	else if (spawk_affected == 2)
	cdr_updated++

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

function cdr_monitor() {
	if (!monitor)
	return

	printf "%d rows inserted, %d rows updated\n", \
		cdr_inserted, cdr_updated
}
