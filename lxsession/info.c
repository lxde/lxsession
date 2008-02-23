/* $Xorg: info.c,v 1.5 2001/02/09 02:05:59 xorgcvs Exp $ */
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
/* $XFree86: xc/programs/xsm/info.c,v 1.5 2001/01/17 23:46:28 dawes Exp $ */

#include "xsm.h"
#include "restart.h"
#include "info.h"
#include "prop.h"

#include <glib.h>

typedef struct
{
    char *bufStart;
    char *bufPtr;
    int bufSize;
    int bytesLeft;
}
Buffer;

#define BUF_START_SIZE 1024
#define BUF_GROW_SIZE 256

static void
AppendStr ( Buffer *buffer, char *str )
{
    int len = strlen ( str );

    if ( ( buffer->bytesLeft - 1 ) < len )
    {
        int newBufSize = buffer->bufSize + len + BUF_GROW_SIZE;
        char *newbuf = ( char * ) malloc ( newBufSize );
        int bytesUsed = buffer->bufPtr - buffer->bufStart;
        memcpy ( newbuf, buffer->bufStart, bytesUsed );
        newbuf[bytesUsed] = '\0';
        free ( buffer->bufStart );
        buffer->bufStart = newbuf;
        buffer->bufPtr = newbuf + bytesUsed;
        buffer->bufSize = newBufSize;
        buffer->bytesLeft = newBufSize - bytesUsed;
    }

    strcat ( buffer->bufPtr, str );
    buffer->bufPtr += len;
    buffer->bytesLeft -= len;
}

char *
GetProgramName ( char *fullname )
{
    char *lastSlash = NULL;
    int i;

    for ( i = 0; i < ( int ) strlen ( fullname ); i++ )
        if ( fullname[i] == '/' )
            lastSlash = &fullname[i];

    if ( lastSlash )
        return ( lastSlash + 1 );
    else
        return ( fullname );
}

void
UpdateClientList ( void )
{
    ClientRec *client;
    char *progName, *hostname, *tmp1, *tmp2;
    char *clientInfo;
    int maxlen1, maxlen2;
    char extraBuf1[80], extraBuf2[80];
    char *restart_service_prop;
    GSList *cl, *pl;
    int i, k;
    static int reenable_asap = 0;

    if ( clientListNames )
    {
        /*
         * Free the previous list of names.  Xaw doesn't make a copy of
         * our list, so we need to keep it around.
         */

        for ( i = 0; i < numClientListNames; i++ )
            g_free ( clientListNames[i] );

        g_free ( ( char * ) clientListNames );

        clientListNames = NULL;
    }

    if ( clientListRecs )
    {
        /*
         * Free the mapping of client names to client records
         */
        g_free ( ( char * ) clientListRecs );
        clientListRecs = NULL;
    }

    maxlen1 = maxlen2 = 0;
    numClientListNames = 0;

    for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
    {
        client = ( ClientRec * ) cl->data;

        progName = NULL;
        restart_service_prop = NULL;

        for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
        {
            Prop *pprop = ( Prop * ) pl->data;
            GSList *vl = pprop->values;
            if ( vl != NULL )
            {
                PropValue *pval = ( PropValue * ) vl->data;

                if ( strcmp ( pprop->name, SmProgram ) == 0 )
                {
                    progName = GetProgramName ( ( char * ) pval->value );

                    if ( ( int ) strlen ( progName ) > maxlen1 )
                        maxlen1 = strlen ( progName );
                }
                else if ( strcmp ( pprop->name, "_XC_RestartService" ) == 0 )
                {
                    restart_service_prop = ( char * ) pval->value;
                }
            }
        }

        if ( !progName )
            continue;

        if ( restart_service_prop )
            tmp1 = restart_service_prop;
        else if ( client->clientHostname )
            tmp1 = client->clientHostname;
        else
            continue;

        if ( ( tmp2 = ( char * ) strchr ( tmp1, '/' ) ) == NULL )
            hostname = tmp1;
        else
            hostname = tmp2 + 1;

        if ( ( int ) strlen ( hostname ) > maxlen2 )
            maxlen2 = strlen ( hostname );

        numClientListNames++;
    }

    if ( numClientListNames == 0 )
    {
        reenable_asap = 1;

        return;
    }

    if ( reenable_asap )
    {
        reenable_asap = 0;
    }

    clientListNames = ( char ** ) g_malloc (
                          numClientListNames * sizeof ( char * ) );
    clientListRecs = ( ClientRec ** ) g_malloc (
                         numClientListNames * sizeof ( ClientRec * ) );

    i = 0;
    for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
    {
        ClientRec *client = ( ClientRec * ) cl->data;
        int extra1, extra2;
        char *hint;

        progName = NULL;
        restart_service_prop = NULL;

        for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
        {
            Prop *pprop = ( Prop * ) pl->data;
            GSList *vl = pprop->values;

            if ( vl != NULL )
            {
                PropValue *pval = ( PropValue * ) vl->data;
                if ( strcmp ( pprop->name, SmProgram ) == 0 )
                {
                    progName = GetProgramName ( ( char * ) pval->value );
                }
                else if ( strcmp ( pprop->name, "_XC_RestartService" ) == 0 )
                {
                    restart_service_prop = ( char * ) pval->value;
                }
            }
        }

        if ( !progName )
            continue;

        if ( restart_service_prop )
            tmp1 = restart_service_prop;
        else if ( client->clientHostname )
            tmp1 = client->clientHostname;
        else
            continue;

        if ( ( tmp2 = ( char * ) strchr ( tmp1, '/' ) ) == NULL )
            hostname = tmp1;
        else
            hostname = tmp2 + 1;

        extra1 = maxlen1 - strlen ( progName ) + 5;
        extra2 = maxlen2 - strlen ( hostname );

        if ( client->restartHint == SmRestartIfRunning )
            hint = "Restart If Running";
        else if ( client->restartHint == SmRestartAnyway )
            hint = "Restart Anyway";
        else if ( client->restartHint == SmRestartImmediately )
            hint = "Restart Immediately";
        else if ( client->restartHint == SmRestartNever )
            hint = "Restart Never";
        else
            hint = "";

        clientInfo = ( char * ) g_malloc ( strlen ( progName ) +
                                           extra1 + extra2 + 3 + strlen ( hostname ) + 3 + strlen ( hint ) + 1 );

        for ( k = 0; k < extra1; k++ )
            extraBuf1[k] = ' ';
        extraBuf1[extra1] = '\0';

        for ( k = 0; k < extra2; k++ )
            extraBuf2[k] = ' ';
        extraBuf2[extra2] = '\0';

        sprintf ( clientInfo, "%s%s (%s%s)   %s", progName, extraBuf1,
                  hostname, extraBuf2, hint );

        clientListRecs[i] = client;
        clientListNames[i++] = clientInfo;
    }
}
