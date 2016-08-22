/*
 *      lxsession-edit.c
 *
 *      Copyright 2008 PCMan <pcman.tw@gmail.com>
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

#include <gtk/gtk.h>
#include <glib/gi18n.h>
#include <stdio.h>
#include <string.h>

#include "lxsession-edit-common.h"

#define CONFIG_FILE_NAME    "desktop.conf"

int main(int argc, char** argv)
{
    GtkBuilder *builder;
    GtkWidget *dlg, *autostarts, *wm, *adv_page;
    GKeyFile* kf;
    char *cfg, *wm_cmd = NULL;
    gboolean loaded;

    const char* session_name = NULL;

#ifdef ENABLE_NLS
    bindtextdomain ( GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR );
    bind_textdomain_codeset ( GETTEXT_PACKAGE, "UTF-8" );
    textdomain ( GETTEXT_PACKAGE );
#endif

    gtk_init( &argc, &argv );
    if( argc > 1 )
        session_name = argv[1];
    else
    {
        session_name = g_getenv("XDG_CURRENT_DESKTOP");
        if(!session_name)
        {
            session_name = g_getenv("DESKTOP_SESSION");
            if( G_UNLIKELY(!session_name) )
                session_name = "LXDE";
        }
    }

    builder = gtk_builder_new();
    if( !gtk_builder_add_from_file( builder, PACKAGE_UI_DIR "/lxsession-edit.ui", NULL ) )
        return 1;

    dlg = (GtkWidget*) gtk_builder_get_object( builder, "dlg" );
    autostarts = (GtkWidget*) gtk_builder_get_object( builder, "autostarts" );
    adv_page = (GtkWidget*) gtk_builder_get_object( builder, "adv_page" );
    wm = (GtkWidget*) gtk_builder_get_object( builder, "wm" );
    g_object_unref(builder);

    gtk_dialog_set_alternative_button_order((GtkDialog*)dlg, GTK_RESPONSE_OK, GTK_RESPONSE_CANCEL, -1);

    /* Set icon name for main (dlg) window so it displays in the panel. */
    gtk_window_set_icon_name(GTK_WINDOW(dlg), "preferences-desktop");

    /* autostart list */
    init_list_view((GtkTreeView*)autostarts);
    load_autostart(session_name);
    gtk_tree_view_set_model( (GtkTreeView*)autostarts, (GtkTreeModel*)get_autostart_list() );

    kf = g_key_file_new();

    /* if we are running under LXSession */
    if( g_getenv("_LXSESSION_PID") )
    {
        /* wm settings (only show this when we are under lxsession) */
        cfg = g_build_filename( g_get_user_config_dir(), "lxsession", session_name, CONFIG_FILE_NAME, NULL );
        loaded = g_key_file_load_from_file(kf, cfg, 0, NULL);
        if( !loaded )
        {
            const char* const *dirs = g_get_system_config_dirs();
            const char* const *dir;
            g_free(cfg);
            for( dir = dirs; *dir; ++dir )
            {
                cfg = g_build_filename( *dir, "lxsession", session_name, CONFIG_FILE_NAME, NULL );
                loaded = g_key_file_load_from_file(kf, cfg, 0, NULL);
                g_free( cfg );
                if( loaded )
                    break;
            }
        }
        if( loaded )
            wm_cmd = g_key_file_get_string(kf, "Session", "windows_manager/command", NULL);

        if( ! wm_cmd || !*wm_cmd )
        {
            g_free(wm_cmd);
            /* If it's our favorite, LXDE */
            if( strcmp(session_name, "LXDE") == 0 )
                wm_cmd = g_strdup("openbox-lxde");
            else
                wm_cmd = g_strdup("openbox");
        }
        gtk_entry_set_text((GtkEntry*)wm, wm_cmd);
    }
    else
    {
        gtk_widget_destroy(adv_page);
        wm = adv_page = NULL;
        wm_cmd = NULL;
    }

    if( gtk_dialog_run((GtkDialog*)dlg) == GTK_RESPONSE_OK )
    {
        save_autostart(session_name);

        if( wm ) /* if wm settings is available. */
        {
            char* dir;
            dir = g_build_filename( g_get_user_config_dir(), "lxsession", session_name, NULL );
            g_mkdir_with_parents( dir, 0700 );
            cfg = g_build_filename( dir, "desktop.conf", NULL );
            g_free( dir );
            wm_cmd = (char*)gtk_entry_get_text((GtkEntry*)wm);
            if( wm_cmd )
            {
                char* data;
                gsize len;
                g_key_file_set_string( kf, "Session", "windows_manager/command", wm_cmd );
                data = g_key_file_to_data(kf, &len, NULL);
                g_file_set_contents(cfg, data, len, NULL);
            }
        }
    }
    g_key_file_free(kf);

    gtk_widget_destroy(dlg);
    return 0;
}
