/*
 *      lxpolkit.c
 *
 *      Copyright 2010 - 2011 PCMan <pcman.tw@gmail.com>
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <glib/gi18n.h>
#include <sys/types.h>
#include <unistd.h>

#include "lxpolkit-listener.h"
#include "lxpolkit.h"

static PolkitAgentListener *listener;
static PolkitSubject* session;

void show_msg(GtkWindow* parent, GtkMessageType type, const char* msg)
{
    GtkWidget* dlg = gtk_message_dialog_new(parent, GTK_DIALOG_MODAL, type,
                                            GTK_BUTTONS_OK, "%s", msg);
    const char* title = NULL;
    switch(type)
    {
    case GTK_MESSAGE_ERROR:
        title = _("Error");
        break;
    case GTK_MESSAGE_INFO:
        title = _("Information");
        break;
    }
    if(title)
        gtk_window_set_title(GTK_WINDOW(dlg), title);
    gtk_dialog_run(GTK_DIALOG(dlg));
    gtk_widget_destroy(dlg);
}

gboolean policykit_agent_init()
{
    GError* err = NULL;

    listener = lxpolkit_listener_new();
    session = polkit_unix_session_new_for_process_sync(getpid(), NULL, &err);
    if(session == NULL)
    {
        /* show error msg */
        g_object_unref(listener);
        show_msg(NULL, GTK_MESSAGE_ERROR, err->message);
        return 1;
    }
    if(!polkit_agent_register_listener(listener, session, NULL, &err))
    {
        /* show error msg */
        g_object_unref(listener);
        g_object_unref(session);
        /* lxsession_show_msg(NULL, GTK_MESSAGE_ERROR, err->message); */
        show_msg(NULL, GTK_MESSAGE_ERROR, err->message);
        listener = NULL;
        session = NULL;
        return FALSE;
    }
    return TRUE;
}

void policykit_agent_finalize()
{
    g_object_unref(listener);
    g_object_unref(session);
}
