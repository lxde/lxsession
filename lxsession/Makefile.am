NULL=

bin_PROGRAMS = lxsession

lxsession_CFLAGS = \
	-I$(topsrcdir) \
	$(GTK_CFLAGS) \
	$(POLKIT_CFLAGS) \
	$(X11_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_DATA_DIR="\"$(datadir)"\" \
	-DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
	-Werror-implicit-function-declaration \
	$(NULL)

lxsession_LDADD = \
	$(GTK_LIBS) \
	$(POLKIT_LIBS) \
	$(X11_LIBS) \
	$(NULL)

#XSETTINGS_DAEMON_SOURCES = \
#	$(NULL)

POLKIT_AGENT_SOURCES = \
	polkit-agent/lxpolkit.c \
	polkit-agent/lxpolkit.h \
	polkit-agent/lxpolkit-listener.c \
	polkit-agent/lxpolkit-listener.h \
	$(NULL)

lxsession_SOURCES = \
	lxsession.c \
	lxsession.h \
	xdg-autostart.c \
	xdg-autostart.h \
	xsettings-common.c \
	xsettings-common.h \
	xsettings-manager.c \
	xsettings-manager.h \
	xutils.c \
	xutils.h \
	settings-daemon.c \
	settings-daemon.h \
	$(POLKIT_AGENT_SOURCES) \
	$(NULL)
