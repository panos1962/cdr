all:
	(cd src/cdrawk && make)

install:
	(cd src/cdrawk && make install)

test:
	local/test.sh
