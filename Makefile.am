ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

NULL=

SUBDIRS= \
	lxsession \
	lxsession-edit \
	lxsession-logout \
	po \
	man \
	data \
	$(NULL)

scripts=     lxlock
bin_SCRIPTS= $(scripts)

EXTRA_DIST = \
	$(scripts) \
	$(image_DATA) \
	$(NULL)
