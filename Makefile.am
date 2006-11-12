# 
#  Copyright 2005  Red Hat, Inc.
# 
#  Permission to use, copy, modify, distribute, and sell this software and its
#  documentation for any purpose is hereby granted without fee, provided that
#  the above copyright notice appear in all copies and that both that
#  copyright notice and this permission notice appear in supporting
#  documentation, and that the name of Red Hat not be used in
#  advertising or publicity pertaining to distribution of the software without
#  specific, written prior permission.  Red Hat makes no
#  representations about the suitability of this software for any purpose.  It
#  is provided "as is" without express or implied warranty.
# 
#  RED HAT DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
#  INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO
#  EVENT SHALL RED HAT BE LIABLE FOR ANY SPECIAL, INDIRECT OR
#  CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
#  DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
#  TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
#  PERFORMANCE OF THIS SOFTWARE.

SUBDIRS=po

bin_SCRIPTS = startlxde

bin_PROGRAMS = lxsession

SYSTEM_INIT_DIR = $(libdir)/X11/xsm

lxsession_CFLAGS = $(GTK_CFLAGS) $(SM_CFLAGS) -DRSHCMD=\"@RSH@\" \
                   -DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\"

lxsession_LDADD = $(GTK_LIBS) $(SM_LIBS)

lxsession_SOURCES =	\
        gdm-logout-action.c \
        gdm-logout-action.h \
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
        save.c \
        save.h \
        saveutil.c \
        saveutil.h \
        signals.c \
        printhex.c \
        xsm.c \
        xsm.h

# Currently these paths are hardcoded.
xsessiondir=/usr/share/xsessions
xsession_DATA = LXDE.desktop

defaultsdir=/etc
defaults_DATA = LXSM-LXDE-Default

EXTRA_DIST = LXDE.desktop.in startlxde.in $(defaults_DATA)

CLEANFILES = $(bin_SCRIPTS)

