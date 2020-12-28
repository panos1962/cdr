@load "spawk"

BEGIN {
	OFS = " "
	spawk_verbose = 0

	spawk_sesami["dbname"] = "cucm"
	spawk_sesami["dbuser"] = "cucmadm"

	spawk_sesami["dbpassword"] = (ENVIRON["CDR_DBPASS"] ? \
		ENVIRON["CDR_DBPASS"] : "xxx")

	cdr_inserted = 0
	cdr_updated = 0
}

{
	if (mode)
	cdr_load()

	else
	cdr_print()

	if (monitor && ((NR % 1000) == 0))
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

	spawk_commit()

	if (spawk_affected == 1)
	cdr_inserted++

	else if (spawk_affected == 2)
	cdr_updated++

	return 0
}

function cdr_monitor() {
	printf "%d rows inserted, %d rows updated\n", \
		cdr_inserted, cdr_updated >"/dev/tty"
}

function cdr_print() {
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
