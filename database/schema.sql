-------------------------------------------------------------------------------@

\! [ -w /dev/tty ] && echo "Creating database…" >/dev/tty

-- (Re)create the "cucm" database.

DROP DATABASE IF EXISTS `cucm`
;

CREATE DATABASE `cucm`
DEFAULT CHARSET = utf8
DEFAULT COLLATE = utf8_general_ci
;

-- Select "cucm" database as the default database.

USE `cucm`
;

COMMIT WORK
;

-------------------------------------------------------------------------------@

\! [ -w /dev/tty ] && echo "Creating tables…" >/dev/tty


CREATE TABLE `arxio` (
	`kodikos`	CHARACTER(32) NOT NULL COMMENT 'Κωδικός αρχείου',
	`onomasia`	VARCHAR(1024) NOT NULL COMMENT ' Όνομα αρχείου',

	PRIMARY KEY (
		`kodikos`
	) USING HASH,

	UNIQUE (
		`onomasia`
	) USING BTREE
)

ENGINE = InnoDB
COMMENT = 'Πίνακας αρχείων CDR'
;

-- Ο πίνακας "cdr" περιέχει τα CDRs που παρέχει ο CUCM στον server υποδοχής.
-- Τα ονόματα των πεδίων είναι ταυτόσημα με αυτά που περιγράφονται με αυτά
-- που χρησιμοποιεί ο CUCM.

CREATE TABLE `cdr` (
	`arxio`					CHARACTER(32) NOT NULL,
	`lineno`				INT UNSIGNED NOT NULL,
	`globalCallID_callManagerId`		INT UNSIGNED NOT NULL DEFAULT 0,
	`globalCallID_callId`			INT UNSIGNED NOT NULL DEFAULT 0,
	`dateTimeOrigination`			TIMESTAMP NOT NULL,
	`origNodeId`				INT UNSIGNED NOT NULL DEFAULT 0,
	`origIpAddr`				CHAR(15) NOT NULL DEFAULT '',
	`callingPartyNumber`			VARCHAR(52) NOT NULL DEFAULT '',
	`callingPartyUnicodeLoginUserID`	VARCHAR(130) NOT NULL DEFAULT '',
	`destIpAddr`				CHAR(15) NOT NULL DEFAULT '',
	`originalCalledPartyNumber`		VARCHAR(52) NOT NULL DEFAULT '',
	`finalCalledPartyNumber`		VARCHAR(52) NOT NULL DEFAULT '',
	`dateTimeConnect`			TIMESTAMP NULL DEFAULT NULL,
	`dateTimeDisconnect`			TIMESTAMP NULL DEFAULT NULL,
	`huntPilotPattern`			VARCHAR(52) NOT NULL DEFAULT '',

	INDEX (
		`arxio`,
		`lineno`
	) USING BTREE,

	INDEX (
		`dateTimeOrigination`
	) USING BTREE,

	INDEX (
		`callingPartyNumber`
	) USING BTREE,

	INDEX (
		`originalCalledPartyNumber`
	) USING BTREE
)

ENGINE = InnoDB
COMMENT = 'Πίνακας CDRs'
;

COMMIT WORK;

-------------------------------------------------------------------------------@

\! [ -w /dev/tty ] && echo "Creating relations…" >/dev/tty

ALTER TABLE `cdr` ADD FOREIGN KEY (
	`arxio`
) REFERENCES `arxio` (
	`kodikos`
) ON UPDATE CASCADE ON DELETE CASCADE
;

COMMIT WORK
;

-------------------------------------------------------------------------------@

\! [ -w /dev/tty ] && echo "Creating users…" >/dev/tty

-- Create user for generic DQL/DML access to "cucm" database.

DROP USER IF EXISTS 'cucmadm'@'localhost'
;

CREATE USER 'cucmadm'@'localhost' IDENTIFIED BY '__PASSADM__'
;

GRANT SELECT, INSERT, UPDATE, DELETE ON `cucm`.* TO 'cucmadm'@'localhost'
;

-- Create user for generic DQL access to "cucm" database.

DROP USER IF EXISTS'cucminq'@'localhost'
;

CREATE USER 'cucminq'@'localhost' IDENTIFIED BY '__PASSINQ__'
;

GRANT SELECT ON `cucm`.* TO 'cucminq'@'localhost'
;

COMMIT WORK
;
