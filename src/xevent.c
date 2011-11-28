/*
 *      xevent.c
 *      
 *      Copyright 2009 PCMan <pcman.tw@gmail.com>
 *      
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *      
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *      
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 */

#include "xevent.h"

#include <string.h>

#include <X11/X.h>
#include <X11/Xproto.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

#include "settings-daemon.h"

Display* dpy = NULL;

static Atom CMD_ATOM; /* for private client message */
static GSource* source = NULL; /* main loop event source for X11 events */

typedef struct _X11Source
{
	GSource source;
	GPollFD poll_fd;
}X11Source;

static gboolean x11_event_prepare(GSource *source, gint *timeout);
static gboolean x11_event_check(GSource *source);
static gboolean x11_event_dispatch(GSource *source, GSourceFunc  callback, gpointer user_data);

static GSourceFuncs event_funcs = 
{
	x11_event_prepare,
	x11_event_check,
	x11_event_dispatch,
	NULL
};

void send_internal_command( int cmd )
{
	Window root = DefaultRootWindow(dpy);
    XEvent ev;

	memset(&ev, 0, sizeof(ev) );
	ev.xclient.type = ClientMessage;
	ev.xclient.window = root;
	ev.xclient.message_type = CMD_ATOM;
	ev.xclient.format = 8;

	ev.xclient.data.l[0] = cmd;

	XSendEvent(dpy, root, False,
			   SubstructureRedirectMask|SubstructureNotifyMask, &ev);
	XSync(dpy, False);
}

gboolean xevent_init()
{
	X11Source* xsource;
	int fd;

	dpy = XOpenDisplay( g_getenv("DISPLAY") );
	if( ! dpy )
		return FALSE;

	/* according to the spec, private Atoms should prefix their names with _. */
	CMD_ATOM = XInternAtom( dpy, "_LXSESSION", False );

	fd = ConnectionNumber(dpy); /* fd of XDisplay connection */
	if( G_UNLIKELY(fd == -1) )
		return FALSE;

	/* set up main loop event source for XDisplay */
	source = g_source_new (&event_funcs, sizeof(X11Source));
	xsource = (X11Source*)source;
	xsource->poll_fd.fd = fd;
	xsource->poll_fd.events = G_IO_IN;

	g_source_add_poll(source, &xsource->poll_fd);
	g_source_set_can_recurse(source, TRUE);
	g_source_attach(source, NULL);

	return TRUE;
}

gboolean single_instance_check()
{
	/* NOTE: this is a hack to do single instance */
	XGrabServer( dpy );
	if( XGetSelectionOwner( dpy, CMD_ATOM ) )
	{
		XUngrabServer( dpy );
		XCloseDisplay( dpy );
		return FALSE;
	}
	XSetSelectionOwner( dpy, CMD_ATOM, DefaultRootWindow( dpy ), CurrentTime );
	XUngrabServer( dpy );
	return TRUE;
}

gboolean x11_event_prepare(GSource *source, gint *timeout)
{
	*timeout = -1;
	return XPending(dpy) ? TRUE : FALSE;
}

gboolean x11_event_check(GSource *source)
{
	X11Source *xsource = (X11Source*)source;
	if(xsource->poll_fd.revents & G_IO_IN)
		return XPending(dpy) ? TRUE : FALSE;
	return FALSE;
}

gboolean x11_event_dispatch(GSource *source, GSourceFunc  callback, gpointer user_data)
{
	while( XPending(dpy) )
	{
		XEvent evt;
		XNextEvent( dpy, &evt );
		if( evt.type == ClientMessage )
		{
			if(evt.xproperty.atom == CMD_ATOM)
			{
				int cmd = evt.xclient.data.b[0];
				switch( cmd )
				{
				case LXS_RELOAD:	/* reload all settings */
                    /* TODO Replace this by Dbus
					settings_deamon_reload();
                    */
					break;
				case LXS_EXIT:
                    /* TODO Replace this by Dbus
					lxsession_quit();
                    */
					break;
				}
			}
		}
		else if( evt.type ==  SelectionClear )
		{
			settings_manager_selection_clear( &evt );
		}
	}
	return TRUE;
}

void xevent_finalize()
{
	if(source)
	{
		g_source_destroy(source);
		g_source_unref(source);
	}

	XGrabServer( dpy );
	XSetSelectionOwner( dpy, CMD_ATOM, DefaultRootWindow( dpy ), None );
	XUngrabServer( dpy );

	XCloseDisplay( dpy );
}

