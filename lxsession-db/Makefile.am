bin_PROGRAMS = lxsession-db

lxsession_db_SOURCES = \
	main.vala \
	desktop-files-backend.vala \
    $(NULL)

lxsession_db_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
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

CLEANFILES = \
	main.c \
	desktop-files-backend.c \
    lxsession_db_vala.stamp
