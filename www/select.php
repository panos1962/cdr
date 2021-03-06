<?php
session_start();

if (!array_key_exists("id", $_POST))
lathos("missing request id");

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

$query .= "FROM `cdr` ";

if ($apo)
$query .= "USE INDEX (`dateTimeOrigination`) ";

$where = "WHERE";

if ($_POST["calling"])
where_push("`callingPartyNumber` LIKE '" . $db->real_escape_string($_POST["calling"]) . "'");

if ($_POST["called"])
where_push("`originalCalledPartyNumber` LIKE '" . $db->real_escape_string($_POST["called"]) . "'");

if ($_POST["final"])
where_push("`finalCalledPartyNumber` LIKE '" . $db->real_escape_string($_POST["final"]) . "'");

if ($apo)
where_push("`dateTimeOrigination` >= '" . $apo . " 00:00:00'");

if ($eos)
where_push("`dateTimeOrigination` < '" . $eos . " 00:00:00'");

$query .= "ORDER BY `dateTimeOrigination` ";

if ($_POST["orio"])
$query .= "LIMIT " . ($_POST["orio"] + 1);

$res = $db->query($query);

if (!$res)
lathos("SQL");

print '{"dummy":0';

if (spy_check())
print ',"spy":1';

print ',"query":"' . $query . '"';

print ',"data":[';

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
print ']';

print '}';

$res->close();
$db->close();

function where_push($cond) {
	global $query;
	global $where;

	$query .= $where . " " . $cond . " ";
	$where = "AND";
}

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
	lathos("SQL");

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

	die('{"error":"' . $msg . '"}');
}

function spy_check() {
	if (!array_key_exists("spy", $_POST))
	return FALSE;

	if (!$_POST["spy"])
	return FALSE;

	$x = file_get_contents("../local/spy.txt");

	if (sha1($_POST["spy"]) !== file_get_contents("../local/spy.txt"))
	return FALSE;

	return TRUE;
}
?>
