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
.date {
	width: 18ex;
}
.button {
	margin-left: 16px;
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
	cdr.apoDOM = $('#apo');
	cdr.eosDOM = $('#eos');

	cdr.formaDOM = $('#forma').
	on('submit', () => {
		$.post({
			"url": "select.php",
			"method": "POST",
			"data": {
				"calling": cdr.callingDOM.val(),
				"called": cdr.calledDOM.val(),
				"final": cdr.finalDOM.val(),
				"apo": cdr.apoDOM.val(),
				"eos": cdr.eosDOM.val(),
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
	});

});

cdr.formatData = (x) => {
	let tableDOM = $('<tbody>');

	cdr.dataDOM.
	empty().
	append($('<table border="yes">').
	append($('<thead>').
	append($('<tr>').
	append($('<th>').text('Calling')).
	append($('<th>').text('Called')).
	append($('<th>').text('Final')).
	append($('<th>').text('Begin')).
	append($('<th>').text('End')).
	append($('<th>').text('Hunt')))).
	append(tableDOM));

	for (let i = 0; i < x.length; i++) {
		tableDOM.append($('<tr>').
		append($('<td>').text(x[i].c)).
		append($('<td>').text(x[i].o)).
		append($('<td>').text(x[i].f)).
		append($('<td>').text(x[i].b)).
		append($('<td>').text(x[i].e)).
		append($('<td>').text(x[i].h)));
	}
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
<label for="apo">From</label>
<input id="apo" class="date" type="date">
<label for="eos">To</label>
<input id="eos" class="date" type="date">
<input class="button" type="submit" value="Submit">
<input class="button" type="reset" value="Clear">
<input class="button" id="logout" type="button" value="Logout">
</form>
<div id="data">
</div>
</body>
</html>
