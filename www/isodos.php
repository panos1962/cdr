<?php
session_start();

if (array_key_exists("dbaccess", $_SESSION))
unset($_SESSION["dbaccess"]);

$conn = @new mysqli("localhost", "cucminq", $_POST["pass"], "cucm");

if ($conn->connect_error)
die("ERROR");

$conn->close();
$_SESSION["dbaccess"] = TRUE;
?>
