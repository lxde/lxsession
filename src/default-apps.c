/*
 *      default-apps.c
 *
 *      Copyright 2011 Julien Lavergne <gilir@ubuntu.com>
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

#include <stdio.h>
#include <glib.h>
#include <wordexp.h> /* for shell expansion */

#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>

static GPid run_app( const char* cmd, gboolean guarded );

static void on_child_exit( GPid pid, gint status, gchar* cmd )
{
    int sig = WTERMSIG( status );
    /* if the term signal is not SIGTERM or SIGKILL, this might be a crash! */
    if( sig && sig != SIGTERM && sig != SIGKILL )
        run_app( cmd, TRUE );
}

/* Returns pid if succesful, returns -1 if errors happen. */
static GPid run_app( const char* cmd, gboolean guarded )
{
    GPid pid = -1;
    wordexp_t we;
    GSpawnFlags flags = guarded ? G_SPAWN_DO_NOT_REAP_CHILD|G_SPAWN_SEARCH_PATH : G_SPAWN_SEARCH_PATH;

    if( wordexp(cmd, &we, 0) == 0)
    {
        g_spawn_async( NULL, we.we_wordv, NULL, flags, NULL, NULL, &pid, NULL );
        wordfree(&we);
    }

    if(guarded && pid > 0)
    {
        g_child_watch_add_full( G_PRIORITY_DEFAULT_IDLE, pid,
                                (GChildWatchFunc)on_child_exit,
                                g_strdup( cmd ), (GDestroyNotify)g_free );
    }
    return pid;
}

void load_default_apps( const char* filename )
{
    char buf[1024];
    int len;
    FILE* file = fopen( filename, "r" );
    if( file )
    {
        while ( fgets( buf, sizeof(buf) - 2, file ) )
        {
            if ( buf[0] == '\0' || buf[0] == '\n' || buf[0] == '#' )
                continue;  /* a comment */
            len = strlen ( buf );
            if( buf[ len - 1 ] == '\n' ) /* remove the '\n' at the end of line */
            {
                --len;
                buf[ len ] = '\0';
            }
            switch(buf[0])
            {
            case '@': /* if the app should be restarted on crash */
                run_app( buf + 1, TRUE );
                break;
            default: /* just run the program */
                run_app( buf, FALSE );
            }
        }
        fclose( file );
    }
}

/* Functions for specific default apps */
void app_command_safe_window_manager()
{

    GList *list = NULL, *li = NULL;

    /* List all possible window-manager */
    list = g_list_append (list, "openbox-lxde");
    list = g_list_append (list, "openbox-lubuntu");
    list = g_list_append (list, "openbox");
    list = g_list_append (list, "compiz");
    list = g_list_append (list, "kwin");
    list = g_list_append (list, "mutter");
    list = g_list_append (list, "fluxbox");
    list = g_list_append (list, "metacity");
    list = g_list_append (list, "xfwin");
    list = g_list_append (list, "matchbox");

    for(li = list; li!= NULL; li = g_list_next(li)) 
    {
        char *program = li->data;
        if (g_find_program_in_path(program))
        {
            run_app(program, TRUE);
            break;
        }
        /*TODO Log error message that no window manager is available*/
    }
    //g_list_free (list);
    //g_list_free (li);

}

gboolean app_command_window_manager(GKeyFile* kf)
{
    gchar* window_manager = NULL;
    GPid statut;
    gboolean ret = FALSE;

    window_manager = g_key_file_get_string( kf, "Session", "window_manager", NULL);

    if (window_manager == "safe")
    {
        app_command_safe_window_manager();
    /* Include special case
    case "window-manager":
        break;
    */
    }
    else
    {
        statut = run_app(window_manager, TRUE);
        if (statut == -1)
        {
            /* Problem when launching openbox-lxde, switch to safe mode */
            g_key_file_set_string( kf, "Session", "window_manager", "safe");
            ret = TRUE;
            /* TODO Log message */
            app_command_safe_window_manager();
        }
    }
    return ret;

}

gboolean app_command_panel(GKeyFile* kf)
{
    gchar* panel = NULL, * panel_session = NULL, * command = NULL;
    GPid statut;

    panel = g_key_file_get_string( kf, "Session", "panel/program", NULL);
    panel_session = g_key_file_get_string( kf, "Session", "panel/session", NULL);

    if (panel != NULL)
    {
        if (panel_session != NULL)
        {
            if (g_strcmp0 (panel,"lxpanel"))
            {
                command = g_strconcat("lxpanel"," ","--profile"," ", panel_session, NULL);
                statut = run_app(command, TRUE);
                g_free(command);
            }
            else
            {
                statut = run_app(panel, TRUE);
            }
        }
        else 
        {
            statut = run_app(panel, TRUE);
        }
    }
    return FALSE;

}

gboolean app_command_screensaver(GKeyFile* kf)
{
    gchar* ss_prog = NULL, * command = NULL;
    GPid statut;

    ss_prog = g_key_file_get_string( kf, "Session", "screensaver/program", NULL);

    if (ss_prog != NULL)
    {
        if (g_strcmp0 (ss_prog,"xscreensaver"))
        {
            command = g_strconcat("xscreensaver"," ","-no-splash", NULL);
            statut = run_app(command, TRUE);
            g_free(command);
        }
        else
        {
            statut = run_app(ss_prog, TRUE);
        }

    g_free(ss_prog);

    }

    return FALSE;

}

gboolean app_command_power_manager(GKeyFile* kf)
{
    gchar* power_prog = NULL;
    GPid statut;

    power_prog = g_key_file_get_string( kf, "Session", "power-manager/program", NULL);

    if (power_prog != NULL)
    {
        statut = run_app(power_prog, TRUE);
        g_free(power_prog);

    /* Implement fallback */

    }

    return FALSE;
}

gboolean app_command_file_manager(GKeyFile* kf)
{
    gchar* fm_prog = NULL, * fm_session = NULL, * command = NULL;
    GPid statut;

    fm_prog = g_key_file_get_string( kf, "Session", "file-manager/program", NULL);
    fm_session = g_key_file_get_string( kf, "Session", "file-manager/session", NULL);

    if (fm_prog != NULL)
    {
        if (fm_session != NULL)
        {
            if (g_strcmp0 (fm_prog,"pcmanfm"))
            {
                command = g_strconcat("pcmanfm"," ","--profile"," ", fm_session, NULL);
                statut = run_app(command, TRUE);
                g_free(command);
            }
            else
            {
                statut = run_app(fm_prog, TRUE);
            }
        }
        else
        {
            statut = run_app(fm_prog, TRUE);
        }
    }
    return FALSE;

}
