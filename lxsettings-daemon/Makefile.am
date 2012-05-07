//bin_PROGRAMS = lxsettings-daemon

lxsettings_SOURCES = \
    settings-daemon.c \
    xevent.c \
    xsettings-common.c \
    xsettings-manager.c \
    xutils.c \
    $(NULL)

lxsettings_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	-include config.h -w \
	$(NULL)

lxsettings_LDADD = \
	$(GLIB_LIBS) \
	$(X11_LIBS) \
	$(NULL)

EXTRA_DIST = \
    settings-daemon.h \
    xevent.h \
    xsettings-common.h \
    xsettings-manager.h \
    xutils.h
