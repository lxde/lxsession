/* $Xorg: xsm.c,v 1.7 2001/02/09 02:06:01 xorgcvs Exp $ */
/******************************************************************************

Copyright 1993, 1998  The Open Group

Permission to use, copy, modify, distribute, and sell this software and its
documentation for any purpose is hereby granted without fee, provided that
the above copyright notice appear in all copies and that both that
copyright notice and this permission notice appear in supporting
documentation.

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
OPEN GROUP BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of The Open Group shall not be
used in advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization from The Open Group.
******************************************************************************/
/* $XFree86: xc/programs/xsm/xsm.c,v 1.9 2001/12/14 20:02:27 dawes Exp $ */

/*
 * X Session Manager.
 *
 * Authors:
 * Ralph Mor, X Consortium
 *      Jordan Brown, Quarterdeck Office Systems
 */

#include "xsm.h"
#include "prop.h"
#include "info.h"
#include "save.h"
#include "auth.h"
#include "restart.h"
#include "saveutil.h"
#include "lock.h"
#include "autostart.h"

#include <unistd.h>
#include <signal.h>
#include <X11/Xatom.h>

#include <X11/ICE/ICElib.h>

Atom wmStateAtom;
Atom wmDeleteAtom;
static char *cmd_line_display = NULL;

static GMainLoop* main_loop = NULL;

/*
 * Forward declarations
 */
static void GetEnvironment ( void );
static Bool OkToEnterInteractPhase ( void );
static Bool OkToEnterPhase2 ( void );
static gboolean NewConnectionProc ( GIOChannel* source,
                                    GIOCondition cond,
                                    gpointer client_data );
static void Cleanup ( void );

/*
 * Extern declarations
 */

extern int checkpoint_from_signal;

static IceListenObj *listenObjs;

/* Global varibles */
int  Argc;
char **Argv;

GSList* RunningList = NULL;
GSList* PendingList = NULL;
GSList* RestartAnywayList = NULL;
GSList* RestartImmedList = NULL;
GSList* WaitForSaveDoneList = NULL;
GSList* InitialSaveList = NULL;
GSList* FailedSaveList = NULL;
GSList* WaitForInteractList = NULL;
GSList* WaitForPhase2List = NULL;
GSList* DefaultApps = NULL;

Bool        wantShutdown = False;
Bool        shutdownInProgress = False;
Bool        phase2InProgress = False;
Bool        saveInProgress = False;
Bool        shutdownCancelled = False;
Bool        verbose = False;

char        *sm_id = NULL;

char        *networkIds = NULL;
char        *session_name = NULL;

IceAuthDataEntry *authDataEntries = NULL;
int     numTransports = 0;

Bool        client_info_visible = False;
Bool        client_prop_visible = False;
Bool        client_log_visible = False;

char      **clientListNames = NULL;
ClientRec   **clientListRecs = NULL;
int     numClientListNames = 0;

int     current_client_selected;

int     sessionNameCount = 0;
char      **sessionNamesShort = NULL;
char      **sessionNamesLong = NULL;
Bool        *sessionsLocked = NULL;

int     num_clients_in_last_session = -1;

char        **non_session_aware_clients = NULL;
int     non_session_aware_count = 0;

char        *display_env = NULL, *non_local_display_env = NULL;
char        *session_env = NULL, *non_local_session_env = NULL;
char        *audio_env = NULL;

Bool        remote_allowed;
extern char* rsh_cmd;

/* End of global variables */

/*
 * Main program
 */
int
main ( int argc, char *argv[] )
{
    char *p;
    char  str[256];
    static char environment_name[] = "SESSION_MANAGER";
    int  i;

    main_loop = g_main_loop_new( NULL, TRUE );

    Argc = argc;
    Argv = argv;

    p = (char *) g_getenv("_LXSESSION_PID");

    for ( i = 1; i < argc; i++ )
    {
        if ( argv[i][0] == '-' )
        {
            switch ( argv[i][1] )
            {
            case 'd':     /* -display */
                if ( ++i >= argc ) goto usage;
                cmd_line_display = g_strdup ( argv[i] );
                continue;

            case 's':     /* -session */
                if ( ++i >= argc ) goto usage;
                session_name = g_strdup ( argv[i] );
                continue;
            case 'e':
                if( 0 == strcmp( argv[i]+1, "exit" ) )
                {
                    if( p ) /* _LXSESSION_PID has been set */
                    {
                        GPid pid = atoi( p );
                        kill( pid, SIGUSR1 );
                        exit( 0 );
                    }
                    else
                    {
                        g_print( "Error: LXSession is not running.\n" );
                        exit( 1 );
                    }
                }
                break;
            case 'v':     /* -verbose */
                verbose = True;
                continue;
            }
        }

usage:
        fprintf ( stderr,
                  "Usage: lxsession [-display display] [-session session_name] [-exit]\n" );
        exit ( 1 );
    }

    if( p ) /* _LXSESSION_PID has been set */
    {
        g_print("Error: LXSession is already running\n");
        exit( 1 );
    }

    sprintf( str, "%d", getpid() );
    g_setenv("_LXSESSION_PID", str, TRUE );

    register_signals();

    if ( cmd_line_display )
    {
        /*
         * If a display was passed on the command line, set the DISPLAY
         * environment in this process so all applications started by
         * the session manager will run on the specified display.
         */

        p = ( char * ) g_malloc ( 8 + strlen ( cmd_line_display ) + 1 );
        sprintf ( p, "DISPLAY=%s", cmd_line_display );
        putenv ( p );
    }

    if ( verbose )
        printf ( "setenv %s %s\n", environment_name, networkIds );

    /* find rsh program */
    rsh_cmd = g_find_program_in_path( "rsh" );
    if( G_UNLIKELY( ! rsh_cmd ) )
    {
        rsh_cmd = g_find_program_in_path( "rcmd" );
        if( G_UNLIKELY( ! rsh_cmd ) )
        {
            rsh_cmd = g_find_program_in_path( "remsh" );
        }
    }

    if ( !session_name )
        session_name = g_strdup ( "LXDE" );

    g_setenv( "DESKTOP_SESSION", session_name, TRUE );

    if ( !StartSession ( session_name ) )
        UnableToLockSession ( session_name );

    /*
     * Main loop
     */
    g_main_loop_run( main_loop );
    g_main_loop_unref( main_loop );

    return 0;
}

static void
GetEnvironment ( void )
{
    static char envDISPLAY[]="DISPLAY";
    static char envSESSION_MANAGER[]="SESSION_MANAGER";
    static char envAUDIOSERVER[]="AUDIOSERVER";
    char *p, *temp;

    remote_allowed = 1;

    display_env = NULL;

    if ( ( p = cmd_line_display ) || ( p = ( char * ) getenv ( envDISPLAY ) ) )
    {
        display_env = ( char * ) g_malloc ( strlen ( envDISPLAY ) +1+strlen ( p ) +1 );

        if ( !display_env ) nomem();

        sprintf ( display_env, "%s=%s", envDISPLAY, p );

        /*
         * When we restart a remote client, we have to make sure the
         * display environment we give it has the SM's hostname.
         */

        if ( ( temp = strchr ( p, '/' ) ) == 0 )
            temp = p;
        else
            temp++;

        if ( *temp != ':' )
        {
            /* we have a host name */

            non_local_display_env = ( char * ) g_malloc (
                                        strlen ( display_env ) + 1 );

            if ( !non_local_display_env ) nomem();

            strcpy ( non_local_display_env, display_env );
        }
        else
        {
            char hostnamebuf[256];

            gethostname ( hostnamebuf, sizeof hostnamebuf );
            non_local_display_env = ( char * ) g_malloc (
                                        strlen ( envDISPLAY ) + 1 +
                                        strlen ( hostnamebuf ) + strlen ( temp ) + 1 );

            if ( !non_local_display_env ) nomem();

            sprintf ( non_local_display_env, "%s=%s%s",
                      envDISPLAY, hostnamebuf, temp );
        }
    }

    session_env = NULL;

    if ( ( p = ( char * ) getenv ( envSESSION_MANAGER ) ) )
    {
        session_env = ( char * ) g_malloc (
                          strlen ( envSESSION_MANAGER ) +1+strlen ( p ) +1 );

        if ( !session_env ) nomem();

        sprintf ( session_env, "%s=%s", envSESSION_MANAGER, p );

        /*
         * When we restart a remote client, we have to make sure the
         * session environment does not have the SM's local connection port.
         */

        non_local_session_env = ( char * ) g_malloc ( strlen ( session_env ) + 1 );

        if ( !non_local_session_env ) nomem();

        strcpy ( non_local_session_env, session_env );

        if ( ( temp = Strstr ( non_local_session_env, "local/" ) ) != NULL )
        {
            char *delim = strchr ( temp, ',' );

            if ( delim == NULL )
            {
                if ( temp == non_local_session_env +
                        strlen ( envSESSION_MANAGER ) + 1 )
                {
                    *temp = '\0';
                    remote_allowed = 0;
                }
                else
                    * ( temp - 1 ) = '\0';
            }
            else
            {
                int bytes = strlen ( delim + 1 );
                memmove ( temp, delim + 1, bytes );
                * ( temp + bytes ) = '\0';
            }
        }
    }

    audio_env = NULL;

    if ( ( p = ( char * ) getenv ( envAUDIOSERVER ) ) )
    {
        audio_env = ( char * ) g_malloc ( strlen ( envAUDIOSERVER ) +1+strlen ( p ) +1 );

        if ( !audio_env ) nomem();

        sprintf ( audio_env, "%s=%s", envAUDIOSERVER, p );
    }
}



Status
StartSession ( char *name )
{
    int database_read = 0;

    /*
     * If we're not using the default session, lock it.
     * If using the default session, it will be locked as
     * soon as the user assigns the session a name.
     */

    /* NOTE: Try to unlock old lock file first if it exists */
    UnlockSession( name );

    if ( !LockSession ( name, True ) )
    {
        return ( 0 );
    }
    /*
     * Get important environment variables.
     */

    GetEnvironment ();
    /*
     * Read the session save file.  Make sure the session manager
     * has an SM_CLIENT_ID, so that other managers (like the WM) can
     * identify it.
     */

    set_session_save_file_name ();
    StartDefaultApps (name);

    /* Support autostart spec of freedesktop.org */
    handle_autostart( name );

    database_read = ReadSave (&sm_id );

    if (! sm_id)
    {
        sm_id = SmsGenerateClientID( NULL );
        if (!sm_id)
            return (1);
    }

    if ( database_read )
    {
        /*
         * Restart window manager first.  When the session manager
         * gets a WM_STATE stored on its top level window, we know
         * the window manager is running.  At that time, we can start
         * the rest of the applications.
         */
        Restart ( RESTART_MANAGERS );
        Restart ( RESTART_REST_OF_CLIENTS );
        StartNonSessionAwareApps ();
    }
    return ( 1 );
}



void
EndSession ( int status )
{
    if ( verbose )
        printf ( "\nSESSION MANAGER GOING AWAY!\n" );

    FreeAuthenticationData ( numTransports, authDataEntries );

    if ( session_name )
    {
        UnlockSession ( session_name );
        g_free ( session_name );
    }

    if ( display_env )
        g_free ( display_env );

    if ( session_env )
        g_free ( session_env );

    if ( cmd_line_display )
        g_free ( cmd_line_display );

    if ( non_local_display_env )
        g_free ( non_local_display_env );

    if ( non_local_session_env )
        g_free ( non_local_session_env );

    if ( audio_env )
        g_free ( audio_env );

    if ( networkIds )
        free ( networkIds );

    // exit ( status );
    g_main_loop_quit(main_loop);
}



void
FreeClient ( ClientRec *client, Bool freeProps )
{
    if ( freeProps )
    {
        GSList *pl;

        for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
            FreeProp ( ( Prop * ) pl->data );

        g_slist_free ( client->props );

        client->props = NULL;
    }

    if ( client->clientId )
        free ( client->clientId );  /* malloc'd by SMlib */

    if ( client->clientHostname )
        free ( client->clientHostname );  /* malloc'd by SMlib */

    if ( client->discardCommand )
        g_free ( client->discardCommand );

    if ( client->saveDiscardCommand )
        g_free ( client->saveDiscardCommand );

    g_free ( ( char * ) client );
}

static void
Cleanup ( void )

{
    g_unsetenv("_LXSESSION_PID");
    g_slist_foreach( DefaultApps, (GFunc)g_free, NULL );
    g_slist_free( DefaultApps );
    UnlockSession( session_name );
}

extern void
FreeSessionNames ( int count, char **namesShort,
                    char **namesLong,
                    Bool *lockFlags )
{
    int i;

    for ( i = 0; i < count; i++ )
        g_free ( ( char * ) namesShort[i] );
    g_free ( ( char * ) namesShort );

    if ( namesLong )
    {
        for ( i = 0; i < count; i++ )
            if ( lockFlags[i] )
                g_free ( ( char * ) namesLong[i] );
        g_free ( ( char * ) namesLong );
    }

    g_free ( ( char * ) lockFlags );
}
