NULL =

bin_PROGRAMS = lxsession-logout

lxsession_logout_CFLAGS = \
	-I$(topsrcdir) \
	$(GTK_CFLAGS) \
	$(DBUS_CFLAGS) \
	-DPACKAGE_LOCALE_DIR=\"$(datadir)/locale\" \
	-DPACKAGE_DATA_DIR=\"$(datadir)\" \
	-DPACKAGE_UI_DIR="\"$(prefix)/lxsession/ui"\" \
	$(NULL)

lxsession_logout_LDADD = \
	$(GTK_LIBS) \
	$(DBUS_LIBS) \
	$(X11_LIBS) \
	$(NULL)

lxsession_logout_SOURCES= \
	dbus-interface.c \
	dbus-interface.h \
	lxsession-logout.c \
	$(NULL)
