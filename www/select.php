<?php
session_start();

if (!array_key_exists("dbpass", $_SESSION))
database_connection_error();

$db = @new mysqli("localhost", "cucminq", $_SESSION["dbpass"], "cucm");

if ($db->connect_error)
database_connection_error();

$query = "SELECT ";
$query .= "`callingPartyNumber`, ";
$query .= "`originalCalledPartyNumber`, ";
$query .= "`finalCalledPartyNumber`, ";
$query .= "`dateTimeConnect`, ";
$query .= "`dateTimeDisconnect`, ";
$query .= "`origIpAddr`, ";
$query .= "`destIpAddr`, ";
$query .= "`huntPilotPattern` ";

$query .= "FROM `cdr` WHERE 1 = 1 ";

if ($_POST["calling"])
$query .= "AND `callingPartyNumber` LIKE '" . $db->real_escape_string($_POST["calling"]) . "' ";

if ($_POST["called"])
$query .= "AND `originalCalledPartyNumber` LIKE '" . $db->real_escape_string($_POST["called"]) . "' ";

if ($_POST["apo"])
$query .= "AND `dateTimeConnect` >= '" . $db->real_escape_string($_POST["apo"]) . " 00:00:00' ";

if ($_POST["eos"])
$query .= "AND `dateTimeConnect` <= '" . $db->real_escape_string($_POST["eos"]) . " 23:59:59' ";

$res = $db->query($query);

if (!$res)
lathos("SQL");

print '{data: [';

$sep = '{';
while ($row = $res->fetch_row()) {
	$nf = 0;
	printf($sep);
	printf("c:'%s',", $row[$nf++]);
	printf("o:'%s',", $row[$nf++]);
	printf("f:'%s',", $row[$nf++]);
	printf("b:'%s',", $row[$nf++]);
	printf("e:'%s',", $row[$nf++]);
	printf("i:'%s',", $row[$nf++]);
	printf("d:'%s',", $row[$nf++]);
	printf("h:'%s'", $row[$nf++]);
	print '}';
	$sep = ',{';
}
print ']}';

$res->close();
$db->close();

function database_connection_error() {
	unset($_SESSION["dbpass"]);
	die('{"error":"db"}');
}

function lathos($msg) {
	$db->close();
	die('{"error":"' . $msg . '}');
}
?>
