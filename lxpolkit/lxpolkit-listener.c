/*
 *      lx-polkit-listener.c
 *
 *      Copyright 2010 PCMan <pcman.tw@gmail.com>
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

#include "lxpolkit-listener.h"
#include "lxpolkit.h"
#include <glib/gi18n.h>
#include <string.h>

#include <sys/types.h>
#include <pwd.h>
#include <grp.h>

#ifdef G_ENABLE_DEBUG
#define DEBUG(...)  g_debug(__VA_ARGS__)
#else
#define DEBUG(...)
#endif

static void lxpolkit_listener_finalize              (GObject *object);

G_DEFINE_TYPE(LXPolkitListener, lxpolkit_listener, POLKIT_AGENT_TYPE_LISTENER);

typedef struct _DlgData DlgData;
struct _DlgData
{
    LXPolkitListener* listener;
    GSimpleAsyncResult* result;
    GtkWidget* dlg;
    GtkWidget* id;
    GtkWidget* request;
    GtkWidget* request_label;
    GCancellable* cancellable;
    GAsyncReadyCallback callback;
    gpointer user_data;
    char* cookie;
    char* action_id;
    PolkitAgentSession* session;
};

static void on_cancelled(GCancellable* cancellable, DlgData* data);
static inline void dlg_data_free(DlgData* data);
static void on_dlg_response(GtkDialog* dlg, int response, DlgData* data);
static void on_user_changed(GtkComboBox* id_combo, DlgData* data);

inline void dlg_data_free(DlgData* data)
{
    DEBUG("dlg_data_free");
    gtk_widget_destroy(data->dlg);

    g_signal_handlers_disconnect_by_func(data->cancellable, on_cancelled, data);
    g_object_unref(data->cancellable);
    g_object_unref(data->session);
    g_object_unref(data->result);
    g_free(data->action_id);
    g_free(data->cookie);
    g_slice_free(DlgData, data);
}

static void on_completed(PolkitAgentSession* session, gboolean authorized, DlgData* data)
{
    DEBUG("on_complete");
    gtk_widget_set_sensitive(data->dlg, TRUE);

    if(!authorized && !g_cancellable_is_cancelled(data->cancellable))
    {
        show_msg(data->dlg, GTK_MESSAGE_ERROR, _("Authentication failed!\nWrong password?"));
        /* initiate a new session */
        g_object_unref(data->session);
        data->session = NULL;
        gtk_entry_set_text(data->request, "");
        gtk_widget_grab_focus(data->request);
        on_user_changed(data->id, data);
        return;
    }
    g_simple_async_result_complete(data->result);
    dlg_data_free(data);
}

static void on_request(PolkitAgentSession* session, gchar* request, gboolean echo_on, DlgData* data)
{
    const char* msg;
    DEBUG("on_request: %s", request);
    if(strcmp("Password: ", request) == 0)
        msg = _("Password: ");
    else
        msg = request;
    gtk_label_set_text(data->request_label, msg);
    gtk_entry_set_visibility(data->request, echo_on);
}

static void on_show_error(PolkitAgentSession* session, gchar* text, DlgData* data)
{
    DEBUG("on error: %s", text);
    show_msg(data->dlg, GTK_MESSAGE_ERROR, text);
}

static void on_show_info(PolkitAgentSession* session, gchar* text, DlgData* data)
{
    DEBUG("on info: %s", text);
    show_msg(data->dlg, GTK_MESSAGE_INFO, text);
}

void on_dlg_response(GtkDialog* dlg, int response, DlgData* data)
{
    DEBUG("on_response: %d", response);
    if(response == GTK_RESPONSE_OK)
    {
        const char* request = gtk_entry_get_text(data->request);
        polkit_agent_session_response(data->session, request);
        gtk_widget_set_sensitive(data->dlg, FALSE);
    }
    else
        g_cancellable_cancel(data->cancellable);
}

void on_cancelled(GCancellable* cancellable, DlgData* data)
{
    DEBUG("on_cancelled");
    if(data->session)
        polkit_agent_session_cancel(data->session);
    else
        dlg_data_free(data);
}

/* A different user is selected. */
static void on_user_changed(GtkComboBox* id_combo, DlgData* data)
{
    GtkTreeIter it;
    GtkTreeModel* model = gtk_combo_box_get_model(id_combo);
    DEBUG("on_user_changed");
    if(gtk_combo_box_get_active_iter(id_combo, &it))
    {
        PolkitIdentity* id;
        gtk_tree_model_get(model, &it, 1, &id, -1);
        if(data->session) /* delete old session object */
        {
            /* prevent receiving completed signal. */
            g_signal_handlers_disconnect_matched(data->session, G_SIGNAL_MATCH_DATA, 0, 0, NULL, NULL, data);
            polkit_agent_session_cancel(data->session);
            g_object_unref(data->session);
        }
        /* create authentication session for currently selected user */
        data->session = polkit_agent_session_new(id, data->cookie);
        g_object_unref(id);
        g_signal_connect(data->session, "completed", G_CALLBACK(on_completed), data);
        g_signal_connect(data->session, "request", G_CALLBACK(on_request), data);
        g_signal_connect(data->session, "show-error", G_CALLBACK(on_show_error), data);
        g_signal_connect(data->session, "show-info", G_CALLBACK(on_show_info), data);
        polkit_agent_session_initiate(data->session);
    }
}

static void initiate_authentication(PolkitAgentListener  *listener,
                                    const gchar          *action_id,
                                    const gchar          *message,
                                    const gchar          *icon_name,
                                    PolkitDetails        *details,
                                    const gchar          *cookie,
                                    GList                *identities,
                                    GCancellable         *cancellable,
                                    GAsyncReadyCallback   callback,
                                    gpointer              user_data)
{
    GtkBuilder* b = gtk_builder_new();
    GtkWidget *icon, *msg, *detail, *id_hbox;
    GList* l;
    DlgData* data = g_slice_new0(DlgData);
    DEBUG("init_authentication");
    DEBUG("action_id = %s", action_id);
#ifdef G_ENABLE_DEBUG
    char** p;
    for(p = polkit_details_get_keys(details);*p;++p)
        DEBUG("%s: %s", *p, polkit_details_lookup(details, *p));
#endif
    data->listener = (LXPolkitListener*)listener;
    data->result = g_simple_async_result_new(listener, callback, user_data, initiate_authentication);

    data->action_id = g_strdup(action_id);
    data->cancellable = (GCancellable*)g_object_ref(cancellable);
    data->callback = callback;
    data->user_data = user_data;
    data->cookie = g_strdup(cookie);

    /* create the dialog, load from GtkBuilder ui definition file. */
    gtk_builder_add_from_file(b, PACKAGE_UI_DIR "/lxpolkit.ui", NULL);
    data->dlg = (GtkWidget*)gtk_builder_get_object(b, "dlg");
    icon = (GtkWidget*)gtk_builder_get_object(b, "icon");
    msg = (GtkWidget*)gtk_builder_get_object(b, "msg");
    detail = (GtkWidget*)gtk_builder_get_object(b, "detail");
    id_hbox = (GtkWidget*)gtk_builder_get_object(b, "id_hbox");
    data->id = (GtkWidget*)gtk_builder_get_object(b, "id");
    data->request = (GtkWidget*)gtk_builder_get_object(b, "request");
    data->request_label = (GtkWidget*)gtk_builder_get_object(b, "request_label");
    g_object_unref(b);

    g_signal_connect(data->dlg, "response", G_CALLBACK(on_dlg_response), data);
    g_signal_connect(cancellable, "cancelled", G_CALLBACK(on_cancelled), data);

    gtk_dialog_set_alternative_button_order(GTK_DIALOG(data->dlg), GTK_RESPONSE_OK, GTK_RESPONSE_CANCEL);
    gtk_dialog_set_default_response(GTK_DIALOG(data->dlg), GTK_RESPONSE_OK);
    gtk_window_set_icon_name(GTK_WINDOW(data->dlg), GTK_STOCK_DIALOG_AUTHENTICATION);

    /* set dialog icon */
    if(icon_name && *icon_name)
        gtk_image_set_from_icon_name(GTK_IMAGE(icon), icon_name, GTK_ICON_SIZE_DIALOG);
    else
        gtk_image_set_from_stock(GTK_IMAGE(icon), GTK_STOCK_DIALOG_AUTHENTICATION, GTK_ICON_SIZE_DIALOG);

    /* set message prompt */
    gtk_label_set_text(GTK_LABEL(msg), message);

    /* create combo box for user selection */
    if( identities )
    {
        GtkListStore* store = gtk_list_store_new(2, G_TYPE_STRING, G_TYPE_OBJECT);
        g_signal_connect(data->id, "changed", G_CALLBACK(on_user_changed), data);
        for(l = identities; l; l=l->next)
        {
            PolkitIdentity* id = (PolkitIdentity*)l->data;
            char* name;
            if(POLKIT_IS_UNIX_USER(id))
            {
                struct passwd* pwd = getpwuid(polkit_unix_user_get_uid(POLKIT_UNIX_USER(id)));
                gtk_list_store_insert_with_values(store, NULL, -1, 0, pwd->pw_name, 1, id, -1);
            }
            else if(POLKIT_IS_UNIX_GROUP(id))
            {
                struct group* grp = getgrgid(polkit_unix_group_get_gid(POLKIT_UNIX_GROUP(id)));
                char* str = g_strdup_printf(_("Group: %s"), grp->gr_name);
                gtk_list_store_insert_with_values(store, NULL, -1, 0, str, 1, id, -1);
                g_free(str);
            }
            else
            {
                /* FIXME: what's this? */
                char* str = polkit_identity_to_string(id);
                gtk_list_store_insert_with_values(store, NULL, -1, 0, str, 1, id, -1);
                g_free(str);
            }
        }
        gtk_combo_box_set_model(data->id, GTK_TREE_MODEL(store));
        g_object_unref(store);
        /* select the fist user in the list */
        gtk_combo_box_set_active(data->id, 0);
    }
    else
    {
        DEBUG("no identities list, is this an error?");
        gtk_widget_hide(id_hbox);
        g_simple_async_result_complete_in_idle(data->result);
        dlg_data_free(data);
        return;
    }
    gtk_window_present(GTK_WINDOW(data->dlg));
}

static gboolean initiate_authentication_finish(PolkitAgentListener  *listener,
                                              GAsyncResult         *res,
                                              GError              **error)
{
    LXPolkitListener* self = (LXPolkitListener*)listener;
    DEBUG("init_authentication_finish");
    return !g_simple_async_result_propagate_error(G_SIMPLE_ASYNC_RESULT(res), error);
}

static void lxpolkit_listener_class_init(LXPolkitListenerClass *klass)
{
    GObjectClass *g_object_class;
    PolkitAgentListenerClass* pkal_class;
    g_object_class = G_OBJECT_CLASS(klass);
    g_object_class->finalize = lxpolkit_listener_finalize;

    pkal_class = POLKIT_AGENT_LISTENER_CLASS(klass);
    pkal_class->initiate_authentication = initiate_authentication;
    pkal_class->initiate_authentication_finish = initiate_authentication_finish;
}


static void lxpolkit_listener_finalize(GObject *object)
{
    LXPolkitListener *self;

    g_return_if_fail(object != NULL);
    g_return_if_fail(IS_LXPOLKIT_LISTENER(object));

    self = LXPOLKIT_LISTENER(object);

    G_OBJECT_CLASS(lxpolkit_listener_parent_class)->finalize(object);
}


static void lxpolkit_listener_init(LXPolkitListener *self)
{
}


PolkitAgentListener *lxpolkit_listener_new(void)
{
    return g_object_new(LXPOLKIT_LISTENER_TYPE, NULL);
}
