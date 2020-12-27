#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>

#include <gawkapi.h>

int plugin_is_GPL_compatible;
static const gawk_api_t *api;
static awk_ext_id_t ext_id;
static const char *ext_version = "cdrawk gawk extension: version 1.0";

static awk_bool_t init_cdrawk(void);
static awk_bool_t (*init_func)(void) = init_cdrawk;

//////////////////////////////////////////////////////////////////////////////@

static awk_bool_t init_cdrawk(void) {
	return awk_true;
}

// Η function cdr_ipconvert δέχεται ως παράμετρο ένα IP όπως αυτό καταγράφεται
// από τον CUCM στα CDRs και επιστρέφει το IP σε human format. Τα IPs στα CDRs
// καταγράφονται ως signed 32-bit integer numbers.

static awk_value_t *
do_ipconvert(int nargs, awk_value_t *result, struct awk_ext_func *unused) {
	awk_value_t ipcdr;
	char ipstr[32];
	int64_t ip64;
	int32_t ip32;

	int i1;
	int i2;
	int i3;
	int i4;

	assert(result != NULL);

	if (nargs != 1)
	fatal(ext_id, "cdr_ipconvert: missing argument");

	get_argument(0, AWK_STRING, &ipcdr);

	*ipstr = '\0';

	if (sscanf(ipcdr.str_value.str, "%ld", &ip64) != 1)
	return make_const_string(ipstr, 0, result);

	if (!ip64)
	return make_const_string(ipstr, 0, result);

	if ((ip64 < (1 << 31)) || (ip64 > ~(1 << 31)))
	return make_const_string(ipstr, 0, result);

	ip32 = ip64;

	i1 = ip32 & 0xFF;
	i2 = (ip32 >> 8) & 0xFF;
	i3 = (ip32 >> 16) & 0xFF;
	i4 = (ip32 >> 24) & 0xFF;

	sprintf(ipstr, "%d.%d.%d.%d", i1, i2, i3, i4);
	return make_const_string(ipstr, strlen(ipstr), result);
}

static awk_ext_func_t func_table[] = {
	{ "cdr_ipconvert", do_ipconvert, 1, 1, awk_false, NULL },
};

//////////////////////////////////////////////////////////////////////////////@

dl_load_func(func_table, cdrawk, "")
