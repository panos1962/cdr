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
#logout {
	float: right;
}
.phone {
	width: 14ex;
}
.button {
	margin-left: 16px;
	cursor: pointer;
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
.data {
	background-color: #FFFFDD;
}
.overflow {
	background-color: #FFDEDE;
}
.sortable {
	user-select: none;
	cursor: ns-resize;
}
</style>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
<script>
cdr = {};

$(document.body).ready(() => {
	cdr.callingDOM = $('#calling').focus();
	cdr.calledDOM = $('#called');
	cdr.finalDOM = $('#final');
	cdr.imerominiaDOM = $('#imerominia');
	cdr.meresDOM = $('#meres');
	cdr.orioDOM = $('#orio');

	$('#clear').
	on('click', () => {
		cdr.callingDOM.val('');
		cdr.calledDOM.val('');
		cdr.finalDOM.val('');
		cdr.imerominiaDOM.val('');
		cdr.meresDOM.val('');
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

cdr.submit = () => {
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

			for (let i = 0; i < x.data.length; i++)
			x.data[i].d = x.data[i].b ? x.data[i].e - x.data[i].b : 0;

			cdr.data = x.data;
			cdr.formatData();
		},
		"error": (err) => {
			console.error(err);
		},
	});

	return false;
};

cdr.formatData = () => {
	cdr.tbodyDOM = $('<tbody>');

	cdr.dataDOM.
	empty().
	append($('<table border="yes">').
	append($('<thead>').
	append($('<tr>').
	append($('<th>').text('Calling').
	addClass('sortable').
	data('order', 1).
	on('click', function(e) {
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

			cdr.formatDataPart(0);
		}, 0);
	})).
	append($('<th>').text('Hunt')))).
	append(cdr.tbodyDOM));

	cdr.formatDataPart(0);
};

cdr.formatDataPart = (n) => {
	let i;
	let count = 0;
	let orio = (n > 200 ? 1000 : 100)
	let x = cdr.data;

	for (i = n; i < x.length; i++) {
		if (count++ >= orio)
		break;

		let dur = x[i].b ? x[i].e - x[i].b : '';
		let origination = cdr.datetime(x[i].r);
		let connect = cdr.datetime(x[i].b);
		let disconnect = cdr.datetime(x[i].e);

		cdr.tbodyDOM.append($('<tr>').
		append($('<td>').text(x[i].c)).
		append($('<td>').text(x[i].o)).
		append($('<td>').text(x[i].f)).
		append($('<td>').text(origination)).
		append($('<td>').text(connect)).
		append($('<td>').text(disconnect)).
		append($('<td>').text(cdr.dur2hms(x[i].d))).
		append($('<td>').text(x[i].h)));

		if (i >= cdr.orio) {
			cdr.tbodyDOM.addClass('overflow');
			delete cdr.timer;
			return;
		}
	}

	if (i >= x.length) {
		cdr.tbodyDOM.addClass('data');
		delete cdr.timer;
		return;
	}

	cdr.timer = setTimeout(() => {
		cdr.formatDataPart(i);
	}, 0);
};

cdr.datetime = (t) => {
	if (!t)
	return '';

	let d = new Date(t * 1000);

	let x = d.getDate();
	if (x < 10) x = '0' + x;
	t = x;

	x = d.getMonth() + 1;
	if (x < 10) x = '0' + x;
	t += '-' + x;

	x = d.getFullYear();
	t += '-' + x;

	x = d.getHours();
	if (x < 10) x = '0' + x;
	t += ' ' + x;

	x = d.getMinutes();
	if (x < 10) x = '0' + x;
	t += ':' + x;

	x = d.getSeconds();
	if (x < 10) x = '0' + x;
	t += ':' + x;

	return t;
};

cdr.dur2hms = (x) => {
	let hms = '';

	if (!x)
	return hms;

	let s = x % 60;
	x = parseInt(x / 60);
	let m = x % 60;
	x = parseInt(m / 60);

	if (s)
	hms = s + 's';

	if (m)
	hms = m + 'm' + hms;

	if (x)
	hms = x + 'h' + hms;

	return hms;
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
<label for="orio">Limit</label>
<input id="orio" value="1000" type="number" step="1000" min="1000">

<input class="button" type="submit" value="Submit">
<input class="button" id="clear" type="button" value="Clear">
<input class="button" id="logout" type="button" value="Logout">
</form>
<div id="data">
</div>
</body>
</html>
