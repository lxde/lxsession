bin_PROGRAMS = lxsession

lxsession_SOURCES = \
    main.vala \
    app.vala \
    autostart.vala \
    dbus-common.vala \
    dbus-gnome-session.vala \
    dbus-lxde-session.vala \
    environement.vala \
    options.vala \
    settings.vala \
    utils.vala \
    settings-daemon.c \
    xdg-autostart.c \
    xevent.c \
    xsettings-common.c \
    xsettings-manager.c \
    xutils.c \
    $(NULL)

lxsession_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
	--pkg dbus-glib-1 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg posix \
	--pkg settings-daemon \
	--pkg xdg-autostart \
	$(NULL)

lxsession_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(GIO_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DBUSGLIB_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	-include config.h -w \
	$(NULL)

lxsession_LDADD = \
	$(GLIB_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(DBUSGLIB_LIBS) \
	$(X11_LIBS) \
	$(NULL)

EXTRA_DIST = \
    settings-daemon.h \
    xdg-autostart.h \
    xevent.h \
    xsettings-common.h \
    xsettings-manager.h \
    xutils.h

CLEAN = \
    main.c \
    settings.c \
    utils.c \
    app.c \
    autostart.c \
    dbus-common.c \
    dbus-gnome-session.c \
    dbus-lxde-session.c \
    environement.c \
    options.c
