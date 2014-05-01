bin_PROGRAMS = lxsession-xdg-autostart

lxsession_xdg_autostart_SOURCES = \
    xdg-autostart.c \
    main.vala \
    $(NULL)

lxsession_xdg_autostart_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
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

CLEAN = \
    main.c

EXTRA_DIST = \
    xdg-autostart.h
