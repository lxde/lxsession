ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}
AUTOMAKE_OPTIONS = subdir-objects

NULL=

SUBDIRS= data \
        man \
        po \
        $(NULL)

bin_PROGRAMS = \
    lxsettings-daemon \
    lxsession-xdg-autostart \
    lxsession \
    $(NULL)

scripts= \
    lock/lxlock \
    session-default/lxsession-default \
    session-default/lxsession-default-terminal \
    session-utils/lxsession-xsettings \
    $(NULL)

bin_SCRIPTS= $(scripts)

noinst_DATA = \
    vapi/config.vapi \
    vapi/lxclipboard.vapi \
    vapi/lxpolkit.vapi \
    vapi/lxsession-edit.vapi \
    vapi/lxsettings-daemon.vapi \
    vapi/xdg-autostart.vapi \
    $(NULL)

CLEANFILES = \
    $(NULL)

EXTRA_DIST = \
    $(noinst_DATA) \
    $(scripts) \
    $(NULL)

if USE_GTK
bin_PROGRAMS += \
    lxpolkit \
    lxsession-db \
    lxsession-edit \
    lxsession-logout \
    lxsession-default-apps \
    lxclipboard \
    $(NULL)

lxclipboard_vala_SOURCES = \
    clipboard/main.vala \
    $(NULL)

lxclipboard_SOURCES = \
    $(lxclipboard_vala_SOURCES) \
    clipboard/clipboard.c \
    $(NULL)

lxclipboard_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg gtk+-2.0 \
    --pkg lxclipboard \
    $(NULL)

lxclipboard_CFLAGS = \
    $(GTK_CFLAGS) \
    $(GLIB_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -include config.h -w \
    $(NULL)

lxclipboard_LDADD = \
    $(GTK_LIBS) \
    $(GLIB_LIBS) \
    $(X11_LIBS) \
    $(NULL)

lxpolkit_vala_SOURCES = \
    polkit/main.vala \
    $(NULL)

lxpolkit_SOURCES = \
    $(lxpolkit_vala_SOURCES) \
    polkit/lxpolkit.c \
    polkit/lxpolkit-listener.c \
    $(NULL)

lxpolkit_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg gtk+-2.0 \
    --pkg lxpolkit \
    $(NULL)

lxpolkit_CFLAGS = \
    $(GTK_CFLAGS) \
    $(GLIB_CFLAGS) \
    $(POLKIT_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
    -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
    -DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
    -include config.h -w \
    $(NULL)

lxpolkit_LDADD = \
    $(GTK_LIBS) \
    $(GLIB_LIBS) \
    $(POLKIT_LIBS) \
    $(X11_LIBS) \
    $(NULL)

lxsession_db_SOURCES = \
    session-db/main.vala \
    session-db/desktop-files-backend.vala \
    $(NULL)

lxsession_db_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg gtk+-2.0 \
    $(NULL)

lxsession_db_CFLAGS = \
    -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
    -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
    -DPACKAGE_UI_DIR="\"$(datadir)/lxsession-default-apps/ui"\" \
    $(GTK_CFLAGS) \
    $(GEE_CFLAGS) \
    $(GLIB_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -include config.h -w \
    $(NULL)

lxsession_db_LDADD = \
    $(GTK_LIBS) \
    $(GEE_LIBS) \
    $(GLIB_LIBS) \
    $(X11_LIBS) \
    $(NULL)

lxsession_edit_CFLAGS = \
    -I$(top_srcdir) \
    $(GTK_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
    -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
    -DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
    -Werror-implicit-function-declaration \
    $(NULL)

lxsession_edit_LDADD = \
    $(GTK_LIBS) \
    $(INTLLIBS) \
    $(NULL)

lxsession_edit_common_SOURCES = \
    session-edit/lxsession-edit-common.c \
    $(NULL)

lxsession_edit_SOURCES = \
    session-edit/lxsession-edit.c \
    $(lxsession_edit_common_SOURCES) \
    $(NULL)

lxsession_default_apps_vala_SOURCES = \
    session-default-apps/autostart.vala \
    session-default-apps/main.vala \
    session-default-apps/combobox.vala \
    session-default-apps/dbus-backend.vala \
    session-default-apps/utils.vala \
    $(NULL)

lxsession_default_apps_SOURCES = \
    $(lxsession_default_apps_vala_SOURCES) \
    $(lxsession_edit_common_SOURCES) \
    $(NULL)

lxsession_default_apps_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg gtk+-2.0 \
    --pkg dbus-glib-1 \
    --pkg gio-2.0 \
    --pkg posix \
    --pkg lxsession-edit \
    --pkg config \
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

if USE_BUILDIN_CLIPBOARD
buildinclip_SOURCES = \
    clipboard/clipboard.c \
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
    polkit/lxpolkit.c \
    polkit/lxpolkit-listener.c \
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

lxsession_logout_CFLAGS = \
    $(GTK_CFLAGS) \
    $(SM_CFLAGS) \
    $(DBUS_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -DPACKAGE_LOCALE_DIR=\"$(datadir)/locale\" \
    -DPACKAGE_DATA_DIR=\"$(datadir)\"

lxsession_logout_LDADD = \
    $(GTK_LIBS) \
    $(SM_LIBS) \
    $(DBUS_LIBS) \
    $(X11_LIBS)

lxsession_logout_SOURCES= \
    session-logout/lxsession-logout-dbus-interface.c \
    session-logout/lxsession-logout.c

endif

lxsettings_daemon_SOURCES = \
    settings-daemon/main.vala \
    $(lxsettings_daemon_commun_SOURCES) \
    $(NULL)

lxsettings_daemon_commun_SOURCES = \
    settings-daemon/settings-daemon.c \
    settings-daemon/xevent.c \
    settings-daemon/xsettings-common.c \
    settings-daemon/xsettings-manager.c \
    settings-daemon/xutils.c \
    $(NULL)

lxsettings_daemon_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
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

lxsession_xdg_autostart_vala_SOURCES = \
    xdg-autostart/main.vala \
    $(NULL)

lxsession_xdg_autostart_SOURCES = \
    $(lxsession_xdg_autostart_vala_SOURCES) \
    xdg-autostart/xdg-autostart.c \
    $(NULL)

lxsession_xdg_autostart_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg xdg-autostart \
    $(NULL)

lxsession_xdg_autostart_CFLAGS = \
    $(GLIB_CFLAGS) \
    $(GIO_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -include config.h -w \
    $(NULL)

lxsession_xdg_autostart_LDADD = \
    $(GLIB_LIBS) \
    $(GIO_LIBS) \
    $(X11_LIBS) \
    $(NULL)

lxsession_vala_SOURCES = \
    session/main.vala \
    session/app.vala \
    session/autostart.vala \
    session/conffiles.vala \
    session/control.vala \
    session/dbus-common.vala \
    session/dbus-gnome-session.vala \
    session/dbus-lxde-session.vala \
    session/environement.vala \
    session/options.vala \
    session/process.vala \
    session/settings.vala \
    session/utils.vala \
    $(NULL)

lxsession_SOURCES = \
    $(lxsession_vala_SOURCES) \
    $(lxsettings_daemon_commun_SOURCES) \
    $(buildinclip_SOURCES) \
    $(buildinpolkit_SOURCES) \
    $(NULL)

lxsession_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg dbus-glib-1 \
    --pkg gio-2.0 \
    --pkg posix \
    --pkg lxsettings-daemon \
    $(buildinclip_VALAFLAGS) \
    $(buildinpolkit_VALAFLAGS) \
    $(NULL)

lxsession_CFLAGS = \
    -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
    -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
    -DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
    -I$(srcdir)/settings-daemon \
    -I$(srcdir)/xdg-autostart \
    $(GLIB_CFLAGS) \
    $(GIO_CFLAGS) \
    $(DBUSGLIB_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    $(buildinclip_CFLAGS) \
    $(buildinpolkit_CFLAGS) \
    -include config.h -w \
    $(NULL)

lxsession_LDADD = \
    $(GLIB_LIBS) \
    $(GIO_LIBS) \
    $(DBUSGLIB_LIBS) \
    $(X11_LIBS) \
    $(buildinclip_LDADD) \
    $(buildinpolkit_LDADD) \
    $(NULL)

EXTRA_DIST += \
    autogen.sh \
    clipboard/clipboard.h \
    polkit/lxpolkit.h \
    polkit/lxpolkit-listener.h \
    settings-daemon/settings-daemon.h \
    settings-daemon/xevent.h \
    settings-daemon/xsettings-common.h \
    settings-daemon/xsettings-manager.h \
    settings-daemon/xutils.h \
    session-edit/lxsession-edit-common.h \
    session-logout/lxsession-logout-dbus-interface.h \
    xdg-autostart/xdg-autostart.h \
    $(NULL)
