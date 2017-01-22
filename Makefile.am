ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}
AUTOMAKE_OPTIONS = subdir-objects

NULL=

SUBDIRS= data \
        man \
        po \
        $(NULL)

bin_PROGRAMS = \
    lxsettings-daemon/lxsettings-daemon \
    xdg-autostart/lxsession-xdg-autostart \
    lxsession/lxsession \
    $(NULL)

scripts= \
    lxlock/lxlock \
    lxsession-default/lxsession-default \
    lxsession-default/lxsession-default-terminal \
    $(NULL)

bin_SCRIPTS= $(scripts)

pkglibexec_SCRIPTS = \
    lxsession-utils/lxsession-xsettings \
    $(NULL)

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
    lxsession-utils/lxsession-xsettings \
    $(NULL)

if USE_GTK
bin_PROGRAMS += \
    lxpolkit/lxpolkit \
    lxsession-db/lxsession-db \
    lxsession-edit/lxsession-edit \
    lxsession-logout/lxsession-logout \
    lxsession-default-apps/lxsession-default-apps \
    lxclipboard/lxclipboard \
    $(NULL)

lxclipboard_lxclipboard_vala_SOURCES = \
    lxclipboard/main.vala \
    $(NULL)

CLEANFILES += lxclipboard/main.c \
    lxclipboard_lxclipboard_vala.stamp \
    $(NULL)

lxclipboard_lxclipboard_SOURCES = \
    $(lxclipboard_lxclipboard_vala_SOURCES) \
    lxclipboard/clipboard.c \
    $(NULL)

lxclipboard_lxclipboard_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg @VALA_GTK_LIBS@ \
    --pkg lxclipboard \
    $(NULL)

lxclipboard_lxclipboard_CPPFLAGS = \
    $(GTK_CFLAGS) \
    $(GLIB_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -include config.h -w \
    $(NULL)

lxclipboard_lxclipboard_LDADD = \
    $(GTK_LIBS) \
    $(GLIB_LIBS) \
    $(X11_LIBS) \
    $(NULL)

if USE_GTK3
lxclipboard_lxclipboard_VALAFLAGS += --define USE_GTK3
else
lxclipboard_lxclipboard_VALAFLAGS += --define USE_GTK2
endif

lxpolkit_lxpolkit_vala_SOURCES = \
    lxpolkit/main.vala \
    $(NULL)

CLEANFILES += lxpolkit/main.c \
    lxpolkit_lxpolkit_vala.stamp \
    $(NULL)

lxpolkit_lxpolkit_SOURCES = \
    $(lxpolkit_lxpolkit_vala_SOURCES) \
    lxpolkit/lxpolkit.c \
    lxpolkit/lxpolkit-listener.c \
    $(NULL)

lxpolkit_lxpolkit_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg @VALA_GTK_LIBS@ \
    --pkg lxpolkit \
    $(NULL)

lxpolkit_lxpolkit_CPPFLAGS = \
    $(GTK_CFLAGS) \
    $(GLIB_CFLAGS) \
    $(POLKIT_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
    -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
    -DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
    -include config.h -w \
    $(NULL)

lxpolkit_lxpolkit_LDADD = \
    $(GTK_LIBS) \
    $(GLIB_LIBS) \
    $(POLKIT_LIBS) \
    $(X11_LIBS) \
    $(NULL)

if USE_GTK3
lxpolkit_lxpolkit_VALAFLAGS += --define USE_GTK3
else
lxpolkit_lxpolkit_VALAFLAGS += --define USE_GTK2
endif

lxsession_db_lxsession_db_SOURCES = \
    lxsession-db/main.vala \
    lxsession-db/desktop-files-backend.vala \
    $(NULL)

CLEANFILES += \
    lxsession-db/main.c \
    lxsession-db/desktop-files-backend.c \
    lxsession_db_lxsession_db_vala.stamp \
    $(NULL)

lxsession_db_lxsession_db_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg @VALA_GTK_LIBS@ \
    $(NULL)

lxsession_db_lxsession_db_CPPFLAGS = \
    -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
    -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
    -DPACKAGE_UI_DIR="\"$(datadir)/lxsession-default-apps/ui"\" \
    $(GTK_CFLAGS) \
    $(GLIB_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -include config.h -w \
    $(NULL)

lxsession_db_lxsession_db_LDADD = \
    $(GTK_LIBS) \
    $(GLIB_LIBS) \
    $(X11_LIBS) \
    $(NULL)

lxsession_edit_lxsession_edit_CPPFLAGS = \
    -I$(top_srcdir) \
    $(GTK_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
    -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
    -DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
    -Werror-implicit-function-declaration \
    $(NULL)

lxsession_edit_lxsession_edit_LDADD = \
    $(GTK_LIBS) \
    $(INTLLIBS) \
    $(NULL)

lxsession_edit_lxsession_edit_common_SOURCES = \
    lxsession-edit/lxsession-edit-common.c \
    $(NULL)

lxsession_edit_lxsession_edit_SOURCES = \
    lxsession-edit/lxsession-edit.c \
    $(lxsession_edit_lxsession_edit_common_SOURCES) \
    $(NULL)

lxsession_default_apps_lxsession_default_apps_vala_SOURCES = \
    lxsession-default-apps/autostart.vala \
    lxsession-default-apps/main.vala \
    lxsession-default-apps/combobox.vala \
    lxsession-default-apps/dbus-backend.vala \
    lxsession-default-apps/utils.vala \
    $(NULL)

CLEANFILES += \
    lxsession-default-apps/autostart.c \
    lxsession-default-apps/main.c \
    lxsession-default-apps/combobox.c \
    lxsession-default-apps/dbus-backend.c \
    lxsession-default-apps/utils.c \
    lxsession_default_apps_lxsession_default_apps_vala.stamp \
    $(NULL)

lxsession_default_apps_lxsession_default_apps_SOURCES = \
    $(lxsession_default_apps_lxsession_default_apps_vala_SOURCES) \
    $(lxsession_edit_lxsession_edit_common_SOURCES) \
    $(NULL)

lxsession_default_apps_lxsession_default_apps_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg @VALA_GTK_LIBS@ \
    --pkg gio-2.0 \
    --pkg posix \
    --pkg lxsession-edit \
    --pkg config \
    $(NULL)

lxsession_default_apps_lxsession_default_apps_CPPFLAGS = \
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

lxsession_default_apps_lxsession_default_apps_LDADD = \
    $(GTK_LIBS) \
    $(GLIB_LIBS) \
    $(GIO_LIBS) \
    $(DBUSGLIB_LIBS) \
    $(X11_LIBS) \
    $(NULL)

if USE_BUILDIN_CLIPBOARD
buildinclip_SOURCES = \
    lxclipboard/clipboard.c \
    $(NULL)

buildinclip_VALAFLAGS = \
    --pkg lxclipboard \
    -D BUILDIN_CLIPBOARD \
    $(NULL)
endif

if USE_BUILDIN_POLKIT
buildinpolkit_SOURCES = \
    lxpolkit/lxpolkit.c \
    lxpolkit/lxpolkit-listener.c \
    $(NULL)

buildinpolkit_VALAFLAGS = \
    --pkg lxpolkit \
    -D BUILDIN_POLKIT \
    $(NULL)

buildinpolkit_CFLAGS = \
    $(POLKIT_CFLAGS) \
    $(NULL)

buildinpolkit_LDADD = \
    $(POLKIT_LIBS) \
    $(NULL)
endif

lxsession_logout_lxsession_logout_CPPFLAGS = \
    $(GTK_CFLAGS) \
    $(SM_CFLAGS) \
    $(DBUS_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -DPACKAGE_LOCALE_DIR=\"$(datadir)/locale\" \
    -DPACKAGE_DATA_DIR=\"$(datadir)\"

lxsession_logout_lxsession_logout_LDADD = \
    $(GTK_LIBS) \
    $(SM_LIBS) \
    $(DBUS_LIBS) \
    $(X11_LIBS)

lxsession_logout_lxsession_logout_SOURCES= \
    lxsession-logout/lxsession-logout-dbus-interface.c \
    lxsession-logout/lxsession-logout.c

CLEANFILES += \
    $(NULL)

EXTRA_DIST += \
    $(NULL)

endif

lxsettings_daemon_lxsettings_daemon_SOURCES = \
    lxsettings-daemon/main.vala \
    $(lxsettings_daemon_lxsettings_daemon_commun_SOURCES) \
    $(NULL)

CLEANFILES += \
    lxsettings-daemon/main.c \
    lxsettings_daemon_lxsettings_daemon_vala.stamp \
    $(NULL)

lxsettings_daemon_lxsettings_daemon_commun_SOURCES = \
    lxsettings-daemon/settings-daemon.c \
    lxsettings-daemon/xevent.c \
    lxsettings-daemon/xsettings-common.c \
    lxsettings-daemon/xsettings-manager.c \
    lxsettings-daemon/xutils.c \
    $(NULL)

lxsettings_daemon_lxsettings_daemon_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg lxsettings-daemon \
    $(NULL)

lxsettings_daemon_lxsettings_daemon_CPPFLAGS = \
    $(GLIB_CFLAGS) \
    $(GIO_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -include config.h -w \
    $(NULL)

lxsettings_daemon_lxsettings_daemon_LDADD = \
    $(GLIB_LIBS) \
    $(GIO_LIBS) \
    $(X11_LIBS) \
    $(NULL)

xdg_autostart_lxsession_xdg_autostart_vala_SOURCES = \
    xdg-autostart/main.vala \
    $(NULL)

CLEANFILES += \
    xdg-autostart/main.c \
    xdg_autostart_lxsession_xdg_autostart_vala.stamp \
    $(NULL)

xdg_autostart_lxsession_xdg_autostart_SOURCES = \
    $(xdg_autostart_lxsession_xdg_autostart_vala_SOURCES) \
    xdg-autostart/xdg-autostart.c \
    $(NULL)

xdg_autostart_lxsession_xdg_autostart_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg xdg-autostart \
    $(NULL)

xdg_autostart_lxsession_xdg_autostart_CPPFLAGS = \
    $(GLIB_CFLAGS) \
    $(GIO_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    -include config.h -w \
    $(NULL)

xdg_autostart_lxsession_xdg_autostart_LDADD = \
    $(GLIB_LIBS) \
    $(GIO_LIBS) \
    $(X11_LIBS) \
    $(NULL)

lxsession_lxsession_vala_SOURCES = \
    lxsession/main.vala \
    lxsession/app.vala \
    lxsession/autostart.vala \
    lxsession/conffiles.vala \
    lxsession/control.vala \
    lxsession/dbus-common.vala \
    lxsession/dbus-gnome-session.vala \
    lxsession/dbus-lxde-session.vala \
    lxsession/environement.vala \
    lxsession/notifications.vala \
    lxsession/options.vala \
    lxsession/process.vala \
    lxsession/settings.vala \
    lxsession/utils.vala \
    $(NULL)

CLEANFILES += \
    lxsession/main.c \
    lxsession/app.c \
    lxsession/autostart.c \
    lxsession/conffiles.c \
    lxsession/control.c \
    lxsession/dbus-common.c \
    lxsession/dbus-gnome-session.c \
    lxsession/dbus-lxde-session.c \
    lxsession/environement.c \
    lxsession/notifications.c \
    lxsession/options.c \
    lxsession/process.c \
    lxsession/settings.c \
    lxsession/utils.c \
    lxsession_lxsession_vala.stamp \
    $(NULL)

lxsession_lxsession_SOURCES = \
    $(lxsession_lxsession_vala_SOURCES) \
    $(lxsettings_daemon_lxsettings_daemon_commun_SOURCES) \
    $(buildinclip_SOURCES) \
    $(buildinpolkit_SOURCES) \
    $(NULL)

lxsession_lxsession_VALAFLAGS = \
    --vapidir=$(srcdir)/vapi \
    --pkg dbus-glib-1 \
    --pkg gio-2.0 \
    --pkg posix \
    --pkg lxsettings-daemon \
    $(buildinclip_VALAFLAGS) \
    $(buildinpolkit_VALAFLAGS) \
    $(lxsession_gtk_lxsession_VALAFLAGS) \
    $(NULL)

lxsession_lxsession_CPPFLAGS = \
    -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
    -DPACKAGE_DATA_DIR="\"$(datadir)"\" \
    -DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
    -I$(srcdir)/lxsettings-daemon \
    -I$(srcdir)/xdg-autostart \
    $(GLIB_CFLAGS) \
    $(GIO_CFLAGS) \
    $(DBUSGLIB_CFLAGS) \
    $(ADDITIONAL_FLAGS) \
    $(buildinclip_CFLAGS) \
    $(buildinpolkit_CFLAGS) \
    $(lxsession_gtk_lxsession_CFLAGS) \
    -include config.h -w \
    $(NULL)

lxsession_lxsession_LDADD = \
    $(GLIB_LIBS) \
    $(GIO_LIBS) \
    $(DBUSGLIB_LIBS) \
    $(X11_LIBS) \
    $(buildinclip_LDADD) \
    $(buildinpolkit_LDADD) \
    $(lxsession_gtk_lxsession_LDADD) \
    $(NULL)

if USE_GTK
lxsession_lxsession_VALAFLAGS +=     \
    --pkg @VALA_GTK_LIBS@ \
    -D USE_GTK

lxsession_lxsession_CPPFLAGS += \
    $(GTK_CFLAGS)

lxsession_lxsession_LDADD += \
    $(GTK_LIBS)

if USE_ADVANCED_NOTIFICATIONS
lxsession_lxsession_VALAFLAGS +=     \
    --pkg appindicator-0.1 \
    --pkg libnotify \
    -D USE_ADVANCED_NOTIFICATIONS

lxsession_lxsession_CPPFLAGS += \
    $(LIBNOTIFY_CFLAGS) \
    $(INDICATORS_CFLAGS)

lxsession_lxsession_LDADD += \
    $(LIBNOTIFY_LIBS) \
    $(INDICATORS_LIBS)
endif
endif

EXTRA_DIST += \
    autogen.sh \
    lxclipboard/clipboard.h \
    lxpolkit/lxpolkit.h \
    lxpolkit/lxpolkit-listener.h \
    lxsettings-daemon/settings-daemon.h \
    lxsettings-daemon/xevent.h \
    lxsettings-daemon/xsettings-common.h \
    lxsettings-daemon/xsettings-manager.h \
    lxsettings-daemon/xutils.h \
    lxsession-edit/lxsession-edit-common.h \
    lxsession-logout/lxsession-logout-dbus-interface.h \
    xdg-autostart/xdg-autostart.h \
    $(NULL)
