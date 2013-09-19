## Process this file with automake to produce Makefile.in

NULL=

bin_PROGRAMS = lxsession-edit

lxsession_edit_CFLAGS = \
	-I$(topsrcdir) \
	$(GTK_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_DATA_DIR="\"$(datadir)"\" \
	-DPACKAGE_UI_DIR="\"$(datadir)/lxsession/ui"\" \
	-Werror-implicit-function-declaration
	$(NULL)

lxsession_edit_LDADD = \
	$(GTK_LIBS) \
	$(INTLLIBS) \
	$(NULL)

lxsession_edit_SOURCES = \
	lxsession-edit.c \
	lxsession-edit-common.c \
	lxsession-edit-common.h \
	$(NULL)
