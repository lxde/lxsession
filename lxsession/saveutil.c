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
#include <glib.h>

char* session_save_file = NULL;

/* older versions of glib don't provde these API */
#if ! GLIB_CHECK_VERSION(2, 8, 0)

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

int g_mkdir_with_parents(const gchar *pathname, int mode)
{
    struct stat statbuf;
    char *dir, *sep;
    dir = g_strdup( pathname );
    sep = dir[0] == '/' ? dir + 1 : dir;
    do {
        sep = strchr( sep, '/' );
        if( G_LIKELY( sep ) )
            *sep = '\0';

        if( stat( dir, &statbuf) == 0 )
        {
            if( ! S_ISDIR(statbuf.st_mode) )    /* parent not dir */
                goto err;
        }
        else    /* stat failed */
        {
            if( errno == ENOENT )   /* not exists */
            {
                if( mkdir( dir, mode ) == -1 )
                    goto err;
            }
            else
                goto err;   /* unknown error */
        }

        if( G_LIKELY( sep ) )
        {
            *sep = '/';
            ++sep;
        }
        else
            break;
    }while( sep );
    g_free( dir );
    return 0;
err:
    g_free( dir );
    return -1;
}
#endif

const char* get_session_dir()
{
    static char* dir;
    if ( G_UNLIKELY( ! dir ) )
    {
        dir = (char*)g_getenv ( "SM_SAVE_DIR" );
        if( G_LIKELY( ! dir ) )
            dir = g_build_filename( g_get_user_config_dir(), "lxsession", session_name, NULL );
    }
    if( !  g_file_test( dir, G_FILE_TEST_EXISTS ) )
        g_mkdir_with_parents( dir, 0700 ); /* ensure existance of the dir */
    return dir;
}

void set_session_save_file_name ()
{
    /* g_free( session_save_file ); */
    session_save_file = g_build_filename( get_session_dir(), "session", NULL );
}

int
ReadSave ( char **sm_id )
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
    if( getnextline ( &buf, &buflen, f ) )
    {
        if ( ( p = strchr ( buf, '\n' ) ) ) *p = '\0';
        *sm_id = *buf ? g_strdup( buf ) : NULL;
    }
    else
        return;

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
        char *strbuf;
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

/* FIXME: Are these simple checks enough? */
static gboolean same_command( const char* cmd1, const char* cmd2 )
{
    char *_cmd1 = NULL, *_cmd2 = NULL;
    char* space;
    gboolean ret = FALSE;

    if( ! cmd1 || ! cmd2 )
        return FALSE;

    if( space = strchr( cmd1, ' ' ) )
    {
        _cmd1 = g_strndup( cmd1, (space - cmd1) );
        cmd1 = _cmd1;
    }

    if( space = strchr( cmd2, ' ' ) )
    {
        _cmd2 = g_strndup( cmd2, (space - cmd2) );
        cmd2 = _cmd2;
    }

    /* if one of the commands is absolute path, and the other is not */
    if( g_path_is_absolute( cmd1 ) )
    {
        if( g_path_is_absolute( cmd2 ) )    /* both are absolute paths */
            ret = (0 == strcmp( cmd1, cmd2 ));
        else  /* cmd2 is not an absoulte path */
        {
            char* full = g_find_program_in_path( cmd2 );
            if( full )
            {
                ret = (0 == strcmp( cmd1, full ));
                g_free( full );
            }
        }
    }
    else /* cmd1 is not an absolute path */
    {
        if( g_path_is_absolute( cmd2 ) )    /* but cmd2 is absolute path */
        {
            char* full = g_find_program_in_path( cmd1 );
            if( full )
            {
                ret = (0 == strcmp( cmd2, full));
                g_free( full );
            }
        }
        else /* cmd2 is not an absoulte path, either */
            ret = (0 == strcmp( cmd1, cmd2 ));
    }
    g_free( _cmd1 );
    g_free( _cmd2 );
    return ret;
}

gboolean is_default_app( ClientRec *client )
{
    GSList *pl, *def;
    /*
      NOTE:
      Check if the program we try to save is a default app.
      Default apps should not be saved since they are started by
      StartDefaultApps(), not through X11 session management.
    */
    for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
    {
        Prop *pprop = ( Prop * ) pl->data;
        GSList *vl;
        PropValue *pval;

        if( 0 == strcmp( pprop->name, "Program" ) ) /* check program name first */
        {
            if ( strcmp ( pprop->type, SmCARD8 )
                 && pprop->values && pprop->values->data )
            {
                pval = (PropValue*)pprop->values->data;
                char* program = (char*)pval->value;
                GSList* def;

                if( verbose )
                    g_debug("check if program %s is default app", program);

                /* We shouldn't save our own process, lxsession. */
                if( g_str_has_prefix(program, "lxsession") )
                    return TRUE;

                for( def = DefaultApps; def; def = g_slist_next( def ) ) {
                    char* def_app = (char*)def->data;
                    if( same_command( program, def_app ) )
                        return TRUE;
                }
            }
        }
        else if( 0 == strcmp( pprop->name, SmRestartCommand) ) /* check restart command */
        {
            /* FIXME: Why this type-checking doesn't work here? */
            if ( /*strcmp ( pprop->type, SmLISTofARRAY8 )
                 &&*/ pprop->values && pprop->values->data )
            {
                GSList* array = (GSList*)pprop->values;
                pval = ( ( PropValue * ) array->data );
                const char* restart_command = pval && pval->value ? (char*)pval->value : NULL;
                if( restart_command )
                {
                    GSList* def;

                    if( verbose )
                        g_debug("check if restart command %s is default app", restart_command);
                    /* We shouldn't save our own process, lxsession. */
                    if( g_str_has_prefix(restart_command, "lxsession") )
                        return TRUE;

                    for( def = DefaultApps; def; def = g_slist_next( def ) ) {
                        char* def_app = (char*)def->data;
                        if( same_command( restart_command, def_app ) )
                            return TRUE;
                    }
                }
            }
        }
    }
    return FALSE;
}

static void
SaveClient ( FILE *f, ClientRec *client )
{
    GSList *pl;

    /* don't save our default apps */
    if( is_default_app( client ) )
    {
        if( verbose )
            g_debug( "This is a default app, don't save" );
        return;
    }

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
    char *commands;
    char *p, *c;
    int count;

    /* g_debug ( "write: session_save_file = %s", session_save_file ); */
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

            if ( client->restartHint != SmRestartNever && ! is_default_app(client) )
                count++;
        }

        for ( cl = RestartAnywayList; cl; cl = g_slist_next ( cl ) )
        {
            if ( ! is_default_app(client) )
                count++;
        }

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
