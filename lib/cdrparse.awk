#!/usr/bin/env awk -f

# Το παρόν awk script αποτελεί «βιβλιοθήκη» εργαλείων διαχείρισης των CDR
# files του CUCM και χρησιμοποιείται όταν διαβάζουμε τα CDR files που
# αποστέλλει ο CUCM στον server υποδοχής. Τα CDR files είναι CSV text files
# όπου κάθε γραμμή αφορά σε κάποια κλήση ή άλλη κίνηση που έγινε από ή προς
# συσκευή του δικτύου που ελέγχει ο CUCM. Οι δύο πρώτες γραμμές τους αρχείου
# αφορούν στα ονόματα και στον τύπο των στηλών του αρείου.

# Στο BEGIN section επιτελούμε σημαντικές εργασίες αρχικοποίησης όπως είναι
# ο καθορισμός του field separator και η ανάγνωση των column names και των
# column types από εξωτερικά αρχεία βιβλιοθήκης.

BEGIN {
	FS = ","
	cdr_parse_init()
	delete cdr_valid_input_files[""]
	delete cdr_invalid_input_files[""]
}

# Το πρόγραμμα διαβάζει μόνο αρχεία που έχουν αποσταλεί από τον CUCM και
# μάλιστα απευθείας από τα αρχεία αυτά και όχι με redirection. Ως εκ τούτου
# ελέγχονται κατ' αρχάς τα ονόματα των input files τα οποία πρέπει να είναι
# της μορφής "cdr_StandAloneCluster_0[12]_2[0-9]{11}_[0-9]+".

cdr_invalid_cdrfname() {
	next
}

# Κατόπιν ελέγχεται ο τύπος των records που περιέχονται στο input file. Τα
# records πρέπει να είναι CDRs και όχι CMRs.

cdr_invalid_record_type() {
	next
}

# Τέλος, πρέπει το πλήθος και ο τύπος των πεδίων να είναι τα προβλεπόμενα
# από τις προδιαγραφές.

cdr_unaccepted_columns_count() {
	next
}

# Στο σημείο αυτό έχουμε διασφαλίσει ότι το input line αφορά σε ένα CDR,
# οπότε επιχειρούμε να διαβάσουμε τις τιμές των πεδίων και να κάνουμε
# κάποιες αρχικές βελτιώσεις, π.χ. να μετατρέψουμε σε αριθμούς τις τιμές
# των αριθμητικών πεδίων, να απογυμνώσουμε τα αλφαριθμητικά πεδία από τα
# περιβάλλοντα quotes κλπ.

{
	# Αν εμφανιστεί οποιοδήποτε σφάλμα κατά το διάβασμα του CDR,
	# το record απορρίπεται.

	if (cdr_fixcolvals())
	next
}

# Η function "cdr_invalid_cdrfname" ελέγχει το όνομα του input file για
# κάθε input record. Τα CDR files που αποστέλλει ο CUCM έχουν ονομασίες
# που ακολουθούν κάποιο συγκεκριμένο pattern. Αν το όνομα του input file
# δεν πληροί τις συγκεκριμένες προδιαγραφές, το αρχείο μαρκάρεται ως
# ύποπτο και απορρίπτονται όλα τα περιεχόμενα records.
#
# Για την επιτάχυνση των ελέγχων χρησιμποιούνται δύο associative arrays
# που περιέχουν τα δεκτά και τα απαράδεκτα ονόματα των input files.

function cdr_invalid_cdrfname(			n, a) {
	if (FILENAME in cdr_valid_input_files)
	return 0

	if (FILENAME in cdr_invalid_input_files)
	return 1

	n = split(FILENAME, a, "/")

	if (cdr_validfname(a[n], "cdr")) {
		cdr_valid_input_files[FILENAME]
		return 0
	}

	cdr_error(FILENAME ": invalid input file name")
	cdr_invalid_input_files[FILENAME]
	return 1
}

# Τα CDRs έχουν στην πρώτη στήλη τον αριθμό 1, επομένως κάθε record που δεν
# πληροί αυτή την προϋπόθεση απορρίπτεται από το πρόγραμμα. Ωστόσο, τα δύο
# πρώτα records των CDR files αφορούν στα ονόματα και τους τύπους των πεδίων,
# επομένως οι δύο πρώτες γραμμές κάθε input file απορρίπτονται σιωπηρά.

function cdr_invalid_record_type() {
	if ($1 == 1)
	return 0

	if (FNR < 3)
	return 1

	return cdr_ferror($0 ": invalid CDR record type")
}

# Η global μεταβλητή "cdr_colcount" δείχνει το πλήθος των πεδίων που πρέπει
# να έχει κάθε input line (129). Γραμμές που δεν έχουν το επιθυμητό πλήθος
# πεδίων απορρίπτονται ως συντακτικά λανθασμένες.

function cdr_unaccepted_columns_count() {
	if (NF == cdr_colcount)
	return 0

	# Σε αρχεία που αφορούν στα έτη μέχρι και το 2018 υπάρχουν μόνο τα
	# πρώτα 94 πεδία, επομένως πρέπει να κάνουμε δεκτές και γραμμές με
	# 94 πεδία.

	if (NF == 94)
	return 0

	return cdr_ferror($0 ": syntax error")
}

# Η function "cdr_fixcolvals" είναι σημαντική καθώς διαβάζει ένα προς ένα
# τα πεδία του CDR και τα θέτει στις φερώνυμες μεταβλητές. Παράλληλα επιτελεί
# διορθώσεις και φιξαρίσματα στις τιμές των πεδίων, ενώ ελέγχει και σημαντικά
# στοιχεία του CDR που πρέπει να πληρούν κάποιες απαραίτητες προϋποθέσεις και
# περιορισμούς.
#
# Η function "cdr_fixcolvals" επιστρέφει μη μηδενική τιμή εφόσον το ανά
# χείρας CDR δεν είναι αποδεκτό, αλλιώς επιστρέφει μηδέν.

function cdr_fixcolvals(			i, col) {
	for (i = 1; i <= NF; i++) {
		SYMTAB[col = cdr_colname[i]] = $i

		if (cdr_isnumcol(i)) {
			SYMTAB[col] += 0
			continue
		}

		if ($i ~ /^".*"$/) {
			gsub(/(^["])|(["]$)/, "", SYMTAB[col])
			continue
		}
	}

	# Το πεδίο "dateTimeOrigination" είναι το timestamp ενεργοποίησης
	# της συσκευής, π.χ. σήκωμα ακουστικού. Αυτό το timestamp πρέπει
	# να είναι καθορισμένο.

	if (dateTimeOrigination <= 0)
	return cdr_ferror($0 ": invalid origination timestamp")

	# Το ίδιο ισχύει και για το "dateTimeDisconnect" που είναι το
	# timestamp αποσύνδεσης ή απενεργοποίησης της συσκευής. Αυτό
	# το timestamp πρέπει προφανώς να είναι μεταγενέστερο του
	# timestamp ενεργοποίησης της συσκευής.

	if (dateTimeDisconnect < dateTimeOrigination)
	return cdr_ferror($0 ": invalid disconnection timestamp")

	# Το πεδίο "dateTimeConnect" είναι το timestamp σύνδεσης, δηλαδή
	# της αποκατάστασης επικοινωνίας μεταξύ καλούντος και καλουμένου.
	# Αν υπάρχει το συγκεκριμένο timestamp και δεν είναι μηδενικό,
	# τότε θα πρέπει προφανώς να μην είναι προγενέστερο του timestamp
	# ενεργοποίησης της συσκευής και να μην είναι μεταγενέστερο του
	# timestamp αποσύνδεσης.

	if (dateTimeConnect) {
		if (dateTimeConnect < dateTimeOrigination)
		return cdr_ferror($0 ": origination/connection disorder")

		if (dateTimeConnect > dateTimeDisconnect)
		return cdr_ferror($0 ": connection/disconnection disorder")
	}

	# Μέχρι εδώ φαίνεται το CDR να είναι αποδεκτό και μπορούμε να
	# προχωρήσουμε σε περαιτέρω επεξεργασία.

	return 0
}

# Η function "cdr_parse_init" είναι function αρχικοποίησης της παρούσης
# βιβλιοθήκης και σκοπό έχει να θέσει αρχικές τιμές στα global arrays
# "cdr_colnames" και "cdr_coltypes" που δεικτοδοτούνται αριθμητικά από
# το 1 έως το προκαθορισμένο πλήθος των πεδίων των CDRs και περιέχουν
# τα ονόματα και τους τύπους των πεδίων αντίστοιχα. Παράλληλα τίθεται
# το προκαθορισμένο πλήθος πεδίων των CDRs σε 129 και ελέγχεται αν το
# πλήθος των πεδίων είναι το ίδιο στα δύο σχετικά αρχεία βιβλιοθήκης
# που ονομάζονται "cdr.colnames" και "cdr.coltypes" αντίστοιχα, και
# βρίσκονται στο directory "lib" της εφαρμογής.

function cdr_parse_init(		dir, nfile, tfile, f, err, i) {
	dir = cdr_basedir "/lib"
	nfile = "cdr.colnames"
	tfile = "cdr.coltypes"

	f = dir "/" nfile

	cdr_colcount = 0

	while ((err = (getline < f)) > 0) {
		cdr_colcount++
		cdr_colname[cdr_colcount] = $0
	}

	if (err)
	cdr_error(f ": cannot read file", 1);

	close(f)

	f = dir "/" tfile

	i = 0

	while ((err = (getline < f)) > 0) {
		i++
		cdr_coltype[i] = $0
	}

	if (err)
	cdr_error(f ": cannot read file", 1);

	close(f)

	if (i != cdr_colcount)
	cdr_error("incompatible columns/types (check files " \
		nfile " and " tfile " in " dir ")")
}

# Η function "cdr_isnumcol" δέχεται ως παράμετρο το ordinal number ενός
# πεδίου του CDR και ελέγχει αν πρόκειται για αριθμητικό πεδίο.

function cdr_isnumcol(i) {
	return (cdr_coltype[i] == "INTEGER")
}

# Το εδάφιο που ακολουθεί, κατέστη απαραίτητο από την version 5.0 του gawk
# και μετά καθώς περιορίστηκε η ευκολία δημιουργίας global μεταβλητών μέσω
# SYMTAB. Το νέο μοτίβο είναι ότι οι μεταβλητές θα πρέπει να υφίστανται πριν
# τις προσπελάσουμε μέσω του SYMTAB· μια απλή αναφορά των μεταβλητών αρκεί.

BEGIN {
	cdrRecordType
	globalCallID_callManagerId
	globalCallID_callId
	origLegCallIdentifier
	dateTimeOrigination
	origNodeId
	origSpan
	origIpAddr
	callingPartyNumber
	callingPartyUnicodeLoginUserID
	origCause_location
	origCause_value
	origPrecedenceLevel
	origMediaTransportAddress_IP
	origMediaTransportAddress_Port
	origMediaCap_payloadCapability
	origMediaCap_maxFramesPerPacket
	origMediaCap_g723BitRate
	origVideoCap_Codec
	origVideoCap_Bandwidth
	origVideoCap_Resolution
	origVideoTransportAddress_IP
	origVideoTransportAddress_Port
	origRSVPAudioStat
	origRSVPVideoStat
	destLegIdentifier
	destNodeId
	destSpan
	destIpAddr
	originalCalledPartyNumber
	finalCalledPartyNumber
	finalCalledPartyUnicodeLoginUserID
	destCause_location
	destCause_value
	destPrecedenceLevel
	destMediaTransportAddress_IP
	destMediaTransportAddress_Port
	destMediaCap_payloadCapability
	destMediaCap_maxFramesPerPacket
	destMediaCap_g723BitRate
	destVideoCap_Codec
	destVideoCap_Bandwidth
	destVideoCap_Resolution
	destVideoTransportAddress_IP
	destVideoTransportAddress_Port
	destRSVPAudioStat
	destRSVPVideoStat
	dateTimeConnect
	dateTimeDisconnect
	lastRedirectDn
	pkid
	originalCalledPartyNumberPartition
	callingPartyNumberPartition
	finalCalledPartyNumberPartition
	lastRedirectDnPartition
	duration
	origDeviceName
	destDeviceName
	origCallTerminationOnBehalfOf
	destCallTerminationOnBehalfOf
	origCalledPartyRedirectOnBehalfOf
	lastRedirectRedirectOnBehalfOf
	origCalledPartyRedirectReason
	lastRedirectRedirectReason
	destConversationId
	globalCallId_ClusterID
	joinOnBehalfOf
	comment
	authCodeDescription
	authorizationLevel
	clientMatterCode
	origDTMFMethod
	destDTMFMethod
	callSecuredStatus
	origConversationId
	origMediaCap_Bandwidth
	destMediaCap_Bandwidth
	authorizationCodeValue
	outpulsedCallingPartyNumber
	outpulsedCalledPartyNumber
	origIpv4v6Addr
	destIpv4v6Addr
	origVideoCap_Codec_Channel2
	origVideoCap_Bandwidth_Channel2
	origVideoCap_Resolution_Channel2
	origVideoTransportAddress_IP_Channel2
	origVideoTransportAddress_Port_Channel2
	origVideoChannel_Role_Channel2
	destVideoCap_Codec_Channel2
	destVideoCap_Bandwidth_Channel2
	destVideoCap_Resolution_Channel2
	destVideoTransportAddress_IP_Channel2
	destVideoTransportAddress_Port_Channel2
	destVideoChannel_Role_Channel2
	IncomingProtocolID
	IncomingProtocolCallRef
	OutgoingProtocolID
	OutgoingProtocolCallRef
	currentRoutingReason
	origRoutingReason
	lastRedirectingRoutingReason
	huntPilotPartition
	huntPilotDN
	calledPartyPatternUsage
	IncomingICID
	IncomingOrigIOI
	IncomingTermIOI
	OutgoingICID
	OutgoingOrigIOI
	OutgoingTermIOI
	outpulsedOriginalCalledPartyNumber
	outpulsedLastRedirectingNumber
	wasCallQueued
	totalWaitTimeInQueue
	callingPartyNumber_uri
	originalCalledPartyNumber_uri
	finalCalledPartyNumber_uri
	lastRedirectDn_uri
	mobileCallingPartyNumber
	finalMobileCalledPartyNumber
	origMobileDeviceName
	destMobileDeviceName
	origMobileCallDuration
	destMobileCallDuration
	mobileCallType
	originalCalledPartyPattern
	finalCalledPartyPattern
	lastRedirectingPartyPattern
	huntPilotPattern
}
