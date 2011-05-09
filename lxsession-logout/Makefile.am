bin_PROGRAMS = lxsession-logout

lxsession_logout_CFLAGS =  $(GTK_CFLAGS) $(SM_CFLAGS) $(DBUS_CFLAGS) \
			$(ADDITIONAL_FLAGS) \
			-DPACKAGE_LOCALE_DIR=\"$(datadir)/locale\" \
			-DPACKAGE_DATA_DIR=\"$(datadir)\"

lxsession_logout_LDADD = $(GTK_LIBS) $(SM_LIBS) $(DBUS_LIBS)

lxsession_logout_SOURCES= \
	dbus-interface.c \
	dbus-interface.h \
	lxsession-logout.c
