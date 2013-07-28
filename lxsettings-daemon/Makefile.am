bin_PROGRAMS = lxsettings-daemon

lxsettings_daemon_SOURCES = \
    main.vala \
    settings-daemon.c \
    xevent.c \
    xsettings-common.c \
    xsettings-manager.c \
    xutils.c \
    $(NULL)

lxsettings_daemon_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
	--pkg lxsettings-daemon \
	$(NULL)

lxsettings_daemon_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(GIO_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	-include config.h -w \
	$(NULL)

lxsettings_daemon_LDADD = \
	$(GLIB_LIBS) \
	$(GIO_LIBS) \
	$(X11_LIBS) \
	$(NULL)

CLEAN = \
    main.c

EXTRA_DIST = \
    settings-daemon.h \
    xevent.h \
    xsettings-common.h \
    xsettings-manager.h \
    xutils.h
