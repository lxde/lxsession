bin_PROGRAMS = lxsession-default-apps

lxsession_default_apps_SOURCES = \
	autostart.vala \
	main.vala \
	combobox.vala \
	dbus-backend.vala \
    ../lxsession-edit/lxsession-edit-common.c \
    $(NULL)

lxsession_default_apps_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
	--pkg gtk+-2.0 \
	--pkg dbus-glib-1 \
	--pkg gio-2.0 \
	--pkg posix \
	--pkg lxsession-edit \
	$(NULL)

lxsession_default_apps_CFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_DATA_DIR="\"$(datadir)"\" \
	-DPACKAGE_UI_DIR="\"$(datadir)/lxsession-default-apps/ui"\" \
	$(GTK_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GIO_CFLAGS) \
	$(DBUSGLIB_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	-include config.h -w \
	$(NULL)

lxsession_default_apps_LDADD = \
	$(GTK_LIBS) \
	$(GLIB_LIBS) \
	$(GIO_LIBS) \
	$(DBUSGLIB_LIBS) \
	$(X11_LIBS) \
	$(NULL)

CLEANFILES = \
    autostart.c \
    main.c \
    combobox.c \
    dbus-backend.c \
    lxsession_default_apps_vala.stamp
