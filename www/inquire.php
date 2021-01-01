<?php
session_start();

if (!$_SESSION["dbaccess"]) {
	header('Location: index.php');
	exit(0);
}
?>

<html>

<head>

<style>

#logout {
	float: right;
	margin: 8px;
}

</style>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>

<script>

cdr = {};

$(document.body).ready(() => {
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
});

</script>

<style>
</style>

</head>

<body>
<input id="logout" type="button" value="Logout">
</body>

</html>
