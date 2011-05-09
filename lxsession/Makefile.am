NULL=

bin_PROGRAMS = lxsession

lxsession_CFLAGS = $(GLIB_CFLAGS) $(X11_CFLAGS) \
				$(ADDITIONAL_FLAGS) \
				-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
				-Werror-implicit-function-declaration
				$(NULL)

lxsession_LDADD = $(GLIB_LIBS) $(X11_LIBS)

lxsession_SOURCES = \
	lxsession.c \
	lxsession.h \
	xdg-autostart.c \
	xdg-autostart.h \
	xevent.c \
	xevent.h \
	settings-daemon.c \
	settings-daemon.h \
	xsettings-common.h \
	xsettings-common.c \
	xsettings-manager.h \
	xsettings-manager.c \
	xutils.h \
	xutils.c \
	$(NULL)
