/* $Xorg: saveutil.c,v 1.5 2001/02/09 02:06:01 xorgcvs Exp $ */
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
/* $XFree86: xc/programs/xsm/saveutil.c,v 1.5 2001/01/17 23:46:31 dawes Exp $ */

#include "xsm.h"
#include "saveutil.h"

char    session_save_file[PATH_MAX];

void
set_session_save_file_name ( char *session_name )
{
    char *p;

    p = ( char * ) getenv ( "SM_SAVE_DIR" );
    if ( !p )
    {
        p = ( char * ) getenv ( "HOME" );
        if ( !p )
            p = ".";
    }

    strcpy ( session_save_file, p );
    strcat ( session_save_file, "/.LXSM-" );
    strcat ( session_save_file, session_name );
}



int
ReadSave ( char *session_name, char **sm_id )
{
    char  *buf;
    int   buflen;
    char  *p;
    PendingClient *c = NULL;
    Prop  *prop = NULL;
    PropValue  *val;
    FILE  *f;
    int   state, i;
    int   version_number;
    f = fopen ( session_save_file, "r" );
    if ( !f )
    {
        if ( verbose )
            printf ( "No session save file.\n" );
        *sm_id = NULL;
        return 0;
    }
    if ( verbose )
        printf ( "Reading session save file...\n" );

    buf = NULL;
    buflen = 0;

    /* Read version # */
    getnextline ( &buf, &buflen, f );
    if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
    version_number = atoi ( buf );
    if ( version_number > SAVEFILE_VERSION )
    {
        if ( verbose )
            printf ( "Unsupported version number of session save file.\n" );
        *sm_id = NULL;
        if ( buf )
            free ( buf );
        return 0;
    }

    /* Read SM's id */
    getnextline ( &buf, &buflen, f );
    if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
    *sm_id = g_strdup ( buf );

    /* Read number of clients running in the last session */
    if ( version_number >= 2 )
    {
        getnextline ( &buf, &buflen, f );
        if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
        num_clients_in_last_session = atoi ( buf );
    }

    state = 0;
    while ( getnextline ( &buf, &buflen, f ) )
    {
        if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
        for ( p = buf; *p && isspace ( *p ); p++ ) /* LOOP */;
        if ( *p == '#' ) continue;

        if ( !*p )
        {
            if ( version_number >= 3 &&
                    g_slist_length ( PendingList ) == num_clients_in_last_session )
            {
                state = 5;
                break;
            }
            else
            {
                state = 0;
                continue;
            }
        }

        if ( !isspace ( buf[0] ) )
        {
            switch ( state )
            {
            case 0:
                c = ( PendingClient * ) g_malloc ( sizeof *c );
                if ( !c ) nomem();

                c->clientId = g_strdup ( p );
                c->clientHostname = NULL;  /* set in next state */

                c->props = NULL;

                PendingList = g_slist_append ( PendingList, c );

                state = 1;
                break;

            case 1:
                c->clientHostname = g_strdup ( p );
                state = 2;
                break;

            case 2:
            case 4:
                prop = ( Prop * ) g_malloc ( sizeof *prop );
                if ( !prop ) nomem();

                prop->name = g_strdup ( p );
                prop->values = NULL;

                prop->type = NULL;

                c->props = g_slist_append ( c->props, prop );

                state = 3;
                break;

            case 3:
                prop->type = g_strdup ( p );
                state = 4;
                break;

            default:
                fprintf ( stderr, "state %d\n", state );
                fprintf ( stderr,
                          "Corrupt save file line ignored:\n%s\n", buf );
                continue;
            }
        }
        else
        {
            if ( state != 4 )
            {
                fprintf ( stderr, "Corrupt save file line ignored:\n%s\n", buf );
                continue;
            }
            val = ( PropValue * ) g_malloc ( sizeof *val );
            if ( !val ) nomem();

            if ( strcmp ( prop->type, SmCARD8 ) == 0 )
            {
                val->length = 1;
                val->value = ( gpointer ) g_malloc ( 1 );
                * ( ( char * ) ( val->value ) ) = atoi ( p );
            }
            else
            {
                val->length = strlen ( p );
                val->value = g_strdup ( p );
            }

            prop->values = g_slist_append ( prop->values, val );
        }
    }

    /* Read commands for non-session aware clients */

    if ( state == 5 )
    {
        String strbuf;
        int bufsize = 0;

        getnextline ( &buf, &buflen, f );
        if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
        non_session_aware_count = atoi ( buf );

        if ( non_session_aware_count > 0 )
        {
            non_session_aware_clients = ( char ** ) malloc (
                                            non_session_aware_count * sizeof ( char * ) );

            for ( i = 0; i < non_session_aware_count; i++ )
            {
                getnextline ( &buf, &buflen, f );
                if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
                non_session_aware_clients[i] = ( char * ) malloc (
                                                   strlen ( buf ) + 2 );
                strcpy ( non_session_aware_clients[i], buf );
                bufsize += ( strlen ( buf ) + 1 );
            }
        }
    }

    fclose ( f );

    if ( buf )
        free ( buf );

    return 1;
}

gboolean is_default_app( ClientRec *client )
{
    GSList *pl;
    for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
    {
        Prop *pprop = ( Prop * ) pl->data;
        GSList *vl;
        PropValue *pval;
        gboolean check_program = !strcmp( pprop->name, "Program" );
        if( !check_program )
            continue;
        if ( strcmp ( pprop->type, SmCARD8 )
             && pprop->values && pprop->values->data )
        {
            pval = (PropValue*)pprop->values->data;
            char* program = (char*)pval->value;
            GSList* def;
            /*
              NOTE:
              Check if the program we try to save is a default app.
              Default apps should not be saved since they are started by
              StartDefaultApps(), not through X11 session management.
            */
            for( def = DefaultApps; def; def = g_slist_next( def ) ) {
                char* def_app = (char*)def->data;
                /* FIXME: Is this simple check enough? */
                if( ! strcmp( program, def_app ) )
                    return TRUE;
            }
            /* We shouldn't save our own process, lxsession. */
            if( !strcmp(program, "lxsession") )
                return TRUE;
        }
    }
    return FALSE;
}

static void
SaveClient ( FILE *f, ClientRec *client )
{
    GSList *pl;

    if( is_default_app( client ) )
        return;

    fprintf ( f, "%s\n", client->clientId );
    fprintf ( f, "%s\n", client->clientHostname );

    for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
    {
        Prop *pprop = ( Prop * ) pl->data;
        GSList *pj, *vl;
        PropValue *pval;
        gboolean check_program = !strcmp( pprop->name, "Program" );
        fprintf ( f, "%s\n", pprop->name );
        fprintf ( f, "%s\n", pprop->type );
        if ( strcmp ( pprop->type, SmCARD8 ) == 0 )
        {
            char *card8;
            int value;

            vl = pprop->values;
            pval = ( PropValue * ) vl->data;

            card8 = pval->value;
            value = *card8;
            fprintf ( f, "\t%d\n", value );
        }
        else
        {
            for ( pj = pprop->values; pj; pj = g_slist_next ( pj ) )
            {
                pval = ( PropValue * ) pj->data;
                fprintf ( f, "\t%s\n", ( char * ) pval->value );
            }
        }
    }
    fprintf ( f, "\n" );
}



void
WriteSave ( char *sm_id )
{
    ClientRec *client;
    FILE *f;
    GSList *cl;
    String commands;
    char *p, *c;
    int count;
    // g_debug ( "write: session_save_file = %s", session_save_file );
    f = fopen ( session_save_file, "w" );

    if ( !f )
    {
        char msg[256];

        sprintf ( msg, "%s: Error creating session save file %s",
                  Argv[0], session_save_file );
        perror ( msg );
    }
    else
    {
        fprintf ( f, "%d\n", SAVEFILE_VERSION );
        fprintf ( f, "%s\n", sm_id );

        count = 0;
        for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
        {
            client = ( ClientRec * ) cl->data;

            if ( client->restartHint != SmRestartNever )
                count++;
        }
        count += g_slist_length ( RestartAnywayList );

        fprintf ( f, "%d\n", count );
        if ( count == 0 )
            fprintf ( f, "\n" );

        for ( cl = RunningList; cl; cl = g_slist_next ( cl ) )
        {
            client = ( ClientRec * ) cl->data;

            if ( client->restartHint == SmRestartNever )
                continue;
            SaveClient ( f, client );
        }

        for ( cl = RestartAnywayList; cl; cl = g_slist_next ( cl ) )
        {
            client = ( ClientRec * ) cl->data;

            SaveClient ( f, client );
        }


        /* Save the non-session aware clients */
        /*
                XtVaGetValues ( manualRestartCommands,
                                XtNstring, &commands,
                                NULL );
        */
#if 0
        p = c = commands;
        count = 0;

        while ( *p )
        {
            if ( *p == '\n' )
            {
                if ( p != c )
                    count++;
                c = p + 1;
            }
            p++;
        }
        if ( p != c )
            count++;

        fprintf ( f, "%d\n", count );

        p = c = commands;

        while ( *p )
        {
            if ( *p == '\n' )
            {
                if ( p != c )
                {
                    *p = '\0';
                    fprintf ( f, "%s\n", c );
                    *p = '\n';
                }
                c = p + 1;
            }
            p++;
        }

        if ( p != c )
            fprintf ( f, "%s\n", c );
#endif
        fclose ( f );
        // g_debug ( "end saving file" );
    }
}


#if 0
Status
DeleteSession ( char *session_name )
{
    char *buf;
    int  buflen;
    char *p, *dir;
    FILE *f;
    int  state;
    int  foundDiscard;
    char filename[256];
    int  version_number;

    dir = ( char * ) getenv ( "SM_SAVE_DIR" );
    if ( !dir )
    {
        dir = ( char * ) getenv ( "HOME" );
        if ( !dir )
            dir = ".";
    }

    sprintf ( filename, "%s/.LSM-%s", dir, session_name );

    f = fopen ( filename, "r" );
    if ( !f )
    {
        return ( 0 );
    }

    buf = NULL;
    buflen = 0;

    /* Read version # */
    getnextline ( &buf, &buflen, f );
    if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
    version_number = atoi ( buf );
    if ( version_number > SAVEFILE_VERSION )
    {
        if ( verbose )
            printf ( "Can't delete session save file - incompatible version.\n" );
        if ( buf )
            free ( buf );
        return ( 0 );
    }

    /* Skip SM's id */
    getnextline ( &buf, &buflen, f );

    /* Skip number of clients running in the last session */
    if ( version_number >= 2 )
        getnextline ( &buf, &buflen, f );

    state = 0;
    foundDiscard = 0;
    while ( getnextline ( &buf, &buflen, f ) )
    {
        if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
        for ( p = buf; *p && isspace ( *p ); p++ ) /* LOOP */;
        if ( *p == '#' ) continue;

        if ( !*p )
        {
            state = 0;
            foundDiscard = 0;
            continue;
        }

        if ( !isspace ( buf[0] ) )
        {
            switch ( state )
            {
            case 0:
                state = 1;
                break;

            case 1:
                state = 2;
                break;

            case 2:
            case 4:
                if ( strcmp ( p, SmDiscardCommand ) == 0 )
                    foundDiscard = 1;
                state = 3;
                break;

            case 3:
                state = 4;
                break;

            default:
                continue;
            }
        }
        else
        {
            if ( state != 4 )
            {
                continue;
            }
            if ( foundDiscard )
            {
                execute_system_command ( p ); /* Discard Command */
                foundDiscard = 0;
            }
        }
    }

    fclose ( f );

    if ( buf )
        free ( buf );

    return ( ( unlink ( filename ) == -1 ) ? 0 : 1 );
}

#endif

Bool
getnextline ( char **pbuf, int *plen, FILE *f )
{
    int c;
    int i;

    i = 0;
    while ( 1 )
    {
        if ( i+2 > *plen )
        {
            if ( *plen ) *plen *= 2;
            else *plen = BUFSIZ;
            if ( *pbuf ) *pbuf = ( char * ) realloc ( *pbuf, *plen + 1 );
            else *pbuf = ( char * ) malloc ( *plen + 1 );
        }
        c = getc ( f );
        if ( c == EOF ) break;
        ( *pbuf ) [i++] = c;
        if ( c == '\n' ) break;
    }
    ( *pbuf ) [i] = '\0';
    return i;
}
