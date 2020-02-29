/*
 *      autostart.c - Handle autostart spec of freedesktop.org
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

#include "xdg-autostart.h"

#include <glib.h>
#include <stdio.h>
#include <string.h>

static const char DesktopEntry[] = "Desktop Entry";
const char* de_name = NULL;

#if 0
/*
* Parse Exec command line of app desktop file, and translate
* it into a real command which can be passed to g_spawn_command_line_async().
* file_list is a null-terminated file list containing full
* paths of the files passed to app.
* returned char* should be freed when no longer needed.
*/
static char* translate_app_exec_to_command_line( VFSAppDesktop* app,
                                                 GList* file_list )
{
    const char* pexec = vfs_app_desktop_get_exec( app );
    char* file;
    GList* l;
    gchar *tmp;
    GString* cmd = g_string_new("");
    gboolean add_files = FALSE;

    for( ; *pexec; ++pexec )
    {
        if( *pexec == '%' )
        {
            ++pexec;
            switch( *pexec )
            {
            case 'U':
                for( l = file_list; l; l = l->next )
                {
                    tmp = g_filename_to_uri( (char*)l->data, NULL, NULL );
                    file = g_shell_quote( tmp );
                    g_free( tmp );
                    g_string_append( cmd, file );
                    g_string_append_c( cmd, ' ' );
                    g_free( file );
                }
                add_files = TRUE;
                break;
            case 'u':
                if( file_list && file_list->data )
                {
                    file = (char*)file_list->data;
                    tmp = g_filename_to_uri( file, NULL, NULL );
                    file = g_shell_quote( tmp );
                    g_free( tmp );
                    g_string_append( cmd, file );
                    g_free( file );
                    add_files = TRUE;
                }
                break;
            case 'F':
            case 'N':
                for( l = file_list; l; l = l->next )
                {
                    file = (char*)l->data;
                    tmp = g_shell_quote( file );
                    g_string_append( cmd, tmp );
                    g_string_append_c( cmd, ' ' );
                    g_free( tmp );
                }
                add_files = TRUE;
                break;
            case 'f':
            case 'n':
                if( file_list && file_list->data )
                {
                    file = (char*)file_list->data;
                    tmp = g_shell_quote( file );
                    g_string_append( cmd, tmp );
                    g_free( tmp );
                    add_files = TRUE;
                }
                break;
            case 'D':
                for( l = file_list; l; l = l->next )
                {
                    tmp = g_path_get_dirname( (char*)l->data );
                    file = g_shell_quote( tmp );
                    g_free( tmp );
                    g_string_append( cmd, file );
                    g_string_append_c( cmd, ' ' );
                    g_free( file );
                }
                add_files = TRUE;
                break;
            case 'd':
                if( file_list && file_list->data )
                {
                    tmp = g_path_get_dirname( (char*)file_list->data );
                    file = g_shell_quote( tmp );
                    g_free( tmp );
                    g_string_append( cmd, file );
                    g_free( tmp );
                    add_files = TRUE;
                }
                break;
            case 'c':
                g_string_append( cmd, vfs_app_desktop_get_disp_name( app ) );
                break;
            case 'i':
                /* Add icon name */
                if( vfs_app_desktop_get_icon_name( app ) )
                {
                    g_string_append( cmd, "--icon " );
                    g_string_append( cmd, vfs_app_desktop_get_icon_name( app ) );
                }
                break;
            case 'k':
                /* Location of the desktop file */
                break;
            case 'v':
                /* Device name */
                break;
            case '%':
                g_string_append_c ( cmd, '%' );
                break;
            case '\0':
                goto _finish;
                break;
            }
        }
        else  /* not % escaped part */
        {
            g_string_append_c ( cmd, *pexec );
        }
    }
_finish:
    if( ! add_files )
    {
        g_string_append_c ( cmd, ' ' );
        for( l = file_list; l; l = l->next )
        {
            file = (char*)l->data;
            tmp = g_shell_quote( file );
            g_string_append( cmd, tmp );
            g_string_append_c( cmd, ' ' );
            g_free( tmp );
        }
    }

    return g_string_free( cmd, FALSE );
}
#endif

static void launch_autostart_file( const char* desktop_id, const char* desktop_file, GKeyFile* kf)
{
    if( g_key_file_load_from_file( kf, desktop_file, 0, NULL ) )
    {
        char* exec;
        char** only_show_in, **not_show_in;
        gsize n;

        if( g_key_file_get_boolean( kf, DesktopEntry, "Hidden", NULL ) )
            return;

        /* check if this desktop entry is desktop-specific */
        only_show_in = g_key_file_get_string_list( kf, DesktopEntry, "OnlyShowIn", &n, NULL );
        if( only_show_in )
        {
            /* The format of this list is like:  OnlyShowIn=GNOME;XFCE */
            gsize i = 0;
            for( i = 0; i < n; ++i )
            {
                /* Only start this program if we are in the "OnlyShowIn" list */
                if( 0 == strcmp( de_name, only_show_in[ i ] ) )
                    break;
            }
            if( i >= n )    /* our session name is not found in the list */
            {
                g_strfreev( only_show_in );
                return;   /* read next desktop file */
            }
            g_strfreev( only_show_in );
        }
		else /* OnlyShowIn and NotShowIn cannot be set at the same time. */
		{
			/* check if this desktop entry is not allowed in our session */
			not_show_in = g_key_file_get_string_list( kf, DesktopEntry, "NotShowIn", &n, NULL );
			if( not_show_in )
			{
				/* The format of this list is like:  NotShowIn=KDE;IceWM */
				gsize i = 0;
				for( i = 0; i < n; ++i )
				{
					/* Only start this program if we are in the "OnlyShowIn" list */
					if( 0 == strcmp( de_name, not_show_in[ i ] ) )
						break;
				}
				if( i < n )    /* our session name is found in the "NotShowIn" list */
				{
					g_strfreev( not_show_in );
					return;   /* read next desktop file */
				}
				g_strfreev( not_show_in );
			}
		}

        exec = g_key_file_get_string( kf, DesktopEntry, "TryExec", NULL );
        if( G_UNLIKELY(exec) ) /* If we are asked to tryexec first */
        {
            if( ! g_path_is_absolute( exec ) )
            {
                char* full = g_find_program_in_path( exec );
                g_free( exec );
                exec = full;
            }
            /* If we cannot match the TryExec key with an installed executable program */
            if( ! g_file_test( exec, G_FILE_TEST_IS_EXECUTABLE ) )
            {
                g_free( exec );
                return;   /* bypass this desktop file, and read next */
            }
            g_free( exec );
        }

        /* get the real command line */
        exec = g_key_file_get_string( kf, DesktopEntry, "Exec", NULL );
        if( G_LIKELY(exec) )
        {
            /* according to the spec, the Exec command line should be translated
             *  with some rules, but that's normally for file managers who needs to
             *  pass selected file as arguments. The probability we need this is
             *  very low, so just omit it.
             */

			/* FIXME: Exec key should be handled correctly */

            /* launch the program */
            if( g_spawn_command_line_async( exec, NULL ) )
            {
            }
        }
    }
}

static void get_autostart_files_in_dir( GHashTable* hash, const char* base_dir )
{
    char* dir_path = g_build_filename( base_dir, "autostart", NULL );
    GDir* dir = g_dir_open( dir_path, 0, NULL );

    if( dir )
    {
        char *path;
        const char *name;

        while( (name = g_dir_read_name( dir )) != NULL )
        {
            if(g_str_has_suffix(name, ".desktop"))
            {
                if (g_hash_table_contains( hash, name))
                {
                    /* desktop file already exist in a higher directory, do nothing */
                }
                else
                {
                    path = g_build_filename( dir_path, name, NULL );
                    // printf("%s\n", path);
                    g_hash_table_replace( hash, g_strdup(name), path );
                }
            }
        }
        g_dir_close( dir );
    }
    g_free( dir_path );
}

void xdg_autostart( const char* de_name_arg )
{
    const char* const *dirs = g_get_system_config_dirs();
    const char* const *dir;
    GHashTable* hash = g_hash_table_new_full( g_str_hash, g_str_equal, g_free, g_free );
    de_name = de_name_arg;

    /* get user-specific autostart files */
    get_autostart_files_in_dir( hash, g_get_user_config_dir() );

     /* get system-wide autostart files */
	for( dir = dirs; *dir; ++dir )
		get_autostart_files_in_dir( hash, *dir );

    if( g_hash_table_size( hash ) > 0 )
    {
        GKeyFile* kf = g_key_file_new();
        g_hash_table_foreach( hash, (GHFunc)launch_autostart_file, kf);
        g_key_file_free( kf );
    }

    g_hash_table_destroy( hash );
}
