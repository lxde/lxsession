/* $Xorg: save.c,v 1.5 2001/02/09 02:06:01 xorgcvs Exp $ */
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
/* $XFree86: xc/programs/xsm/save.c,v 3.3 2001/01/17 23:46:30 dawes Exp $ */

#include "xsm.h"
#include "save.h"
#include "saveutil.h"
#include "info.h"
#include "lock.h"
#include <string.h>

extern int checkpoint_from_signal;

static int saveTypeData[] = {
                                SmSaveLocal,
                                SmSaveGlobal,
                                SmSaveBoth
                            };

static int interactStyleData[] = {
                                     SmInteractStyleNone,
                                     SmInteractStyleErrors,
                                     SmInteractStyleAny
                                 };

static char **failedNames = NULL;
static int numFailedNames = 0;

static Bool help_visible = False;

static char* name_in_use = NULL;
static Bool name_locked = False;

void
DoSave ( int saveType, int interactStyle, Bool fast )
{
    ClientRec *client;
    GSList *cl;
    char *_saveType;
    char *_shutdown;
    char *_interactStyle;

    if ( saveType == SmSaveLocal )
        _saveType = "Local";
    else if ( saveType == SmSaveGlobal )
        _saveType = "Global";
    else
        _saveType = "Both";

    if ( wantShutdown )
        _shutdown = "True";
    else
        _shutdown = "False";

    if ( interactStyle == SmInteractStyleNone )
        _interactStyle = "None";
    else if ( interactStyle == SmInteractStyleErrors )
        _interactStyle = "Errors";
    else
        _interactStyle = "Any";

    saveInProgress = True;

    shutdownCancelled = False;
    phase2InProgress = False;

    if ( g_slist_length ( RunningList ) == 0 )
        FinishUpSave ();

    for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
    {
        client = ( ClientRec * ) cl->data;

        /* Don't save our own logout-helper - lxsession-logout */
        if( client->saveDiscardCommand && strstr( "lxsession-logout", client->saveDiscardCommand ) )
            continue;
        if( client->discardCommand && strstr( "lxsession-logout", client->discardCommand ) )
            continue;

        SmsSaveYourself ( client->smsConn,
                          saveType, wantShutdown, interactStyle, fast );

        WaitForSaveDoneList = g_slist_append ( WaitForSaveDoneList, client );

        client->userIssuedCheckpoint = True;
        client->receivedDiscardCommand = False;

        if ( verbose )
        {
            printf ( "Client Id = %s, sent SAVE YOURSELF [", client->clientId );
            printf ( "Save Type = %s, Shutdown = %s, ", _saveType, _shutdown );
            printf ( "Interact Style = %s, Fast = False]\n", _interactStyle );
        }
    }

    if ( verbose )
    {
        printf ( "\n" );
        printf ( "Sent SAVE YOURSELF to all clients.  Waiting for\n" );
        printf ( "SAVE YOURSELF DONE, INTERACT REQUEST, or\n" );
        printf ( "SAVE YOURSELF PHASE 2 REQUEST from each client.\n" );
        printf ( "\n" );
    }
}


void
LetClientInteract ( GSList *cl )
{
    ClientRec *client = ( ClientRec * ) cl->data;

    SmsInteract ( client->smsConn );

    WaitForInteractList = g_slist_remove ( WaitForInteractList, client );

    if ( verbose )
    {
        printf ( "Client Id = %s, sent INTERACT\n", client->clientId );
    }
}

void
StartPhase2 ( void )
{
    GSList *cl;

    if ( verbose )
    {
        printf ( "\n" );
        printf ( "Starting PHASE 2 of SAVE YOURSELF\n" );
        printf ( "\n" );
    }

    for ( cl = WaitForPhase2List; cl; cl = g_slist_next ( cl ) )
    {
        ClientRec *client = ( ClientRec * ) cl->data;

        SmsSaveYourselfPhase2 ( client->smsConn );

        if ( verbose )
        {
            printf ( "Client Id = %s, sent SAVE YOURSELF PHASE 2",
                     client->clientId );
        }
    }

    /* ListFreeAllButHead ( WaitForPhase2List ); */
    if ( WaitForPhase2List && WaitForPhase2List->next )
    {
        g_slist_free ( WaitForPhase2List->next );
        WaitForPhase2List->next = NULL;
    }

    phase2InProgress = True;
}


void
FinishUpSave ( void )
{
    ClientRec *client;
    GSList *cl;
    g_debug ( "FinishUpSave" );
    if ( verbose )
    {
        printf ( "\n" );
        printf ( "All clients issued SAVE YOURSELF DONE\n" );
        printf ( "\n" );
    }

    saveInProgress = False;
    phase2InProgress = False;

    /*
     * Now execute discard commands
     */
    for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
    {
        client = ( ClientRec * ) cl->data;

        if ( !client->receivedDiscardCommand )
            continue;

        if ( client->discardCommand )
        {
            execute_system_command ( client->discardCommand );
            g_free ( client->discardCommand );
            client->discardCommand = NULL;
        }

        if ( client->saveDiscardCommand )
        {
            client->discardCommand = client->saveDiscardCommand;
            client->saveDiscardCommand = NULL;
        }
    }


    /*
     * Write the save file
     */
    WriteSave ( sm_id );


    if ( wantShutdown && shutdownCancelled )
    {
        shutdownCancelled = False;
    }
    else if ( wantShutdown )
    {
        if ( g_slist_length ( RunningList ) == 0 )
            EndSession ( 0 );

        shutdownInProgress = True;

        for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
        {
            client = ( ClientRec * ) cl->data;

            SmsDie ( client->smsConn );

            if ( verbose )
            {
                printf ( "Client Id = %s, sent DIE\n", client->clientId );
            }
        }
    }
    else
    {
        for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
        {
            client = ( ClientRec * ) cl->data;

            SmsSaveComplete ( client->smsConn );

            if ( verbose )
            {
                printf ( "Client Id = %s, sent SAVE COMPLETE\n",
                         client->clientId );
            }
        }
    }

    if ( !shutdownInProgress )
    {
        // FIXME: XtPopdown ( savePopup );
        // SetAllSensitive ( 1 );
        if ( checkpoint_from_signal )
            checkpoint_from_signal = False;
    }
}

#if 0
void
ShutdownDontSaveXtProc ( Widget w, gpointer client_data, gpointer callData )
{
    GSList *cl;
    ClientRec  *client;

    if ( g_slist_length ( RunningList ) == 0 )
        EndSession ( 0 );

    /*
     * For any client that was not restarted by the session
     * manager (previous ID was NULL), if we did not issue a
     * checkpoint to this client, remove the client's checkpoint
     * file using the discard command.
     */

    for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
    {
        client = ( ClientRec * ) cl->data;

        if ( !client->restarted &&
                !client->userIssuedCheckpoint &&
                client->discardCommand )
        {
            execute_system_command ( client->discardCommand );
            g_free ( client->discardCommand );
            client->discardCommand = NULL;
        }
    }

    shutdownInProgress = True;

    for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
    {
        client = ( ClientRec * ) cl->data;

        SmsDie ( client->smsConn );

        if ( verbose )
        {
            printf ( "Client Id = %s, sent DIE\n", client->clientId );
        }
    }
}
#endif
