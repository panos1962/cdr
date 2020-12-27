BEGIN {
	OFS = ","
}

{
	printf ">>"
	printf OFS "%s", globalCallID_callManagerId
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
