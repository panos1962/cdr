#!/usr/bin/env bash

[ -z "${CDR_BASEDIR}" ] &&
export CDR_BASEDIR="/var/opt/cdr"

unset passadm

while [ -z "${passadm}" ]
do
	echo -n "password for user 'cucmadm': " >/dev/tty
	read passadm </dev/tty
done

unset passinq

while [ -z "${passinq}" ]
do
	echo -n "password for user 'cucminq': " >/dev/tty
	read passinq </dev/tty
done

sed "s;__PASSADM__;${passadm};g
s;__PASSINQ__;${passinq};g" "${CDR_BASEDIR}"/database/schema.sql | mysql -u root -p
