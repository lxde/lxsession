bin_PROGRAMS = lxsession

if USE_BUILDIN_CLIPBOARD
buildinclip_SOURCES = \
    ../lxclipboard/clipboard.c \
    $(NULL)

buildinclip_VALAFLAGS = \
    --pkg lxclipboard \
	--pkg gtk+-2.0 \
    -D BUILDIN_CLIPBOARD \
    $(NULL)

buildinclip_CFLAGS = \
    $(GTK_CFLAGS) \
    $(NULL)

buildinclip_LDADD = \
    $(GTK_LIBS) \
    $(NULL)
endif

if USE_BUILDIN_POLKIT
buildinpolkit_SOURCES = \
    ../lxpolkit/lxpolkit.c \
    ../lxpolkit/lxpolkit-listener.c \
    $(NULL)

buildinpolkit_VALAFLAGS = \
    --pkg lxpolkit \
    -D BUILDIN_POLKIT \
    $(NULL)

buildinpolkit_CFLAGS = \
    $(GTK_CFLAGS) \
    $(POLKIT_CFLAGS) \
    $(NULL)

buildinpolkit_LDADD = \
    $(GTK_LIBS) \
    $(POLKIT_LIBS) \
    $(NULL)
endif

lxsession_SOURCES = \
    main.vala \
    app.vala \
    autostart.vala \
    conffiles.vala \
    control.vala \
    dbus-common.vala \
    dbus-gnome-session.vala \
    dbus-lxde-session.vala \
    environement.vala \
    options.vala \
    process.vala \
    settings.vala \
    utils.vala \
    ../lxsettings-daemon/settings-daemon.c \
    ../lxsettings-daemon/xevent.c \
    ../lxsettings-daemon/xsettings-common.c \
    ../lxsettings-daemon/xsettings-manager.c \
    ../lxsettings-daemon/xutils.c \
    ../xdg-autostart/xdg-autostart.c \
    $(buildinclip_SOURCES) \
    $(buildinpolkit_SOURCES) \
    $(NULL)

lxsession_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
	--pkg dbus-glib-1 \
	--pkg gio-2.0 \
	--pkg posix \
	--pkg lxsettings-daemon \
	--pkg xdg-autostart \
	$(buildinclip_VALAFLAGS) \
	$(buildinpolkit_VALAFLAGS) \
	$(NULL)

lxsession_CFLAGS = \
        -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
        -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
        -DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
	-I$(srcdir)/lxsettings-daemon \
	-I$(srcdir)/xdg-autostart \
	$(GLIB_CFLAGS) \
	$(GIO_CFLAGS) \
	$(GEE_CFLAGS) \
	$(DBUSGLIB_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	$(buildinclip_CFLAGS) \
	$(buildinpolkit_CFLAGS) \
	-include config.h -w \
	$(NULL)

lxsession_LDADD = \
	$(GLIB_LIBS) \
	$(GIO_LIBS) \
	$(GEE_LIBS) \
	$(DBUSGLIB_LIBS) \
	$(X11_LIBS) \
	$(buildinclip_LDADD) \
	$(buildinpolkit_LDADD) \
	$(NULL)

CLEANFILES = \
    main.c \
    app.c \
    autostart.c \
    conffiles.c \
    control.c \
    dbus-common.c \
    dbus-gnome-session.c \
    dbus-lxde-session.c \
    environement.c \
    options.c \
    process.c \
    settings.c \
    utils.c
