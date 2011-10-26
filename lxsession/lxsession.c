/*
 *      lxsession.c
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

#include <stdio.h>
#include <glib.h>
#include <gtk/gtk.h>

#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>

#include "lxsession.h"
#include "xevent.h"
#include "settings-daemon.h"
#include "xdg-autostart.h"
#include "default-apps.h"


static gboolean no_settings = FALSE; /* disable settings daemon */
static gboolean reload_settings = FALSE; /* reload settings daemon */
static gboolean no_autostart = FALSE; /* no autostart */

gboolean config_changed = FALSE; /* Set to TRUE if need to save conf file */

static GMainLoop* main_loop = NULL;
static const char *display_name = NULL;
char* window_manager = NULL; /* will be accessed by settings-daemon.c */

/* name of environment variables */
/* Disable not used
static char sm_env[] = "SESSION_MANAGER";
*/
static char display_env[] = "DISPLAY";
static char pid_env[] = "_LXSESSION_PID";

static char prog_name[]="lxsession";
static char autostart_filename[]="autostart";

const char *session_name = NULL;
const char* de_name = NULL;

static void start_session(GKeyFile* kf);

static void sig_term_handler ( int sig )
{
    g_main_loop_quit(main_loop);
}

void lxsession_quit()
{
    g_main_loop_quit(main_loop);
}

static void register_signals()
{
    /* Ignore SIGPIPE */
    signal( SIGPIPE, SIG_IGN );

#if 0
    action.sa_handler = g_child_watch_signal_handler;
    sigemptyset (&action.sa_mask);
    action.sa_flags = SA_RESTART | SA_NOCLDSTOP;
    sigaction (SIGCHLD, &action, NULL);
#endif

    /* If we get a SIGTERM, do logout */
    signal( SIGTERM, sig_term_handler );
}

GKeyFile* load_session_config( const char* config_filename )
{
    const gchar* const *dirs = g_get_system_config_dirs();
    const gchar* const *dir;
    GKeyFile* kf = g_key_file_new();
    char* filename;
    gboolean ret;

    /* load user-specific session config */
    filename = g_build_filename( g_get_user_config_dir(), prog_name, session_name, config_filename, NULL );
    ret = g_key_file_load_from_file(kf, filename, 0, NULL);
    g_free( filename );

	if( ! ret ) /* user specific file is not found */
	{
		/* load system-wide session config files */
		for( dir = dirs; *dir; ++dir )
		{
			filename = g_build_filename( *dir, prog_name, session_name, config_filename, NULL );
			ret = g_key_file_load_from_file(kf, filename, 0, NULL);
			g_free( filename );
			if(ret)
				break;
		}
	}

	if( G_UNLIKELY(!ret) )
	{
		g_key_file_free(kf);
		return NULL;
	}
	return kf;
}

<<<<<<< HEAD
static void on_child_exit( GPid pid, gint status, gchar* cmd )
{
    int sig = WTERMSIG( status );
    /* if the term signal is not SIGTERM or SIGKILL, this might be a crash! */
    if( sig && sig != SIGTERM && sig != SIGKILL )
        run_app( cmd, TRUE );
}

/* Returns pid if succesful, returns -1 if errors happen. */
GPid run_app( const char* cmd, gboolean guarded )
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

static gboolean load_default_apps( const char* filename )
{
    char buf[1024];
    int len;
    
    FILE* file = fopen( filename, "r" );
    if( !file )
        return FALSE;
    
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
    return TRUE;
}

/*
 * system wide default config is /etc/xdg/lxsession/SESSION_NAME/desktop.conf
 * system wide default apps are listed in /etc/xdg/lxsession/SESSION_NAME/autostart
 */
void start_session(GKeyFile* config)
{
    const gchar* const *dirs = g_get_system_config_dirs();
    const gchar* const *dir;
    char* filename;

    /* run window manager first */
    config_changed = app_command_window_manager(config);

    /* run the panel if it's set */
    if (g_key_file_get_string( kf, "Session", "panel/program", NULL))
    {
        app_command_panel(config);
    }

    /* run the screensaver if it's set */
    if (g_key_file_get_string( kf, "Session", "screensaver/program", NULL))
    {
        app_command_screensaver(config);
    }

    /* run the power-manager if it's set */
    if (g_key_file_get_string( kf, "Session", "power-manager/program", NULL))
    {
        app_command_power_manager(config);
    }

    /* run the file-manager if it's set */
    if (g_key_file_get_string( kf, "Session", "file-manager/program", NULL))
    {
        app_command_file_manager(config);
    }


    if( G_UNLIKELY( !no_autostart ) )

    /* load system-wide default apps */
    for( dir = dirs; *dir; ++dir )
    {
        filename = g_build_filename( *dir, prog_name, session_name, autostart_filename, NULL );
        
        /*  g_get_system_config_dirs() may return several directories,
            so ensures that we don't run processes twice. */
        if( load_default_apps( filename ) )
        {
            g_free( filename );
            break;
        }
        g_free( filename );
    }
    
    /* load user-specific default apps */
    filename = g_build_filename( g_get_user_config_dir(), prog_name, session_name, autostart_filename, NULL );
    load_default_apps( filename );
    g_free( filename );

    /* Support autostart spec of freedesktop.org if not disable*/
    xdg_autostart( session_name );

}

static void parse_options(int argc, char** argv)
{
    int  i;
    for ( i = 1; i < argc; ++i )
    {
        if ( argv[i][0] == '-' )
        {
            switch ( argv[i][1] )
            {
            case 'd':     /* -display */
                if ( ++i >= argc ) goto usage;
                display_name = argv[i];
                g_setenv( display_env, display_name, TRUE );
                continue;
            case 's':     /* -session */
                if ( ++i >= argc ) goto usage;
                session_name = argv[i];
                continue;
            case 'n': /* disable xsettings daemon */
				no_settings = TRUE;
                continue;
            case 'e': /* DE name */
                if ( ++i >= argc ) goto usage;
                de_name = argv[i];
                continue;
            case 'r':
				reload_settings = TRUE;
				continue;
            case 'a': /* autostart disable */
                no_autostart = TRUE;
                continue;
			default:
				goto usage;
            }
        }
	}
	return;
usage:
        fprintf ( stderr,
                  "Usage:  lxsession [OPTIONS...]\n"
				  "\t-d NAME\tspecify name of display (optional)\n"
				  "\t-s NAME\tspecify name of the desktop session profile\n"
                  "\t-e NAME\tspecify name of DE, such as LXDE, GNOME, or XFCE.\n"
				  "\t-r\t reload configurations (for Xsettings daemon)\n"
				  "\t-n\t disable Xsettings daemon support\n"
				  "\t-a\t autostart applications disable (window-manager mode only) \n" );
        exit(1);
}

int main(int argc, char** argv)
{
    const char *pid_str;
    char str[ 16 ];
	GKeyFile* kf;
    GObject *clipboard_daemon = NULL;

    gtk_init (&argc, &argv);

    pid_str = g_getenv(pid_env);

    display_name = g_getenv( display_env );
    if( ! display_name )
    {
        display_name = ":0.0";
        g_setenv( display_env, display_name, TRUE );
    }

    parse_options(argc, argv);

    /* initialize X-related stuff and connect to X Display */
    if( G_UNLIKELY(! xevent_init() ) )
        return 1;

    /* send command to existing daemon to reload settings */
    if( G_UNLIKELY( reload_settings ) )
    {
        send_internal_command( LXS_RELOAD );
        return 0;
    }
	else if( G_UNLIKELY( !single_instance_check()) )
	{
		/* only one instance is allowed for each X. */
		fprintf(stderr, "Only one lxsession can be executed at a time");
		return 1;
	}

    /* set pid */
    g_snprintf( str, 16, "%d", getpid() );
    g_setenv(pid_env, str, TRUE );

    main_loop = g_main_loop_new( NULL, TRUE );

	/* setup signal handlers */
    register_signals();

    if ( G_UNLIKELY(!session_name) )
        session_name = "LXDE";
    g_setenv( "DESKTOP_SESSION", session_name, TRUE );

    if ( G_UNLIKELY(!de_name) )
        de_name = session_name;
    g_setenv( "XDG_CURRENT_DESKTOP", de_name, TRUE );

    /* FIXME: load environment variables? */

	/* Load desktop session config file */
	kf = load_session_config(CONFIG_FILE_NAME);
	if( !kf )
	{
		xevent_finalize();
		return 1;
	}

    if( G_LIKELY(!no_settings) )
        start_settings_daemon(kf);

    if (g_getenv ("XFSETTINGSD_NO_CLIPBOARD") == NULL)
    {
        clipboard_daemon = g_object_new (GSD_TYPE_CLIPBOARD_MANAGER, NULL);
        if (!gsd_clipboard_manager_start (GSD_CLIPBOARD_MANAGER (clipboard_daemon), FALSE))
        {
            g_object_unref (G_OBJECT (clipboard_daemon));
            clipboard_daemon = NULL;

            g_printerr ("Another clipboard manager is already running.");
        }
    }

	g_key_file_free(kf);

    /* start desktop session and load autostart applications */
    start_session(kf);

    if (config_changed == TRUE)
    {
        char* rel_path = g_strconcat("lxsession/", session_name, "/desktop.conf", NULL);
        char* dir = g_build_filename(g_get_user_config_dir(), "lxsession/", session_name);
        char* user_config_file = g_build_filename(g_get_user_config_dir(), rel_path, NULL);
        char* buf;
        int len;

        buf = g_key_file_to_data( kf, &len, NULL );

        if (!g_file_test (dir, G_FILE_TEST_IS_DIR))
        {
            g_mkdir_with_parents((dir), 0700);
        }

        g_file_set_contents(user_config_file, buf, len, NULL);
        g_free(buf);
        g_free(dir);
        g_free(user_config_file);
    }

    g_key_file_free(kf);

    g_main_loop_run( main_loop );
    g_main_loop_unref( main_loop );

    if (G_LIKELY (clipboard_daemon != NULL))
    {
        gsd_clipboard_manager_stop (GSD_CLIPBOARD_MANAGER (clipboard_daemon));
        g_object_unref (G_OBJECT (clipboard_daemon));
    }

	xevent_finalize();

    return 0;
}
