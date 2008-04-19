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

#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>

#include "autostart.h"

static GMainLoop* main_loop = NULL;
static const char *display_name = NULL;
static char* window_manager = NULL;

/* name of environment variables */
static char sm_env[] = "SESSION_MANAGER";
static char display_env[] = "DISPLAY";
static char pid_env[] = "_LXSESSION_PID";

static char prog_name[]="lxsession";
static char config_filename[]="config";
static char autostart_filename[]="autostart";

const char *session_name = NULL;

static void sig_term_handler ( int sig )
{
    g_main_loop_quit(main_loop);
}

static void register_signals()
{
    /* Ignore SIGPIPE */
    signal( SIGPIPE, SIG_IGN );

    /* If child process dies, call our handler */
    /* signal( SIGCHLD, sig_child_handler ); */

    /* If we get a SIGTERM, do logout */
    signal( SIGTERM, sig_term_handler );
}

static void load_config( GKeyFile* kf, const char* filename )
{
    if( g_key_file_load_from_file( kf, filename, 0, NULL ) )
    {
        char* str;
        if( str = g_key_file_get_string( kf, "Session", "window_manager", NULL ) )
        {
            g_free( window_manager );
            window_manager = str;
        }
    }
}

static void run_guarded_app( const char* cmd );
static void on_child_exit( GPid pid, int status, const char* cmd )
{
    int sig = WTERMSIG( status );
    /* if the term signal is not SIGTERM or SIGKILL, this might be a crash! */
    if( sig && sig != SIGTERM && sig != SIGKILL )
        run_guarded_app( cmd );
}

static void run_guarded_app( const char* cmd )
{
    char** argv;
    int argc;
    GPid pid;
    if( g_shell_parse_argv( cmd, &argc, &argv, NULL ) )
    {
        if( g_spawn_async( NULL, argv, NULL,
                G_SPAWN_DO_NOT_REAP_CHILD|
                G_SPAWN_SEARCH_PATH|
                G_SPAWN_STDOUT_TO_DEV_NULL|
                G_SPAWN_STDERR_TO_DEV_NULL,
                NULL, NULL, &pid, NULL ) )
        {
            g_child_watch_add_full( G_PRIORITY_DEFAULT_IDLE, pid,
                                                (GChildWatchFunc)on_child_exit,
                                                g_strdup( cmd ), (GDestroyNotify)g_free );
        }
    }
    g_strfreev( argv );
}

static void load_default_apps( const char* filename )
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
                buf[ len ] = '\0';
                --len;
            }
            if( buf[0] == '@' ) /* if the app should be restarted on crash */
                run_guarded_app( buf + 1 );
            else
                g_spawn_command_line_async( buf, NULL );
        }
        fclose( file );
    }
}

/*
 * system wide default config is /etc/xdg/lxsession/SESSION_NAME/config
 * system wide default apps are listed in /etc/xdg/lxsession/SESSION_NAME/autostart
 */
static void start_session()
{
    FILE *file = NULL;
    const gchar* const *dirs = g_get_system_config_dirs();
    const gchar* const *dir;
    GKeyFile* kf = g_key_file_new();
    char* filename;

    /* load system-wide session config files */
    for( dir = dirs; *dir; ++dir )
    {
        filename = g_build_filename( *dir, prog_name, session_name, config_filename, NULL );
        load_config( kf, filename );
        g_free( filename );
    }
    /* load user-specific session config */
    filename = g_build_filename( g_get_user_config_dir(), prog_name, session_name, config_filename, NULL );
    load_config( kf, filename );
    g_free( filename );

    g_key_file_free( kf );

    /* run window manager first */
    if( G_LIKELY( window_manager ) )
        run_guarded_app( window_manager );

    /* load system-wide default apps */
    for( dir = dirs; *dir; ++dir )
    {
        filename = g_build_filename( *dir, prog_name, session_name, autostart_filename, NULL );
        load_default_apps( filename );
        g_free( filename );
    }
    /* load user-specific default apps */
    filename = g_build_filename( g_get_user_config_dir(), prog_name, session_name, autostart_filename, NULL );
    load_default_apps( filename );
    g_free( filename );

    /* Support autostart spec of freedesktop.org */
    handle_autostart( session_name );
}

int main(int argc, char** argv)
{
    const char *pid_str;
    char str[ 16 ];
    int  i;

    main_loop = g_main_loop_new( NULL, TRUE );

    pid_str = g_getenv(pid_env);

    display_name = g_getenv( display_env );
    if( ! display_name )
    {
        display_name = ":0";
        g_setenv( display_env, display_name, TRUE );
    }

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

            case 'e':
                if( 0 == strcmp( argv[i]+1, "exit" ) )
                {
                    if( pid_str ) /* _LXSESSION_PID has been set */
                    {
                        GPid pid = atoi( pid_str );
                        kill( pid, SIGTERM );
                        return 0;
                    }
                    else
                    {
                        g_print( "Error: LXSession is not running.\n" );
                        return 1;
                    }
                }
            }
        }

usage:
        fprintf ( stderr,
                  "Usage: lxsession [-display display] [-session session_name] [-exit]\n" );
        return 1;
    }

    if( G_UNLIKELY( pid_str ) ) /* _LXSESSION_PID has been set */
    {
        g_print("Error: LXSession is already running\n");
//        return 1;
    }

    g_snprintf( str, 16, "%d", getpid() );
    g_setenv(pid_env, str, TRUE );

    register_signals();

    if ( session_name )
        session_name = "LXDE";

    g_setenv( "DESKTOP_SESSION", session_name, TRUE );

    start_session();

    /*
     * Main loop
     */
    g_main_loop_run( main_loop );
    g_main_loop_unref( main_loop );

    return 0;
}
