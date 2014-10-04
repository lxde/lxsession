if USE_GTK
bin_PROGRAMS = lxsession-message-gtk

lxsession_message_gtk_SOURCES = \
    main-gtk.vala \
    $(NULL)

lxsession_message_gtk_VALAFLAGS = \
	--vapidir=$(srcdir)/../vapi \
	--pkg gtk+-3.0 \
	$(NULL)

lxsession_message_gtk_CFLAGS = \
	$(GTK_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(ADDITIONAL_FLAGS) \
	-include config.h -w \
	$(NULL)

lxsession_message_gtk_LDADD = \
	$(GTK_LIBS) \
	$(GLIB_LIBS) \
	$(X11_LIBS) \
	$(NULL)

CLEAN = \
    main.c
endif
