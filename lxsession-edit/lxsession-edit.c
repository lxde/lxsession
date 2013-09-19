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

#define CONFIG_FILE_NAME    "desktop.conf"

enum {
    COL_ENABLED,
    COL_ICON,
    COL_NAME,
    COL_COMMENT,
    COL_DESKTOP_ID,
    COL_SRC_FILE,
    COL_FLAGS,
    N_COLS
};

enum {
    NONE = 0,
    NOT_SHOW_IN = 1 << 0,
    ONLY_SHOW_IN = 1 << 1,
    ORIGINALLY_ENABLED = 1 << 15
};

static const char* session_name = NULL;
static GtkListStore* autostart_list = NULL;
static const char grp[] = "Desktop Entry";


static gboolean is_desktop_file_enabled(GKeyFile* kf, int *flags)
{
    char** not_show_in;
    char** only_show_in;
    gsize n, i;

    *flags = 0;

    not_show_in = g_key_file_get_string_list(kf, grp, "NotShowIn", &n, NULL);
    if( not_show_in )
    {
        *flags |= NOT_SHOW_IN;
        for( i = 0; i < n; ++i )
        {
            if(strcmp(not_show_in[i], session_name) == 0)
            {
                g_strfreev(not_show_in);
                return FALSE;
            }
        }
        g_strfreev(not_show_in);
    }

    only_show_in = g_key_file_get_string_list(kf, grp, "OnlyShowIn", &n, NULL);
    if( only_show_in )
    {
        *flags |= ONLY_SHOW_IN;
        for( i = 0; i < n; ++i )
            if(strcmp(only_show_in[i], session_name) == 0)
                break;
        g_strfreev(only_show_in);
        if( i >= n )
            return FALSE;
    }

    return TRUE;
}

static gboolean is_desktop_file_valid(GKeyFile* kf)
{
    char* tmp;
    if( g_key_file_get_boolean(kf, grp, "Hidden", NULL) )
        return FALSE;

    if( (tmp = g_key_file_get_string(kf, grp, "Type", NULL)) != NULL )
    {
        if( strcmp(tmp, "Application") )
        {
            g_free(tmp);
            return FALSE;
        }
        g_free(tmp);
    }

    if( (tmp = g_key_file_get_string(kf, grp, "TryExec", NULL)) != NULL )
    {
        char* prg = g_find_program_in_path(tmp);
        g_free(tmp);
        if(!prg)
            return FALSE;
        g_free(prg);
    }
    return TRUE;
}

static void get_autostart_files_in_dir( GHashTable* hash, const char* session_name, const char* base_dir )
{
    char* dir_path = g_build_filename( base_dir, "autostart", NULL );
    GDir* dir = g_dir_open( dir_path, 0, NULL );
    if( dir )
    {
        char *path;
        const char *name;

        while( name = g_dir_read_name(dir) )
        {
            if(g_str_has_suffix(name, ".desktop"))
            {
                path = g_build_filename( dir_path, name, NULL );
                g_hash_table_replace( hash, g_strdup(name), path );
            }
        }
        g_dir_close( dir );
    }
    g_free( dir_path );
}

static void add_autostart_file(char* desktop_id, char* file, GKeyFile* kf)
{
    GtkTreeIter it;
    if( g_key_file_load_from_file( kf, file, 0, NULL ) )
    {
        if( is_desktop_file_valid(kf) )
        {
            char* name = g_key_file_get_locale_string(kf, grp, "Name", NULL, NULL);
            char* icon = g_key_file_get_locale_string(kf, grp, "Icon", NULL, NULL);
            char* comment = g_key_file_get_locale_string(kf, grp, "Comment", NULL, NULL);
            int flags;
            gboolean enabled = is_desktop_file_enabled(kf, &flags);
            if( enabled )
                flags |= ORIGINALLY_ENABLED;
            gtk_list_store_append(autostart_list, &it);
            gtk_list_store_set( autostart_list, &it,
                                COL_ENABLED, enabled,
                                COL_NAME, name,
                                /* COL_ICON, pix, */
                                COL_COMMENT, comment,
                                COL_DESKTOP_ID, desktop_id,
                                COL_SRC_FILE, file,
                                COL_FLAGS, flags,
                                -1 );
            g_free(name);
            g_free(icon);
            g_free(comment);
        }
    }
}

static void load_autostart()
{
    const char* const *dirs = g_get_system_config_dirs();
    const char* const *dir;
    GHashTable* hash = g_hash_table_new_full( g_str_hash, g_str_equal, g_free, g_free );

    /* get system-wide autostart files */
    for( dir = dirs; *dir; ++dir )
        get_autostart_files_in_dir( hash, session_name, *dir );

    /* get user-specific autostart files */
    get_autostart_files_in_dir( hash, session_name, g_get_user_config_dir() );

    if( g_hash_table_size( hash ) > 0 )
    {
        GKeyFile* kf = g_key_file_new();
        g_hash_table_foreach( hash, (GHFunc)add_autostart_file, kf );
        g_key_file_free( kf );
    }
    g_hash_table_destroy( hash );
}

/* FIXME:
 * If the system-wide desktop file can meet our needs,
 * remove the user-specific one instead of changing its key values. */
static void update_enable_state(GKeyFile* kf, gboolean enabled, int flags)
{
    if( flags & NOT_SHOW_IN ) /* the desktop file contains NotShowIn key */
    {
        gsize n, i;
        char** list = g_key_file_get_string_list(kf, grp, "NotShowIn", &n, NULL);
        if( enabled ) /* remove our DE from NotShowIn */
        {
            for( i = 0; i < n; ++i )
            {
                if( strcmp(list[i], session_name) == 0 )
                {
                    g_free(list[i]);
                    memcpy( list + i, list + i + 1, (n-i) * sizeof(char*) );
                    --n;
                    break;
                }
            }
        }
        else /* add our DE to NotShowIn */
        {
            ++n;
            if( list )
                list = g_realloc( list, sizeof(char*) * (n + 1) );
            else
                list = g_new( char*, n + 1 );
            list[n-1] = g_strdup(session_name);
            list[n] = NULL;
        }
        if( n > 0 )
            g_key_file_set_string_list( kf, grp, "NotShowIn", (const gchar * const *) list, n );
        else
            g_key_file_remove_key(kf, grp, "NotShowIn", NULL);
        g_strfreev(list);
    }
    else if( flags & ONLY_SHOW_IN )
    {
        gsize n, i;
        char * * list = g_key_file_get_string_list(kf, grp, "OnlyShowIn", &n, NULL);
        if( enabled ) /* add our DE to OnlyShowIn */
        {
            ++n;
            if( list )
                list = g_realloc( list, sizeof(char*) * (n + 1) );
            else
                list = g_new( char*, n + 1 );
            list[n-1] = g_strdup(session_name);
            list[n] = NULL;
        }
        else /* remove our DE to OnlyShowIn */
        {
            for( i = 0; i < n; ++i )
            {
                if( strcmp(list[i], session_name) == 0 )
                {
                    g_free(list[i]);
                    memcpy( list + i, list + i + 1, (n-i) * sizeof(char*) );
                    --n;
                    break;
                }
            }
        }
        if( n > 0 )
            g_key_file_set_string_list(kf, grp, "OnlyShowIn", (const gchar * const *) list, n );
        else
            g_key_file_remove_key(kf, grp, "OnlyShowIn", NULL);
        g_strfreev(list);
    }
    else
    {
        if( !enabled )
        {
            char* list[2];
            list[0] = (char *) session_name;
            list[1] = NULL;
            g_key_file_set_string_list( kf, grp, "NotShowIn", (const gchar * const *) list, 1);
        }
        else
        {
            /* nothing to do */
        }
    }
}

static void save_autostart()
{
    GtkTreeIter it;
    GKeyFile* kf;
    char* dirname;
    if( ! gtk_tree_model_get_iter_first(GTK_TREE_MODEL(autostart_list), &it) )
        return;

    /* create user autostart dir */
    dirname = g_build_filename(g_get_user_config_dir(), "autostart", NULL);
    g_mkdir_with_parents(dirname, 0700);
    g_free(dirname);

    /* update desktop files in autostart dir */
    kf = g_key_file_new();
    do
    {
        int flags;
        gboolean enabled;
        gtk_tree_model_get( GTK_TREE_MODEL(autostart_list), &it,
                            COL_ENABLED, &enabled,
                            COL_FLAGS, &flags, -1);

        /* enabled state is changed */
        if( enabled != !!(flags & ORIGINALLY_ENABLED) )
        {
            char* desktop_id, *src_file;
            gtk_tree_model_get( GTK_TREE_MODEL(autostart_list), &it,
                                COL_DESKTOP_ID, &desktop_id,
                                COL_SRC_FILE, &src_file,
                                -1);

            /* load the source desktop file */
            if( g_key_file_load_from_file( kf, src_file, G_KEY_FILE_KEEP_TRANSLATIONS, NULL) )
            {
                char* file, *data;
                gsize len;
                /* update enabled state */
                update_enable_state(kf, enabled, flags);
                data = g_key_file_to_data(kf, &len, NULL);
                file = g_build_filename(  g_get_user_config_dir(), "autostart", desktop_id, NULL );
                /* save it to user-specific autostart dir */
                g_debug("src:%s, save to: %s", src_file, file);
                g_file_set_contents(file, data, len, NULL);
                g_free(file);
                g_free(data);
            }
            g_free(desktop_id);
            g_free(src_file);
        }
    }while( gtk_tree_model_iter_next(GTK_TREE_MODEL(autostart_list), &it) );
    g_key_file_free(kf);
}

static void on_enable_toggled(GtkCellRendererToggle* render,
                              char* tp_str, gpointer user_data)
{
    GtkTreePath* tp = gtk_tree_path_new_from_string(tp_str);
    GtkTreeIter it;
    if( gtk_tree_model_get_iter(GTK_TREE_MODEL(autostart_list), &it, tp) )
    {
        gboolean enabled;
        gtk_tree_model_get(GTK_TREE_MODEL(autostart_list), &it, COL_ENABLED, &enabled, -1 );
        gtk_list_store_set(autostart_list, &it, COL_ENABLED, !enabled, -1 );
    }
    gtk_tree_path_free(tp);
}

static void init_list_view( GtkTreeView* view )
{
    GtkTreeViewColumn* col;
    GtkCellRenderer* render;
    autostart_list = gtk_list_store_new(N_COLS,
                                        G_TYPE_BOOLEAN,
                                        GDK_TYPE_PIXBUF,
                                        G_TYPE_STRING,
                                        G_TYPE_STRING,
                                        G_TYPE_STRING,
                                        G_TYPE_STRING,
                                        G_TYPE_INT );

    render = gtk_cell_renderer_toggle_new();
    col = gtk_tree_view_column_new_with_attributes(_("Enabled"), render, "active", COL_ENABLED, NULL );
    gtk_tree_view_append_column(view, col);
    g_signal_connect(render, "toggled", G_CALLBACK(on_enable_toggled), NULL);

    render = gtk_cell_renderer_pixbuf_new();
    col = gtk_tree_view_column_new_with_attributes(_("Application"), render, "pixbuf", COL_ICON, NULL );
    gtk_tree_view_append_column(view, col);

    render = gtk_cell_renderer_text_new();
    gtk_tree_view_column_pack_start( col, render, TRUE );
    gtk_tree_view_column_set_attributes( col, render, "text", COL_NAME, NULL );

    render = gtk_cell_renderer_text_new();
    col = gtk_tree_view_column_new_with_attributes(_("Comment"), render, "text", COL_COMMENT, NULL );
    gtk_tree_view_append_column(view, col);
}

int main(int argc, char** argv)
{
    GtkBuilder *builder;
    GtkWidget *dlg, *autostarts, *wm, *adv_page;
    GKeyFile* kf;
    char *cfg, *wm_cmd = NULL;
    gboolean loaded;

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
    gtk_window_set_icon_name(GTK_WINDOW(dlg), "xfwm4");

    /* autostart list */
    init_list_view((GtkTreeView*)autostarts);
    load_autostart();
    gtk_tree_view_set_model( (GtkTreeView*)autostarts, (GtkTreeModel*)autostart_list );

    /* if we are running under LXSession */
    if( g_getenv("_LXSESSION_PID") )
    {
        /* wm settings (only show this when we are under lxsession) */
        kf = g_key_file_new();
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
        save_autostart();

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
                g_free( wm_cmd );
            }
        }
    }
    g_key_file_free(kf);

    gtk_widget_destroy(dlg);
    return 0;
}
