bin_PROGRAMS = lxsession-logout

lxsession_logout_CFLAGS =  $(GTK_CFLAGS) $(SM_CFLAGS) $(HAL_CFLAGS) \
			-DPACKAGE_LOCALE_DIR=\"$(datadir)/locale\" \
			-DPACKAGE_DATA_DIR=\"$(datadir)\"

lxsession_logout_LDADD = $(GTK_LIBS) $(SM_LIBS) $(HAL_LIBS)

lxsession_logout_SOURCES= \
	gdm-logout-action.c \
        gdm-logout-action.h \
	main.c
