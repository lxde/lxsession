bin_PROGRAMS = lxclipboard

lxclipboard_SOURCES = \
    main.vala \
    clipboard.c \
    $(NULL)

lxclipboard_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
	--pkg gtk+-2.0 \
	--pkg clipboard \
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

EXTRA_DIST = \
    clipboard.h

CLEAN = \
    main.c
