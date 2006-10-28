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

#include <unistd.h>
#include <signal.h>
#include <X11/Shell.h>
#include <X11/Xatom.h>

#include <X11/ICE/ICElib.h>
#include <X11/Intrinsic.h>

Atom wmStateAtom;
Atom wmDeleteAtom;
static char *cmd_line_display = NULL;

/*
 * Forward declarations
 */
static void GetEnvironment ( void );
static Status RegisterClientProc ( SmsConn smsConn, SmPointer managerData,
                                   char *previousId );
static Bool OkToEnterInteractPhase ( void );
static void InteractRequestProc ( SmsConn smsConn, SmPointer managerData,
                                  int dialogType );
static void InteractDoneProc ( SmsConn smsConn, SmPointer managerData,
                               Bool cancelShutdown );
static void SaveYourselfReqProc ( SmsConn smsConn, SmPointer managerData,
                                  int saveType, Bool shutdown,
                                  int interactStyle, Bool fast, Bool global );
static Bool OkToEnterPhase2 ( void );
static void SaveYourselfPhase2ReqProc ( SmsConn smsConn, SmPointer managerData );
static void SaveYourselfDoneProc ( SmsConn smsConn, SmPointer managerData,
                                   Bool success );
static void CloseConnectionProc ( SmsConn smsConn, SmPointer managerData,
                                  int count, char **reasonMsgs );
static Status NewClientProc ( SmsConn smsConn, SmPointer managerData,
                              unsigned long *maskRet,
                              SmsCallbacks *callbacksRet,
                              char **failureReasonRet );
static gboolean NewConnectionProc ( GIOChannel* source,
                                    GIOCondition cond,
                                    gpointer client_data );
static void MyIoErrorHandler ( IceConn ice_conn );
static void InstallIOErrorHandler ( void );
static Status InitWatchProcs ( void );
static void CloseListeners ( void );
static void Cleanup ( void );

/*
 * Extern declarations
 */

extern int checkpoint_from_signal;

static IceListenObj *listenObjs;

/* Global varibles */
int     Argc;
char        **Argv;

GList* RunningList = NULL;
GList* PendingList = NULL;
GList* RestartAnywayList = NULL;
GList* RestartImmedList = NULL;
GList* WaitForSaveDoneList = NULL;
GList* InitialSaveList = NULL;
GList* FailedSaveList = NULL;
GList* WaitForInteractList = NULL;
GList* WaitForPhase2List = NULL;

Bool        wantShutdown = False;
Bool        shutdownInProgress = False;
Bool        phase2InProgress = False;
Bool        saveInProgress = False;
Bool        shutdownCancelled = False;

/* Bool        verbose = False; */

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
    int  success, i;

    gtk_init ( &argc, &argv );

#ifdef ENABLE_NLS
    bindtextdomain ( GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR );
    bind_textdomain_codeset ( GETTEXT_PACKAGE, "UTF-8" );
    textdomain ( GETTEXT_PACKAGE );
#endif

    Argc = argc;
    Argv = argv;

    p = g_getenv("_LXSESSION_PID");

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
# if 0
            case 'v':     /* -verbose */
                verbose = TRUE;
                continue;
#endif
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

    /*
     * Install an IO error handler.  For an explanation,
     * see the comments for InstallIOErrorHandler().
     */

    InstallIOErrorHandler ();
    InitWatchProcs();

    /*
     * Init SM lib
     */

    if ( !SmsInitialize ( "LXS", "1.0",
                          NewClientProc, NULL,
                          HostBasedAuthProc, 256, str ) )
    {
        fprintf ( stderr, "%s\n", str );
        exit ( 1 );
    }

    if ( !IceListenForConnections ( &numTransports, &listenObjs,
                                    256, str ) )
    {
        fprintf ( stderr, "%s\n", str );
        exit ( 1 );
    }

    atexit ( Cleanup );

    for ( i = 0; i < numTransports; i++ )
    {
        GIOChannel* channel;
        channel = g_io_channel_unix_new ( IceGetListenConnectionNumber ( listenObjs[i] ) );
        g_io_channel_set_encoding ( channel, NULL, NULL );
        g_io_channel_set_buffered ( channel, FALSE );
        g_io_add_watch ( channel,
                         G_IO_IN|G_IO_PRI|G_IO_HUP|G_IO_ERR,
                         NewConnectionProc,
                         ( gpointer ) listenObjs[i] );
        g_io_channel_unref ( channel );
    }

    if ( !SetAuthentication ( numTransports, listenObjs, &authDataEntries ) )
    {
        fprintf ( stderr, "Could not set authorization\n" );
        exit ( 1 );
    }

    /* the sizeof includes the \0, so we don't need to count the '=' */
    networkIds = IceComposeNetworkIdList ( numTransports, listenObjs );

    p = ( char * ) g_malloc ( ( sizeof environment_name ) + strlen ( networkIds ) + 1 );

    if ( !p ) nomem();

    sprintf ( p, "%s=%s", environment_name, networkIds );

    putenv ( p );

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

    /*
     * Get list of session names.  If a session name was found on the
     * command line, and it is in the list of session names we got, then
     * use that session name.  If there were no session names found, then
     * use the default session name.  Otherwise, present a list of session
     * names for the user to choose from.
     */
#if 0
    success = GetSessionNames ( &sessionNameCount,
                                &sessionNamesShort, &sessionNamesLong, &sessionsLocked );

    found_command_line_name = 0;

    if ( success && session_name )
    {
        for ( i = 0; i < sessionNameCount; i++ )
            if ( strcmp ( session_name, sessionNamesShort[i] ) == 0 )
            {
                found_command_line_name = 1;

                if ( sessionsLocked[i] )
                {
                    fprintf ( stderr, "Session '%s' is locked\n", session_name );
                    exit ( 1 );
                }

                break;
            }
    }

    if ( !success || found_command_line_name )
    {
        FreeSessionNames ( sessionNameCount,
                           sessionNamesShort, sessionNamesLong, sessionsLocked );

        if ( !found_command_line_name )
            session_name = XtNewString ( DEFAULT_SESSION_NAME );

        if ( !StartSession ( session_name, !found_command_line_name ) )
            UnableToLockSession ( session_name );
    }
    else
    {
        ChooseSession ();
    }
#endif
    if ( !session_name )
        session_name = g_strdup ( "LXDE" );

    if ( !StartSession ( session_name ) )
        UnableToLockSession ( session_name );

    /*
     * Main loop
     */
    gtk_main();
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
    Dimension width;
    char title[256];

    /*
     * If we're not using the default session, lock it.
     * If using the default session, it will be locked as
     * soon as the user assigns the session a name.
     */

    /* NOTE: Try to unlock old lock file first if it exists */
    UnlockSession( name );

    if ( !LockSession ( name, True ) )
    {
    g_debug("unable to lock");
        return ( 0 );
    }
g_debug("lock ok");
    /*
     * Get important environment variables.
     */

    GetEnvironment ();
    /*
     * Read the session save file.  Make sure the session manager
     * has an SM_CLIENT_ID, so that other managers (like the WM) can
     * identify it.
     */

    set_session_save_file_name ( name );
    database_read = ReadSave ( name, &sm_id );
g_debug("read save = %d", database_read);
    /* FIXME: this should be totally re-write */
    if ( !database_read )
    {
        /*
         * Start default apps (e.g. twm, smproxy)
         */

        StartDefaultApps (name);
        // g_spawn_command_line_async ( "smproxy", NULL );
        g_debug("START DEFAULTS");
    }
    else
    {
        /*
         * Restart window manager first.  When the session manager
         * gets a WM_STATE stored on its top level window, we know
         * the window manager is running.  At that time, we can start
         * the rest of the applications.
         */
g_debug("RESTART");
        Restart ( RESTART_MANAGERS );
        Restart ( RESTART_REST_OF_CLIENTS );
        StartNonSessionAwareApps ();

#if 0
        if ( !Restart ( RESTART_MANAGERS ) )
        {
            XtRemoveEventHandler ( topLevel, PropertyChangeMask, False,
                                   PropertyChangeXtHandler, NULL );

            /*
             * Restart the rest of the session aware clients.
             */

            Restart ( RESTART_REST_OF_CLIENTS );

            /*
             * Start apps that aren't session aware that were specified
             * by the user.
             */

            StartNonSessionAwareApps ();
        }
#endif
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
    gtk_main_quit();
}



void
FreeClient ( ClientRec *client, Bool freeProps )
{
    if ( freeProps )
    {
        GList *pl;

        for ( pl = client->props; pl; pl = g_list_next ( pl ) )
            FreeProp ( ( Prop * ) pl->data );

        g_list_free ( client->props );

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



/*
 * Session Manager callbacks
 */

static Status
RegisterClientProc ( SmsConn smsConn, SmPointer managerData, char *previousId )
{
    ClientRec *client = ( ClientRec * ) managerData;
    char  *id;
    GList *cl;
    int  send_save;

    if ( verbose )
    {
        printf (
            "On IceConn fd = %d, received REGISTER CLIENT [Previous Id = %s]\n",
            IceConnectionNumber ( client->ice_conn ),
            previousId ? previousId : "NULL" );
        printf ( "\n" );
    }

    if ( !previousId )
    {
        id = SmsGenerateClientID ( smsConn );
        send_save = 1;
    }
    else
    {
        int found_match = 0;
        send_save = 1;

        for ( cl = PendingList; cl; cl = g_list_next ( cl ) )
        {
            PendingClient *pendClient = ( PendingClient * ) cl->data;

            if ( !strcmp ( pendClient->clientId, previousId ) )
            {
                SetInitialProperties ( client, pendClient->props );
                g_free ( pendClient->clientId );
                g_free ( pendClient->clientHostname );
                g_free ( ( char * ) pendClient );
                PendingList = g_list_delete_link ( PendingList, cl );
                found_match = 1;
                send_save = 0;
                break;
            }
        }

        if ( !found_match )
        {
            for ( cl = RestartAnywayList; cl; cl = g_list_next ( cl ) )
            {
                ClientRec *rClient = ( ClientRec * ) cl->data;

                if ( !strcmp ( rClient->clientId, previousId ) )
                {
                    SetInitialProperties ( client, rClient->props );
                    FreeClient ( rClient, False /* don't free props */ );
                    RestartAnywayList = g_list_delete_link ( RestartAnywayList, cl );
                    found_match = 1;
                    send_save = 0;
                    break;
                }
            }
        }

        if ( !found_match )
        {
            for ( cl = RestartImmedList; cl; cl = g_list_next ( cl ) )
            {
                ClientRec *rClient = ( ClientRec * ) cl->data;

                if ( !strcmp ( rClient->clientId, previousId ) )
                {
                    SetInitialProperties ( client, rClient->props );
                    FreeClient ( rClient, False /* don't free props */ );
                    RestartImmedList = g_list_delete_link ( RestartImmedList, cl );
                    found_match = 1;
                    send_save = 0;
                    break;
                }
            }
        }

        if ( !found_match )
        {
            /*
             * previous-id was bogus: return bad status and the client
             * should re-register with a NULL previous-id
             */

            free ( previousId );
            return ( 0 );
        }
        else
        {
            id = previousId;
        }
    }

    SmsRegisterClientReply ( smsConn, id );

    if ( verbose )
    {
        printf (
            "On IceConn fd = %d, sent REGISTER CLIENT REPLY [Client Id = %s]\n",
            IceConnectionNumber ( client->ice_conn ), id );
        printf ( "\n" );
    }

    client->clientId = id;
    client->clientHostname = SmsClientHostName ( smsConn );
    client->restarted = ( previousId != NULL );

    if ( send_save )
    {
        SmsSaveYourself ( smsConn, SmSaveLocal,
                          False, SmInteractStyleNone, False );

        InitialSaveList = g_list_append ( InitialSaveList, ( char * ) client );
    }

    return ( 1 );
}



static Bool
OkToEnterInteractPhase ( void )
{
    return ( ( g_list_length ( WaitForInteractList ) +
               g_list_length ( WaitForPhase2List ) ) == g_list_length ( WaitForSaveDoneList ) );
}



static void
InteractRequestProc ( SmsConn smsConn, SmPointer managerData, int dialogType )
{
    ClientRec *client = ( ClientRec * ) managerData;

    if ( verbose )
    {
        printf ( "Client Id = %s, received INTERACT REQUEST [Dialog Type = ",
                 client->clientId );

        if ( dialogType == SmDialogError )
            printf ( "Error]\n" );
        else if ( dialogType == SmDialogNormal )
            printf ( "Normal]\n" );
        else
            printf ( "Error in SMlib: should have checked for bad value]\n" );
    }

    WaitForInteractList = g_list_append ( WaitForInteractList, ( char * ) client );

    if ( OkToEnterInteractPhase () )
    {
        LetClientInteract ( WaitForInteractList );
    }
}



static void
InteractDoneProc ( SmsConn smsConn, SmPointer managerData, Bool cancelShutdown )
{
    ClientRec *client = ( ClientRec * ) managerData;
    GList *cl;

    if ( verbose )
    {
        printf (
            "Client Id = %s, received INTERACT DONE [Cancel Shutdown = %s]\n",
            client->clientId, cancelShutdown ? "True" : "False" );
    }

    if ( cancelShutdown )
    {
// ListFreeAllButHead (WaitForInteractList);

        if ( WaitForInteractList )
        {
            g_list_free ( WaitForInteractList->next );
            WaitForInteractList->next = NULL;
        }

// ListFreeAllButHead (WaitForPhase2List);
        if ( WaitForPhase2List )
        {
            g_list_free ( WaitForPhase2List->next );
            WaitForPhase2List->next = NULL;
        }
    }

    if ( cancelShutdown )
    {
        if ( shutdownCancelled )
        {
            /* Shutdown was already cancelled */
            return;
        }

        shutdownCancelled = True;

        for ( cl = RunningList; cl; cl = g_list_next ( cl ) )
        {
            client = ( ClientRec * ) cl->data;

            SmsShutdownCancelled ( client->smsConn );

            if ( verbose )
            {
                printf ( "Client Id = %s, sent SHUTDOWN CANCELLED\n",
                         client->clientId );
            }
        }
    }
    else
    {
        if ( ( cl = WaitForInteractList ) != NULL )
        {
            LetClientInteract ( cl );
        }
        else
        {
            if ( verbose )
            {
                printf ( "\n" );
                printf ( "Done interacting with all clients.\n" );
                printf ( "\n" );
            }

            if ( g_list_length ( WaitForPhase2List ) > 0 )
            {
                StartPhase2 ();
            }
        }
    }
}



static void
SaveYourselfReqProc ( SmsConn smsConn, SmPointer managerData, int saveType,
                      Bool shutdown, int interactStyle, Bool fast, Bool global )
{
    if ( verbose )
        printf ( "SAVE YOURSELF REQUEST not supported!\n" );
}



static Bool
OkToEnterPhase2 ( void )

{
    return ( g_list_length ( WaitForPhase2List ) == g_list_length ( WaitForSaveDoneList ) );
}



static void
SaveYourselfPhase2ReqProc ( SmsConn smsConn, SmPointer managerData )
{
    ClientRec *client = ( ClientRec * ) managerData;

    if ( verbose )
    {
        printf ( "Client Id = %s, received SAVE YOURSELF PHASE 2 REQUEST\n",
                 client->clientId );
    }

    if ( !saveInProgress )
    {
        /*
         * If we are not in the middle of a checkpoint (ie. we just
         * started the client and sent the initial save yourself), just
         * send the save yourself phase2 now.
         */

        SmsSaveYourselfPhase2 ( client->smsConn );
    }
    else
    {
        WaitForPhase2List = g_list_append ( WaitForPhase2List, ( char * ) client );

        if ( g_list_length ( WaitForInteractList ) > 0 && OkToEnterInteractPhase () )
        {
            LetClientInteract ( WaitForInteractList );
        }
        else if ( OkToEnterPhase2 () )
        {
            StartPhase2 ();
        }
    }
}



static void
SaveYourselfDoneProc ( SmsConn smsConn, SmPointer managerData, Bool success )
{
    ClientRec *client = ( ClientRec * ) managerData;
    GList* elem;

    if ( verbose )
    {
        printf ( "Client Id = %s, received SAVE YOURSELF DONE [Success = %s]\n",
                 client->clientId, success ? "True" : "False" );
    }

    elem = g_list_find ( WaitForSaveDoneList, ( char* ) client );
    if ( elem )
    {
        WaitForSaveDoneList = g_list_delete_link ( WaitForSaveDoneList, elem );
    }
    else
    {
        elem = g_list_find ( InitialSaveList, ( char* ) client );
        if ( elem )
        {
            InitialSaveList = g_list_remove ( InitialSaveList, elem );
            SmsSaveComplete ( client->smsConn );
        }

        return;
    }

    if ( !success )
    {
        FailedSaveList = g_list_append ( FailedSaveList, ( char * ) client );
    }
    if ( g_list_length ( WaitForSaveDoneList ) == 0 )
    {
        if ( g_list_length ( FailedSaveList ) > 0 && !checkpoint_from_signal )
        {
            // FIXME: PopupBadSave ();
        }
        else
            FinishUpSave ();
    }
    else if ( g_list_length ( WaitForInteractList ) > 0 && OkToEnterInteractPhase () )
    {
        LetClientInteract ( WaitForInteractList );
    }
    else if ( g_list_length ( WaitForPhase2List ) > 0 && OkToEnterPhase2 () )
    {
        StartPhase2 ();
    }
}



void
CloseDownClient ( ClientRec *client )
{
    int index_deleted = 0;
    GList* elem;

    if ( verbose )
    {
        printf ( "ICE Connection closed, IceConn fd = %d\n",
                 IceConnectionNumber ( client->ice_conn ) );
        printf ( "\n" );
    }

    SmsCleanUp ( client->smsConn );
    IceSetShutdownNegotiation ( client->ice_conn, False );
    IceCloseConnection ( client->ice_conn );

    client->ice_conn = NULL;
    client->smsConn = NULL;

    if ( !shutdownInProgress && client_info_visible )
    {
        for ( index_deleted = 0;
                index_deleted < numClientListNames; index_deleted++ )
        {
            if ( clientListRecs[index_deleted] == client )
                break;
        }
    }

    RunningList = g_list_remove ( RunningList, client );

    if ( saveInProgress )
    {
        if ( elem = g_list_find ( WaitForSaveDoneList, client ) )
        {
            WaitForSaveDoneList = g_list_delete_link ( WaitForSaveDoneList, elem );
        }

        if ( elem )
        {
            FailedSaveList = g_list_append ( FailedSaveList, ( char * ) client );
            client->freeAfterBadSavePopup = True;
        }

        WaitForInteractList = g_list_remove ( WaitForInteractList, client );
        WaitForPhase2List = g_list_remove ( WaitForPhase2List, client );

        if ( elem && g_list_length ( WaitForSaveDoneList ) == 0 )
        {
            if ( g_list_length ( FailedSaveList ) > 0 && !checkpoint_from_signal )
            {
                // FIXME: PopupBadSave ();
            }
            else
                FinishUpSave ();
        }
        else if ( g_list_length ( WaitForInteractList ) > 0 &&
                  OkToEnterInteractPhase () )
        {
            LetClientInteract ( WaitForInteractList );
        }
        else if ( !phase2InProgress &&
                  g_list_length ( WaitForPhase2List ) > 0 && OkToEnterPhase2 () )
        {
            StartPhase2 ();
        }
    }

    if ( client->restartHint == SmRestartImmediately && !shutdownInProgress )
    {
        Clone ( client, True /* use saved state */ );

        RestartImmedList = g_list_append ( RestartImmedList, ( char * ) client );
    }
    else if ( client->restartHint == SmRestartAnyway )
    {
        RestartAnywayList = g_list_append ( RestartAnywayList, ( char * ) client );
    }
    else if ( !client->freeAfterBadSavePopup )
    {
        FreeClient ( client, True /* free props */ );
    }

    if ( shutdownInProgress )
    {
        if ( g_list_length ( RunningList ) == 0 )
            EndSession ( 0 );
    }
}




static void
CloseConnectionProc ( SmsConn smsConn, SmPointer managerData,
                      int count, char **reasonMsgs )
{
    ClientRec *client = ( ClientRec * ) managerData;

    if ( verbose )
    {
        int i;

        printf ( "Client Id = %s, received CONNECTION CLOSED\n",
                 client->clientId );

        for ( i = 0; i < count; i++ )
            printf ( "   Reason string %d: %s\n", i + 1, reasonMsgs[i] );

        printf ( "\n" );
    }

    SmFreeReasons ( count, reasonMsgs );

    CloseDownClient ( client );
}



static Status
NewClientProc ( SmsConn smsConn, SmPointer managerData, unsigned long *maskRet,
                SmsCallbacks *callbacksRet, char **failureReasonRet )
{
    ClientRec *newClient = ( ClientRec * ) g_malloc ( sizeof ( ClientRec ) );

    *maskRet = 0;

    if ( !newClient )
    {
        char *str = "Memory allocation failed";

        if ( ( *failureReasonRet = ( char * ) g_malloc ( strlen ( str ) + 1 ) ) != NULL )
            strcpy ( *failureReasonRet, str );

        return ( 0 );
    }

    newClient->smsConn = smsConn;
    newClient->ice_conn = SmsGetIceConnection ( smsConn );
    newClient->clientId = NULL;
    newClient->clientHostname = NULL;
    newClient->restarted = False; /* wait till RegisterClient for true value */
    newClient->userIssuedCheckpoint = False;
    newClient->receivedDiscardCommand = False;
    newClient->freeAfterBadSavePopup = False;
    newClient->props = NULL;
    newClient->discardCommand = NULL;
    newClient->saveDiscardCommand = NULL;
    newClient->restartHint = SmRestartIfRunning;

    RunningList = g_list_append ( RunningList, ( char * ) newClient );

    if ( verbose )
    {
        printf ( "On IceConn fd = %d, client set up session mngmt protocol\n\n",
                 IceConnectionNumber ( newClient->ice_conn ) );
    }

    /*
     * Set up session manager callbacks.
     */

    *maskRet |= SmsRegisterClientProcMask;

    callbacksRet->register_client.callback  = RegisterClientProc;

    callbacksRet->register_client.manager_data  = ( SmPointer ) newClient;

    *maskRet |= SmsInteractRequestProcMask;

    callbacksRet->interact_request.callback  = InteractRequestProc;

    callbacksRet->interact_request.manager_data = ( SmPointer ) newClient;

    *maskRet |= SmsInteractDoneProcMask;

    callbacksRet->interact_done.callback = InteractDoneProc;

    callbacksRet->interact_done.manager_data    = ( SmPointer ) newClient;

    *maskRet |= SmsSaveYourselfRequestProcMask;

    callbacksRet->save_yourself_request.callback     = SaveYourselfReqProc;

    callbacksRet->save_yourself_request.manager_data = ( SmPointer ) newClient;

    *maskRet |= SmsSaveYourselfP2RequestProcMask;

    callbacksRet->save_yourself_phase2_request.callback =
        SaveYourselfPhase2ReqProc;

    callbacksRet->save_yourself_phase2_request.manager_data =
        ( SmPointer ) newClient;

    *maskRet |= SmsSaveYourselfDoneProcMask;

    callbacksRet->save_yourself_done.callback     = SaveYourselfDoneProc;

    callbacksRet->save_yourself_done.manager_data  = ( SmPointer ) newClient;

    *maskRet |= SmsCloseConnectionProcMask;

    callbacksRet->close_connection.callback   = CloseConnectionProc;

    callbacksRet->close_connection.manager_data  = ( SmPointer ) newClient;

    *maskRet |= SmsSetPropertiesProcMask;

    callbacksRet->set_properties.callback  = SetPropertiesProc;

    callbacksRet->set_properties.manager_data   = ( SmPointer ) newClient;

    *maskRet |= SmsDeletePropertiesProcMask;

    callbacksRet->delete_properties.callback = DeletePropertiesProc;

    callbacksRet->delete_properties.manager_data   = ( SmPointer ) newClient;

    *maskRet |= SmsGetPropertiesProcMask;

    callbacksRet->get_properties.callback = GetPropertiesProc;

    callbacksRet->get_properties.manager_data   = ( SmPointer ) newClient;

    return ( 1 );
}



/*
 * callback invoked when a client attempts to connect.
 */

static gboolean
NewConnectionProc ( GIOChannel* source,
                    GIOCondition cond,
                    gpointer client_data )
{
    IceConn  ice_conn;
    char *connstr;
    IceAcceptStatus status;
    // g_debug ( "New connection" );
    if ( shutdownInProgress )
    {
        /*
         * Don't accept new connections if we are in the middle
         * of a shutdown.
         */
        return TRUE;
    }

    ice_conn = IceAcceptConnection ( ( IceListenObj ) client_data, &status );

    if ( ! ice_conn )
    {
        if ( verbose )
            printf ( "IceAcceptConnection failed\n" );
    }
    else
    {
        IceConnectStatus cstatus;

        while ( ( cstatus = IceConnectionStatus ( ice_conn ) ) ==IceConnectPending )
        {
            // FIXME: How to replace XtAppProcessEvent??
            // XtAppProcessEvent ( appContext, XtIMAll );
            IceProcessMessages ( ice_conn, NULL, NULL );
        }

        if ( cstatus == IceConnectAccepted )
        {
            if ( verbose )
            {
                printf ( "ICE Connection opened by client, IceConn fd = %d, ",
                         IceConnectionNumber ( ice_conn ) );
                connstr = IceConnectionString ( ice_conn );
                printf ( "Accept at networkId %s\n", connstr );
                free ( connstr );
                printf ( "\n" );
            }
        }
        else
        {
            if ( verbose )
            {
                if ( cstatus == IceConnectIOError )
                    printf ( "IO error opening ICE Connection!\n" );
                else
                    printf ( "ICE Connection rejected!\n" );
            }

            IceCloseConnection ( ice_conn );
            return FALSE;   /* remove watch */
        }
    }
    return TRUE;
}


/*
 * The real way to handle IO errors is to check the return status
 * of IceProcessMessages.  xsm properly does this.
 *
 * Unfortunately, a design flaw exists in the ICE library in which
 * a default IO error handler is invoked if no IO error handler is
 * installed.  This default handler exits.  We must avoid this.
 *
 * To get around this problem, we install an IO error handler that
 * does a little magic.  Since a previous IO handler might have been
 * installed, when we install our IO error handler, we do a little
 * trick to get both the previous IO error handler and the default
 * IO error handler.  When our IO error handler is called, if the
 * previous handler is not the default handler, we call it.  This
 * way, everyone's IO error handler gets called except the stupid
 * default one which does an exit!
 */

static IceIOErrorHandler prev_handler;

static void
MyIoErrorHandler ( IceConn ice_conn )
{
    if ( prev_handler )
        ( *prev_handler ) ( ice_conn );
}

static void
InstallIOErrorHandler ( void )

{
    IceIOErrorHandler default_handler;

    prev_handler = IceSetIOErrorHandler ( NULL );
    default_handler = IceSetIOErrorHandler ( MyIoErrorHandler );

    if ( prev_handler == default_handler )
        prev_handler = NULL;
}

/*
 * Process ICE messages
 */
/* This function is taken from xfce4-session */
static gboolean
ice_process_messages ( GIOChannel *channel, GIOCondition condition,
                       IceConn ice_conn )
{
    IceProcessMessagesStatus status;
    GList *lp;
    // g_debug("ice_process_messages");
    status = IceProcessMessages ( ice_conn, NULL, NULL );

    if ( status == IceProcessMessagesIOError )
    {
        if ( verbose )
        {
            printf ( "IO error on connection (fd = %d)\n",
                     IceConnectionNumber ( ice_conn ) );
            printf ( "\n" );
        }
        for ( lp = RunningList; lp; lp = lp->next )
        {
            ClientRec *client = ( ClientRec * ) lp->data;
            if ( client->ice_conn == ice_conn )
            {
                CloseDownClient ( client );
                break;
            }
        }

        if ( ! lp )
        {
            /*
            * The client must have disconnected before it was added
            * to the session manager's running list (i.e. before the
            * NewClientProc callback was invoked).
            */
            IceSetShutdownNegotiation ( ice_conn, False );
            IceCloseConnection ( ice_conn );
            /* remove the I/O watch */
            return ( FALSE );
        }
    }

    /* keep the I/O watch running */
    return ( TRUE );
}

static void
_IceWatchProc ( IceConn ice_conn,
                IcePointer client_data,
                Bool opening,
                IcePointer *watch_data )
{
    GIOChannel *channel;
    guint source;
    // g_debug("_IceWatchProc");
    if ( opening )
    {
        int fd = IceConnectionNumber ( ice_conn );
        /* copied from xfce4-session */
        fcntl ( fd, F_SETFD, fcntl ( fd, F_GETFD, 0 ) | FD_CLOEXEC );
        channel = g_io_channel_unix_new ( fd );
        source = g_io_add_watch ( channel,
                                  G_IO_ERR | G_IO_HUP | G_IO_IN | G_IO_PRI,
                                  ( GIOFunc ) ice_process_messages, ice_conn );
        g_io_channel_unref ( channel );
        *watch_data = ( IcePointer ) GUINT_TO_POINTER ( source );
    }
    else
    {
        g_source_remove ( GPOINTER_TO_UINT ( *watch_data ) );
    }
}

static Status
InitWatchProcs()
{
    return ( IceAddConnectionWatch ( _IceWatchProc, NULL ) );
}

static void
CloseListeners ( void )

{
    IceFreeListenObjs ( numTransports, listenObjs );
}

static void
Cleanup ( void )

{
    CloseListeners();
    g_unsetenv("_LXSESSION_PID");
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
