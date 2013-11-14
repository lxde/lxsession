NULL=
if USE_GTK
bin_PROGRAMS = lxpolkit

lxpolkit_SOURCES = \
    main.vala \
    lxpolkit.c \
    lxpolkit-listener.c \
    $(NULL)

lxpolkit_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
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

CLEANFILES = \
    main.c
endif

EXTRA_DIST = \
        lxpolkit.h \
        lxpolkit-listener.h \
	$(NULL)
