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
</style>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
<script>
cdr = {};

$(document.body).ready(() => {
	cdr.dataDOM = $('#data');
	cdr.logoutDOM = $('#logout').
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

	cdr.callingDOM = $('#calling').focus();
	cdr.calledDOM = $('#called');
	cdr.finalDOM = $('#final');
	cdr.imerominiaDOM = $('#imerominia');
	cdr.meresDOM = $('#meres');
	cdr.orioDOM = $('#orio');

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

			cdr.formatData(x.data);
		},
		"error": (err) => {
			console.error(err);
		},
	});

	return false;
};

cdr.formatData = (x) => {
	let dom = $('<tbody>');

	cdr.dataDOM.
	empty().
	append($('<table border="yes">').
	append($('<thead>').
	append($('<tr>').
	append($('<th>').text('Calling')).
	append($('<th>').text('Called')).
	append($('<th>').text('Final')).
	append($('<th>').text('Origination')).
	append($('<th>').text('Connect')).
	append($('<th>').text('Disconnect')).
	append($('<th>').text('Duration')).
	append($('<th>').text('Hunt')))).
	append(dom));

	cdr.formatDataPart(x, 0, dom);
};

cdr.formatDataPart = (x, n, dom) => {
	let i;
	let count = 0;
	let orio = (n > 200 ? 1000 : 100)

	for (i = n; i < x.length; i++) {
		if (count++ >= orio)
		break;

		let dur = x[i].b ? x[i].e - x[i].b : '';
		let origination = cdr.datetime(x[i].r);
		let connect = cdr.datetime(x[i].b);
		let disconnect = cdr.datetime(x[i].e);

		dom.append($('<tr>').
		append($('<td>').text(x[i].c)).
		append($('<td>').text(x[i].o)).
		append($('<td>').text(x[i].f)).
		append($('<td>').text(origination)).
		append($('<td>').text(connect)).
		append($('<td>').text(disconnect)).
		append($('<td>').text(dur)).
		append($('<td>').text(x[i].h)));

		if (i >= cdr.orio) {
			dom.addClass('overflow');
			delete cdr.timer;
			return;
		}
	}

	if (i >= x.length) {
		dom.addClass('data');
		delete cdr.timer;
		return;
	}

	cdr.timer = setTimeout(() => {
		cdr.formatDataPart(x, i, dom);
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
<input id="imerominia" type="date" value="<?php echo date('Y-m-d'); ?>">
<label for="meres">Days</label>
<input id="meres" type="number">
<label for="orio">Limit</label>
<input id="orio" value="1000" type="number" step="1000" min="1000">

<input class="button" type="submit" value="Submit">
<input class="button" type="reset" value="Clear">
<input class="button" id="logout" type="button" value="Logout">
</form>
<div id="data">
</div>
</body>
</html>
