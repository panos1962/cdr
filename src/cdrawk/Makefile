NAME = cdrawk
SOURCE = $(NAME).c
OBJECT = $(NAME).o
LIBLOC = $(NAME).so
LIBSYS = ../../lib/$(NAME).so
#CFLAGS = `mysql_config --cflags`
#LDFLAGS = `mysql_config --libs`

$(LIBLOC): $(OBJECT)
	gcc -o $(LIBLOC) -shared $(OBJECT) $(LDFLAGS)

$(OBJECT): $(SOURCE)
	gcc -fPIC -shared -c -O -g $(CFLAGS) $(SOURCE)

test: $(LIBLOC)
	gawk -f test.awk ../../local/sample_data/cdr_*

install: $(LIBSYS)

$(LIBSYS): $(LIBLOC)
	@cp $(LIBLOC) $(LIBSYS)

uninstall:
	@sudo rm -f $(LIBSYS)

cleanup:
	@rm -f $(OBJECT) $(LIBLOC)
