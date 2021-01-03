<?php
session_start();

if (!array_key_exists("dbpass", $_SESSION))
database_connection_error();

$db = @new mysqli("localhost", "cucminq", $_SESSION["dbpass"], "cucm");

if ($db->connect_error)
database_connection_error();

apo_eos();

$query = "SELECT ";
$query .= "UNIX_TIMESTAMP(`dateTimeOrigination`), ";
$query .= "`callingPartyNumber`, ";
$query .= "`originalCalledPartyNumber`, ";
$query .= "`finalCalledPartyNumber`, ";
$query .= "UNIX_TIMESTAMP(`dateTimeConnect`), ";
$query .= "UNIX_TIMESTAMP(`dateTimeDisconnect`), ";
$query .= "`origIpAddr`, ";
$query .= "`destIpAddr`, ";
$query .= "`huntPilotPattern` ";

$query .= "FROM `cdr` WHERE 1 = 1 ";

if ($_POST["calling"])
$query .= "AND `callingPartyNumber` LIKE '" . $db->real_escape_string($_POST["calling"]) . "' ";

if ($_POST["called"])
$query .= "AND `originalCalledPartyNumber` LIKE '" . $db->real_escape_string($_POST["called"]) . "' ";

if ($apo)
$query .= "AND `dateTimeOrigination` >= '" . $apo . " 00:00:00' ";

if ($eos)
$query .= "AND `dateTimeOrigination` < '" . $eos . " 00:00:00' ";

$query .= "ORDER BY `dateTimeOrigination` DESC";

if ($_POST["orio"])
$query .= "LIMIT " . ($_POST["orio"] + 1);

$res = $db->query($query);

if (!$res)
lathos("SQL:" . $query);

print '{query:"' . $query . '",data:[';

$sep = '{';
while ($row = $res->fetch_row()) {
	$nf = 0;
	printf($sep);
	printf("r:'%s',", $row[$nf++]);
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

function apo_eos() {
	global $db;
	global $apo;
	global $eos;

	$apo = NULL;
	$eos = NULL;

	if (!$_POST["imerominia"])
	return;

	$imerominia = $_POST["imerominia"];
	$meres = intval($_POST["meres"]);

	if (!$meres)
	$meres = 1;

	$query = "SELECT ";

	if ($meres > 0)
	$query .= "DATE_FORMAT('" . $imerominia . "', '%Y-%m-%d'), " .
		"DATE_FORMAT(DATE_ADD('" . $imerominia . "', INTERVAL " .
		$meres . " DAY), '%Y-%m-%d') ";

	else
	$query .= "DATE_FORMAT(DATE_SUB('" . $imerominia . "', INTERVAL " .
		-$meres . " DAY),  '%Y-%m-%d'), " . "DATE_FORMAT(" .
		"DATE_ADD('" . $imerominia . "', INTERVAL 1 DAY), '%Y-%m-%d') ";

	if (!($res = $db->query($query)))
	lathos($query);

	while ($row = $res->fetch_row()) {
		$apo = $row[0];
		$eos = $row[1];
	}

	$res->close();
}

function database_connection_error() {
	unset($_SESSION["dbpass"]);
	die('{"error":"db"}');
}

function lathos($msg) {
	global $db;

	if ($db)
	$db->close();

	die('{"error":"' . $msg . '}');
}
?>
