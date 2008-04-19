bin_PROGRAMS=lxsession

lxsession_CFLAGS = $(GLIB_CFLAGS) \
                   -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\"

lxsession_LDADD = $(GLIB_LIBS)

lxsession_SOURCES = \
    lxsession.c \
    autostart.c \
    autostart.h
