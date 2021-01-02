<?php
session_start();

if (array_key_exists("dbpass", $_SESSION))
unset($_SESSION["dbpass"]);

$conn = @new mysqli("localhost", "cucminq", $_POST["pass"], "cucm");

if ($conn->connect_error)
die("ERROR");

$conn->close();
$_SESSION["dbpass"] = $_POST["pass"];
?>
