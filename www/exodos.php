<?php
session_start();

if (array_key_exists("dbaccess", $_SESSION))
unset($_SESSION["dbaccess"]);
?>
