<?php
session_start();

if (@$_SESSION["dbpass"]) {
	header('Location: inquire.php');
	exit(0);
}
?>

<html>
<head>
<title>CDR-Login</title>
<link rel="icon" type="image/png" href="images/cdr.png">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
<script>
"use strict";

const cdr = {};

$(document.body).ready(() => {
	cdr.passDOM = $('#pass').focus();
	cdr.formaDOM = $('#forma').
	on('submit', function() {
		$.post({
			"url": "isodos.php",
			"method": "POST",
			"data": {
				"pass": cdr.passDOM.val(),
			},
			"success": (rsp) => {
				if (rsp)
				cdr.passDOM.select().focus();

				else
				self.location = 'inquire.php';
			},
			"error": (err) => {
				cdr.passDOM.focus();
			},
		});

		return false;
	});
});
</script>
</head>

<body>
<form id="forma">
<p>
<label for="pass">Password</label>
<input id="pass" type="password" size="10">
</p>
<p>
<input type="submit" value="Submit">
</p>
</form>
</body>
</html>
