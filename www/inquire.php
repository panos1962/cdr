<?php
session_start();

if (!$_SESSION["dbpass"]) {
	header('Location: index.php');
	exit(0);
}
?>

<html>
<head>
<title>CDR-Inquire</title>
<link rel="icon" type="image/png" href="images/cdr.png">

<style>
table, th, td {
  border-collapse: collapse;
}
tbody.overflow tr:nth-of-type(odd) {
	background-color: #ffe3d5;
}
tbody.overflow tr:nth-of-type(even) {
	background-color: #ffe9de;
}
tbody.data tr:nth-of-type(odd) {
	background-color: #ffffdd;
}
tbody.data tr:nth-of-type(even) {
	background-color: #ffffc4;
}
thead {
	border-bottom: double;
}
#logout {
	float: right;
}
.phone {
	width: 14ex;
}
.button {
	margin-right: 16px;
	cursor: pointer;
}
.busy {
	opacity: 0.5;
	cursor: not-allowed;
}
#imerominia {
	width: 19ex;
}
#meres {
	width: 10ex;
}
#orio {
	width: 10ex;
}
.sortable {
	user-select: none;
	cursor: ns-resize;
}
.count {
	padding: 0px 2px;
	text-align: right;
	color: grey;
}
#meta {
	margin-bottom: 2px;
}
#total {
	display: inline-block;
	margin-right: 8px;
	font-weight: bold;
	font-style: normal;
}
#total::after {
	content: 'records';
	margin-left: 4px;
	font-weight: normal;
	font-style: italic;
}
#minDate {
	display: inline-block;
}
#minDate::before {
	content: '[';
	margin: 4px 4px;
	color: gray;
}
#maxDate {
	display: inline-block;
}
#maxDate::before {
	content: '\2013';
	margin: 0 4px;
	color: gray;
}
#maxDate::after {
	content: ']';
	margin-left: 4px;
	color: gray;
}
#dtlock {
	width: 10ex;
}
.dateLocked {
	color: red;
}
#dateOps {
	display: inline-block;
	padding: 4px 8px;
	background-color: #FBFBFB;
	border-style: dotted;
	border-width: 1px;
	border-color: #C3C3C3;
	border-radius: 4px;
}
#dateOps .button {
	margin: 4px;
}
</style>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
<script>
"use strict";

const cdr = {};

$(document.body).
ready(function() {
	$(this).on('keydown', (e) => {
		if (e.which !== 27)
		return;

		e.stopPropagation();
		cdr.clearDOM.trigger('click');
	});

	cdr.callingDOM = $('#calling').focus();
	cdr.calledDOM = $('#called');
	cdr.finalDOM = $('#final');
	cdr.imerominiaDOM = $('#imerominia').
	on('change', function() {
		cdr.dtlockDOM.data('date', $(this).val());
		cdr.dtlockRefresh();
	});
	cdr.meresDOM = $('#meres').
	on('change', function() {
		cdr.dtlockDOM.data('meres', $(this).val());
		cdr.dtlockRefresh();
	});
	cdr.orioDOM = $('#orio');
	cdr.submitDOM = $('#submit');
	cdr.submitDOM = $('#submit');

	$('#simera').
	on('click', (e) => {
		let d = new Date();
		cdr.imerominiaDOM.val(d.getFullYear() + '-' +
			String(d.getMonth() + 1).padStart(2, '0') + '-' +
			String(d.getDate()).padStart(2, '0'));
		cdr.dateUnlock();
		cdr.dtlockRefresh();
	});

	cdr.pantaDOM = $('#panta').
	on('click', (e) => {
		cdr.imerominiaDOM.val('');
		cdr.meresDOM.val('');
		cdr.dateUnlock();
		cdr.dtlockRefresh();
	});

	cdr.dtlockDOM = $('#dtlock').
	on('click', function(e) {
		if ($(this).data('locked')) {
			cdr.imerominiaDOM.val('');
			cdr.meresDOM.val('');
			cdr.dateUnlock();
			return;
		}

		cdr.dateLock();
	});

	cdr.clearDOM = $('#clear').
	on('click', () => {
		let d;
		let m;

		if (cdr.dtlockDOM.data('locked')) {
			d = cdr.dtlockDOM.data('date');
			m = cdr.dtlockDOM.data('meres');
		}

		cdr.callingDOM.val('').focus();
		cdr.calledDOM.val('');
		cdr.finalDOM.val('');
		cdr.imerominiaDOM.val(d);
		cdr.orioDOM.val();
		cdr.meresDOM.val(m);
	});

	$('#logout').
	on('click', function() {
		$.post({
			"url": "exodos.php",
			"method": "POST",
			"success": (rsp) => {
				self.location = 'index.php';
			},
			"error": (err) => {
				alert('ERROR');
			},
		});
	});

	cdr.dataDOM = $('#data');
	cdr.formaDOM = $('#forma').
	on('submit', cdr.submit);
});

cdr.dateLock = () => {
	let x = cdr.imerominiaDOM.val();

	if (!x)
	return;

	cdr.dtlockDOM.data('date', x);
	cdr.dtlockDOM.data('meres', cdr.meresDOM.val());
	cdr.dtlockDOM.data('locked', true).addClass('dateLocked').prop('value', 'Unlock');
};

cdr.dateUnlock = () => {
	cdr.dtlockDOM.removeData('locked').removeClass('dateLocked').prop('value', 'Lock');
	cdr.dtlockDOM.prop('disabled', !cdr.imerominiaDOM.val());
	return;
};

cdr.dtlockRefresh = () => {
	let d = cdr.imerominiaDOM.val();
	cdr.dtlockDOM.prop('disabled', !d);
	return;
};

cdr.submit = () => {
	if (cdr.isBusy())
	return false;

	cdr.busySet(true);

	if (cdr.timer)
	clearTimeout(cdr.timer);
	
	cdr.dataDOM.empty();
	cdr.orio = cdr.orioDOM.val();

	$.post({
		"url": "select.php",
		"method": "POST",
		"data": {
			"calling": cdr.callingDOM.val(),
			"called": cdr.calledDOM.val(),
			"final": cdr.finalDOM.val(),
			"imerominia": cdr.imerominiaDOM.val(),
			"meres": cdr.meresDOM.val(),
			"orio": cdr.orio,
		},
		"success": (rsp) => {
			var x;

			try {
				eval('x = ' + rsp + ';');
			}
			catch (e) {
				console.error(e);
				return;
			}

			if (x.error === 'db')
			self.location = 'index.php';

			cdr.data = x.data;
			cdr.scanfix();
			cdr.formatData();
		},
		"error": (err) => {
			cdr.busySet(false);
			console.error(err);
		},
	});

	return false;
};

cdr.MIN_DATE = 0;
cdr.MAX_DATE = 999999999999;

cdr.scanfix = () => {
	let x = cdr.data;

	cdr.minDate = cdr.MAX_DATE;
	cdr.maxDate = cdr.MIN_DATE;

	for (let i = 0; i < x.length; i++) {
		// Δημιουργούμε στήλη αύξοντος αριθμού.

		x[i].i = i + 1;

		// Αφαιρούμε το μηδέν μπροστά από τον αριθμό τού
		// καλούντος για τις εισερχόμενες κλήσεις.

		if (x[i].c.match(/^0[1-9]/))
		x[i].c = x[i].c.replace(/^0/, "");

		// Υπολογίζουμε τη διάρκεια κλήσης (σε δευτερόλεπτα)
		// και την αποθηκεύουμε στο πεδίο "d".

		x[i].d = x[i].b ? x[i].e - x[i].b : 0;

 		if (x[i].r > cdr.maxDate)
		cdr.maxDate = x[i].r;

		if (x[i].r < cdr.minDate)
		cdr.minDate = x[i].r;
	}
};

cdr.formatData = () => {
	let metaDOM = $('<div>').attr('id', 'meta');

	metaDOM.
	append($('<div>').attr('id', 'total').text(cdr.data.length));

	if ((cdr.minDate !== cdr.MAX_DATE) && (cdr.maxDate !== cdr.MIN_DATE))
	metaDOM.
	append($('<div>').attr('id', 'minDate').text(cdr.datetime(cdr.minDate))).
	append($('<div>').attr('id', 'maxDate').text(cdr.datetime(cdr.maxDate)));

	cdr.tbodyDOM = $('<tbody>');

	cdr.dataDOM.
	empty().
	append(metaDOM).
	append($('<table border="yes" >').
	append($('<thead>').
	append($('<tr>').
	append($('<th>').text('#').
	addClass('sortable').
	data('order', -1).
	on('click', function(e) {
		if (cdr.isBusy())
		return;

		clearTimeout(cdr.timer);
		let ord = $(this).data('order');
		$(this).data('order', ord === 1 ? -1 : 1);
		cdr.tbodyDOM.empty();

		cdr.timer = setTimeout(() => {
			cdr.data.sort((a, b) => {
				if (a.i < b.i)
				return -ord;

				if (a.i > b.i)
				return ord;

				return 0;
			});
			cdr.formatDataPart(0);
		}, 0);
	})).
	append($('<th>').text('Calling').
	addClass('sortable').
	data('order', 1).
	on('click', function(e) {
		if (cdr.isBusy())
		return;

		clearTimeout(cdr.timer);
		let ord = $(this).data('order');
		$(this).data('order', ord === 1 ? -1 : 1);
		cdr.tbodyDOM.empty();

		cdr.timer = setTimeout(() => {
			cdr.data.sort((a, b) => {
				if (a.c < b.c)
				return -ord;

				if (a.c > b.c)
				return ord;

				if (a.o < b.o)
				return -1;

				if (a.o > b.o)
				return 1;

				return 0;
			});
			cdr.formatDataPart(0);
		}, 0);
	})).
	append($('<th>').text('Called').
	addClass('sortable').
	data('order', 1).
	on('click', function(e) {
		if (cdr.isBusy())
		return;

		clearTimeout(cdr.timer);
		let ord = $(this).data('order');
		$(this).data('order', ord === 1 ? -1 : 1);
		cdr.tbodyDOM.empty();

		cdr.timer = setTimeout(() => {
			cdr.data.sort((a, b) => {
				if (a.o < b.o)
				return -ord;

				if (a.o > b.o)
				return ord;

				if (a.c < b.c)
				return -1;

				if (a.c > b.c)
				return 1;

				return 0;
			});
			cdr.formatDataPart(0);
		}, 0);
	})).
	append($('<th>').text('Final').
	addClass('sortable').
	data('order', 1).
	on('click', function(e) {
		if (cdr.isBusy())
		return;

		clearTimeout(cdr.timer);
		let ord = $(this).data('order');
		$(this).data('order', ord === 1 ? -1 : 1);
		cdr.tbodyDOM.empty();

		cdr.timer = setTimeout(() => {
			cdr.data.sort((a, b) => {
				if (a.f < b.f)
				return -ord;

				if (a.f > b.f)
				return ord;

				if (a.c < b.c)
				return -1;

				if (a.c > b.c)
				return 1;

				return 0;
			});
			cdr.formatDataPart(0);
		}, 0);
	})).
	append($('<th>').text('Origination')).
	append($('<th>').text('Connect')).
	append($('<th>').text('Disconnect')).
	append($('<th>').text('Duration').
	addClass('sortable').
	data('order', -1).
	on('click', function(e) {
		if (cdr.isBusy())
		return;

		clearTimeout(cdr.timer);
		let ord = $(this).data('order');
		$(this).data('order', ord === 1 ? -1 : 1);
		cdr.tbodyDOM.empty();

		cdr.timer = setTimeout(() => {
			cdr.data.sort((a, b) => {
				if (a.d < b.d)
				return -ord;

				if (a.d > b.d)
				return ord;

				if (a.c < b.c)
				return -1;

				if (a.c > b.c)
				return 1;

				return 0;
			});

			// Εκιννούμε την εμφάνιση των αποτελεσμάτων από το
			// πρώτο στοιχείο του array.

			cdr.formatDataPart(0);
		}, 0);
	})).
	append($('<th>').text('Hunt')))).
	append(cdr.tbodyDOM));

	cdr.formatDataPart(0);
};

// Η function "formatDataPart" καλείται αμέσως μετά την παραλαβή των
// αποτελεσμάτων από τον server με σκοπό την εμφάνιση μέρους των αποτελεσμάτων.
// Δέχεται ως παράμετρο έναν αρχικό index του array αποτελεσμάτων και εμφανίζει
// τα αποτελέσματα από τον index αυτόν και μετά μέχρι το τέλος του array
// αποτελεσμάτων. Ωστόσο, μετά την εμφάνιση ικανού πλήθους αποτελεσμάτων,
// διακόπτει τη λειτουργία της και δρομολογεί (ασύγχρονα) την εμφάνιση των
// υπολοίπων αποτελεσμάτων προκειμένου ο browser να «πάρει ανάσα» και να
// ενημερώσει τη σελίδα με το DOM όπως έχει διαμορφωθεί μέχρι στιγμής. Όλα
// αυτά γίνονται για να έχουμε αξιοπρεπές user experience (UX).

cdr.formatDataPart = (n) => {
	let x = cdr.data;
	let count = 0;
	let orio;
	let i;

	if (n > 200)
	orio = 100;

	else if (n > 50)
	orio = 50;

	else if (orio > 10)
	orio = 10;

	else
	orio = 1;

	for (i = n; i < x.length; i++) {
		if (count++ >= orio)
		break;

		let dur = x[i].b ? x[i].e - x[i].b : '';
		let origination = cdr.datetime(x[i].r);
		let connect = cdr.datetime(x[i].b);
		let disconnect = cdr.datetime(x[i].e);

		cdr.tbodyDOM.append($('<tr>').
		append($('<td>').addClass('count').text(x[i].i)).
		append($('<td>').text(x[i].c)).
		append($('<td>').text(x[i].o)).
		append($('<td>').text(x[i].f)).
		append($('<td>').text(origination)).
		append($('<td>').text(connect)).
		append($('<td>').text(disconnect)).
		append($('<td>').text(cdr.dur2hms(x[i].d))).
		append($('<td>').text(x[i].h)));

		// Αν έχουμε ξεπεράσει το μέγιστο όριο αναζήτησης, τότε έχουμε
		// φτάσει στο τέλος των αποτελεσμάτων και διακόπτουμε με
		// overflow. Πράγματι, ο server επιστρέφει αποτελέσματα μέχρι
		// του ορίου που έχουμε θέσει αφήνοντας όμως το περιθώριο σε
		// ένα επιπλέον record προκειμένου να γνωρίζουμε εύκολα και
		// γρήγορα αν έχουμε περισσότερα αποτελέσματα από το όριο που
		// έχουμε θέσει.

		if (i >= cdr.orio) {
			cdr.tbodyDOM.addClass('overflow');
			delete cdr.timer;
			cdr.busySet(false);
			return;
		}
	}

	// Στο σημείο αυτό ελέγχουμε αν το array αποτελεσμάτων έχει εξαντληθεί,
	// οπότε διακότπουμε τη διαδικασία εμφάνισης αποτελεσμάτων.

	if (i >= x.length) {
		cdr.tbodyDOM.addClass('data');
		delete cdr.timer;
		cdr.busySet(false);
		return;
	}

	// Το array αποτελεσμάτων δεν έχει εξαντληθεί οπότε δρομολογούμε την
	// εκτύπωση των υπόλοιπων αποτελεσμάτων.

	cdr.timer = setTimeout(() => {
		cdr.formatDataPart(i);
	}, 0);
};

cdr.datetime = (t) => {
	if (!t)
	return '';

	let d = new Date(t * 1000);

	let x = String(d.getDate()).padStart(2, '0');
	t = x;

	x = String(d.getMonth() + 1).padStart(2, '0');
	t += '-' + x;

	x = d.getFullYear();
	t += '-' + x;

	x = String(d.getHours()).padStart(2, '0');
	t += ' ' + x;

	x = String(d.getMinutes()).padStart(2, '0');
	t += ':' + x;

	x = String(d.getSeconds()).padStart(2, '0');
	t += ':' + x;

	return t;
};

cdr.dur2hms = (x) => {
	let hms = '';

	if (!x)
	return hms;

	let s = x % 60;
	x = (x - s) / 60;
	let m = x % 60;
	x = (x - m) / 60;

	if (s)
	hms = s + 's';

	if (m)
	hms = m + 'm' + hms;

	if (x)
	hms = x + 'h' + hms;

	return hms;
};

cdr.busy = false;

cdr.isBusy = () => {
	return cdr.busy;
};

cdr.busySet = (onOff) => {
	cdr.busy = onOff;

	if (onOff)
	cdr.submitDOM.addClass('busy');

	else
	cdr.submitDOM.removeClass('busy');
};
</script>
</head>

<body>
<form id="forma">
<label for="calling">Calling</label>
<input id="calling" class="phone">
<label for="called">Called</label>
<input id="called" class="phone">
<label for="final">Final</label>
<input id="final" class="phone">
<label for="imerominia">Date</label>
<input id="imerominia" type="date">
<label for="meres">Days</label>
<input id="meres" type="number">
<input class="button" id="logout" type="button" value="Logout">
<hr>

<input class="button" id="submit" type="submit" value="Submit">
<input class="button" id="clear" type="button" value="Clear">
<div id="dateOps" title="Date utils">
<input class="button" id="simera" type="button" value="Today">
<input class="button" id="panta" type="button" value="Ever">
<input class="button" id="dtlock" type="button" value="Lock" disabled="yes">
</div>

<label for="orio" style="font-style: italic;">Limit</label>
<input id="orio" value="1000" type="number" step="1000" min="1000">
</form>
<div id="data">
</div>
</body>
</html>
