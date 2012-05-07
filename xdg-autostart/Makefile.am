//bin_PROGRAMS = xdg-autostart

lxsession_SOURCES = \
    xdg-autostart.c \
    $(NULL)

lxsession_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	-include config.h -w \
	$(NULL)

lxsession_LDADD = \
	$(GLIB_LIBS) \
	$(X11_LIBS) \
	$(NULL)

EXTRA_DIST = \
    xdg-autostart.h
