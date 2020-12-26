BEGIN {
	FS = ","
}

FNR <= 2 {
	next
}

NF != cdr_colcount {
	cdr_error($0 ": syntax error")
	next
}

$1 != 1 {
	cdr_error($0 ": not a CDR record")
	next
}

{
	if (fixcolvals())
	next

	if (!dateTimeConnect)
	next

printf callingPartyNumber OFS
printf cdr_humantime(dateTimeOrigination) OFS
print cdr_s2hms(dateTimeDisconnect - dateTimeConnect)
}

function fixcolvals(			i, col) {
	for (i = 1; i <= NF; i++) {
		SYMTAB[col = cdr_colname[i]] = $i

		if (cdr_isnumcol(i)) {
			SYMTAB[col] += 0
			continue
		}

		if ($i ~ /^".*"$/) {
			sub(/^["]/, "", SYMTAB[col])
			sub(/["]$/, "", SYMTAB[col])
			continue
		}
	}

	if (dateTimeOrigination <= 0)
	return cdr_error($0 ": invalid origination timestamp")

	if (dateTimeDisconnect < dateTimeOrigination)
	return cdr_error($0 ": invalid disconnection timestamp")

	if (dateTimeConnect) {
		if (dateTimeConnect < dateTimeOrigination)
		return cdr_error($0 ": origination/connection disorder")

		if (dateTimeConnect > dateTimeDisconnect)
		return cdr_error($0 ": connection/disconnection disorder")
	}
}
