SYSTEM_INIT_DIR = $(libdir)/X11/xsm

bin_PROGRAMS=lxsession

lxsession_CFLAGS = $(GLIB_CFLAGS) $(SM_CFLAGS) -DRSHCMD=\"@RSH@\" \
                   -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\"

lxsession_LDADD = $(GLIB_LIBS) $(SM_LIBS)

lxsession_SOURCES =	\
        auth.c \
        auth.h \
        info.c \
        info.h \
        lock.c \
        lock.h \
        misc.c \
        prop.c \
        prop.h \
        remote.c \
        restart.c \
        restart.h \
	autostart.c \
	autostart.h \
        save.c \
        save.h \
        saveutil.c \
        saveutil.h \
        signals.c \
        printhex.c \
        xsm.c \
        xsm.h
