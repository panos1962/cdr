<?php
session_start();

if (array_key_exists("dbpass", $_SESSION))
unset($_SESSION["dbpass"]);
?>
