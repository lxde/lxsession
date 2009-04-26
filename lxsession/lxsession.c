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

typedef struct _ChildWatch
{
    GPid pid;
    gboolean exited;
    int status;
    char* cmd;
}ChildWatch;

#define child_watch_free( cw ) \
    { \
        g_free( cw->cmd ); \
        g_free( cw ); \
    }

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

static GSList* child_watches = NULL;
static int wakeup_pipe[ 2 ];

static void sig_term_handler ( int sig )
{
    /* g_main_loop_quit(main_loop); */
    close( wakeup_pipe[0] );
}

static void sig_child_handler( int sig )
{
    /* notify the main loop that a child process exits */
    write( wakeup_pipe[1], "X", 1 );
}

static void register_signals()
{
    /* Ignore SIGPIPE */
    signal( SIGPIPE, SIG_IGN );

    /* If child process dies, call our handler */
    signal( SIGCHLD, sig_child_handler );

#if 0
  action.sa_handler = g_child_watch_signal_handler;
  sigemptyset (&action.sa_mask);
  action.sa_flags = SA_RESTART | SA_NOCLDSTOP;
  sigaction (SIGCHLD, &action, NULL);
#endif

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

/* Returns pid if succesful, returns -1 if errors happen. */
static GPid run_app( const char* cmd )
{
    char** argv;
    int argc;
    GPid pid = -1;
    if( g_shell_parse_argv( cmd, &argc, &argv, NULL ) )
    {
        g_spawn_async( NULL, argv, NULL,
                G_SPAWN_DO_NOT_REAP_CHILD|
                G_SPAWN_SEARCH_PATH|
                G_SPAWN_STDOUT_TO_DEV_NULL|
                G_SPAWN_STDERR_TO_DEV_NULL,
                NULL, NULL, &pid, NULL );
    }
    g_strfreev( argv );
    return pid;
}

static void on_child_exit( ChildWatch* cw )
{
    int sig = WTERMSIG( cw->status );
    /* if the term signal is not SIGTERM or SIGKILL, this might be a crash! */
    if( sig && sig != SIGTERM && sig != SIGKILL )
    {
        GPid pid = run_app( cw->cmd );
        if( pid < 0 )   /* error, remove the watch */
        {
            child_watches = g_slist_remove( child_watches, cw );
            child_watch_free( cw );
        }
        else
        {
            cw->pid = pid;
            cw->exited = FALSE;
            cw->status = 0;            
        }
    }
}

static void add_child_watch( GPid pid, const char* cmd )
{
    ChildWatch* cw = g_new0( ChildWatch, 1 );
    cw->pid = pid;
    cw->cmd = g_strdup( cmd );
    child_watches = g_slist_prepend( child_watches, cw );
}

static void run_guarded_app( const char* cmd )
{
    GPid pid = run_app( cmd );
    if( pid > 0 )
    {
        add_child_watch( pid, cmd );
        /*
        g_child_watch_add_full( G_PRIORITY_DEFAULT_IDLE, pid,
                                            (GChildWatchFunc)on_child_exit,
                                            g_strdup( cmd ), (GDestroyNotify)g_free );
        */
    }
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

static void dispatch_child_watches()
{
    GSList* l;
    ChildWatch* cw;
    int status;

    for( l = child_watches; l; l = l->next )
    {
        cw = (ChildWatch*)l->data;
        if (waitpid (cw->pid, &status, WNOHANG) > 0)
        {
            cw->status = status;
            cw->exited = TRUE;
            on_child_exit( cw );
        }
    }
}

int main(int argc, char** argv)
{
    const char *pid_str;
    char str[ 16 ];
    int  i;

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
        g_error("LXSession is already running\n");
        return 1;
    }

    if( pipe( wakeup_pipe ) < 0 )
        return 1;

    /*
     *  NOTE:
     *  g_main_loop has some weird problems when child watch is the only event source.
     *  It seems that in this situation glib does busy loop. (Not yet fully confirmed.)
     *  To prevent this, I handle this myself with pipe and don't use main loop provided by glib.
     */
    /* main_loop = g_main_loop_new( NULL, TRUE ); */

    g_snprintf( str, 16, "%d", getpid() );
    g_setenv(pid_env, str, TRUE );

    register_signals();

    if ( !session_name )
        session_name = "LXDE";

    g_setenv( "DESKTOP_SESSION", session_name, TRUE );

    start_session();

    /*
    g_main_loop_run( main_loop );
    g_main_loop_unref( main_loop );
     */

    while( read( wakeup_pipe[0], str, 16 ) > 0 )
        dispatch_child_watches();

    /* close( wakeup_pipe[0] ); */
    close( wakeup_pipe[1] );

    return 0;
}
