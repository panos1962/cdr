<?php
session_start();

if (@$_SESSION["dbaccess"]) {
	header('Location: inquire.php');
	exit(0);
}
?>

<html>

<head>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>

<script>

cdr = {};

$(document.body).ready(() => {
	cdr.passDOM = $('#pass').focus();
	cdr.formaIsodosDOM = $('#formaIsodos').
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

<style>
</style>

</head>

<body>
<form id="formaIsodos">
<p>
<label for="pass">Password</label>
<input id="pass" type="password">
</p>
<p>
<input type="submit" value="Submit">
</p>
</form>
</body>

</html>
