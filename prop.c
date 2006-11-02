/* $Xorg: prop.c,v 1.4 2001/02/09 02:06:01 xorgcvs Exp $ */
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
/* $XFree86: xc/programs/xsm/prop.c,v 1.5tsi Exp $ */

#include "xsm.h"
#include "info.h"
#include "prop.h"

void
FreePropValues ( GSList *propValues )
{
    GSList *pv;
    PropValue *pval;

    for ( pv = propValues; pv; pv = g_slist_next ( pv ) )
    {
        pval = ( PropValue * ) pv->data;
        g_free ( ( char * ) pval->value );
        g_free ( ( char * ) pval );
    }

    g_slist_free ( propValues );
}



void
FreeProp ( Prop *prop )
{
    FreePropValues ( prop->values );
    g_free ( prop->name );
    g_free ( prop->type );
    g_free ( ( char * ) prop );
}



void
SetInitialProperties ( ClientRec *client, GSList *props )
{
    GSList *pl;

    if ( verbose )
        printf ( "Setting initial properties for %s\n", client->clientId );

    if ( client->props )
    {
        /*
         * The only way client->props could be non-NULL is if the list
         * was initialized, but nothing was added yet.  So we just free
         * the head of the list.
         */

        g_free ( ( char * ) client->props );
    }

    client->props = props;

    for ( pl = props; pl; pl = g_slist_next ( pl ) )
    {
        Prop  *pprop;
        PropValue *pval;
        GSList  *vl;

        pprop = ( Prop * ) pl->data;

        if ( strcmp ( pprop->name, SmDiscardCommand ) == 0 )
        {
            if ( client->discardCommand )
                g_free ( client->discardCommand );

            vl = pprop->values;
            pval = ( PropValue * ) vl->data;

            client->discardCommand = ( char * ) g_strdup (
                                         ( char * ) pval->value );
        }
        else if ( strcmp ( pprop->name, SmRestartStyleHint ) == 0 )
        {
            int hint;

            vl = pprop->values;
            pval = ( PropValue * ) vl->data;

            hint = ( int ) * ( ( char * ) ( pval->value ) );

            if ( hint == SmRestartIfRunning || hint == SmRestartAnyway ||
                    hint == SmRestartImmediately || hint == SmRestartNever )
            {
                client->restartHint = hint;
            }
        }
    }
}



void
SetProperty ( ClientRec *client, SmProp *theProp, Bool freeIt )
{
    GSList  *pl;
    Prop *pprop = NULL;
    int  found = 0, i;

    /*
     * If the property exists, delete the property values.  We can
     * re-use the actual property header.
     */

    for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
    {
        pprop = ( Prop * ) pl->data;

        if ( strcmp ( theProp->name, pprop->name ) == 0 &&
                strcmp ( theProp->type, pprop->type ) == 0 )
        {
            FreePropValues ( pprop->values );
            found = 1;
            break;
        }
    }


    /*
     * Add the new property
     */

    if ( !found )
    {
        pprop = ( Prop * ) g_malloc ( sizeof ( Prop ) );
        pprop->name = g_strdup ( theProp->name );
        pprop->type = g_strdup ( theProp->type );
    }

    pprop->values = NULL;

    for ( i = 0; i < theProp->num_vals; i++ )
    {
        PropValue *pval = ( PropValue * ) g_malloc ( sizeof ( PropValue ) );

        pval->length = theProp->vals[i].length;
        pval->value = ( gpointer ) g_malloc ( theProp->vals[i].length + 1 );
        memcpy ( pval->value, theProp->vals[i].value, theProp->vals[i].length );
        ( ( char * ) pval->value ) [theProp->vals[i].length] = '\0';

        pprop->values = g_slist_append ( pprop->values, pval );
    }

    if ( pl )
        pl->data = ( char * ) pprop;
    else
        client->props = g_slist_append ( client->props, pprop );

    if ( strcmp ( theProp->name, SmDiscardCommand ) == 0 )
    {
        if ( saveInProgress )
        {
            /*
             * We are in the middle of a save yourself.  We save the
             * discard command we get now, and make it the current discard
             * command when the save is over.
             */

            if ( client->saveDiscardCommand )
                g_free ( client->saveDiscardCommand );
            client->saveDiscardCommand =
                ( char * ) g_strdup ( ( char * ) theProp->vals[0].value );

            client->receivedDiscardCommand = True;
        }
        else
        {
            if ( client->discardCommand )
                g_free ( client->discardCommand );
            client->discardCommand =
                ( char * ) g_strdup ( ( char * ) theProp->vals[0].value );
        }
    }
    else if ( strcmp ( theProp->name, SmRestartStyleHint ) == 0 )
    {
        int hint = ( int ) * ( ( char * ) ( theProp->vals[0].value ) );

        if ( hint == SmRestartIfRunning || hint == SmRestartAnyway ||
                hint == SmRestartImmediately || hint == SmRestartNever )
        {
            client->restartHint = hint;
        }
    }

    if ( freeIt )
        SmFreeProperty ( theProp );
}



void
DeleteProperty ( ClientRec *client, char *propname )
{
    GSList *pl;

    for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
    {
        Prop *pprop = ( Prop * ) pl->data;

        if ( strcmp ( pprop->name, propname ) == 0 )
        {
            FreeProp ( pprop );
            client->props = g_slist_delete_link ( client->props, pl );

            if ( strcmp ( propname, SmDiscardCommand ) == 0 )
            {
                if ( client->discardCommand )
                {
                    g_free ( client->discardCommand );
                    client->discardCommand = NULL;
                }

                if ( client->saveDiscardCommand )
                {
                    g_free ( client->saveDiscardCommand );
                    client->saveDiscardCommand = NULL;
                }
            }
            break;
        }
    }
}



void
SetPropertiesProc ( SmsConn smsConn, SmPointer managerData, int numProps,
                    SmProp **props )
{
    ClientRec *client = ( ClientRec * ) managerData;
    int  updateList, i;

    if ( verbose )
    {
        printf ( "Client Id = %s, received SET PROPERTIES ", client->clientId );
        printf ( "[Num props = %d]\n", numProps );
    }

    updateList = ( g_slist_length ( client->props ) == 0 ) &&
                 numProps > 0 && client_info_visible;

    for ( i = 0; i < numProps; i++ )
    {
        SetProperty ( client, props[i], True /* free it */ );
    }

    free ( ( char * ) props );
}


void
DeletePropertiesProc ( SmsConn smsConn, SmPointer managerData,
                       int numProps, char **propNames )

{
    ClientRec *client = ( ClientRec * ) managerData;
    int  i;

    if ( verbose )
    {
        printf ( "Client Id = %s, received DELETE PROPERTIES ",
                 client->clientId );
        printf ( "[Num props = %d]\n", numProps );
    }

    for ( i = 0; i < numProps; i++ )
    {
        if ( verbose )
            printf ( "   Name: %s\n", propNames[i] );

        DeleteProperty ( client, propNames[i] );

        free ( propNames[i] );
    }

    free ( ( char * ) propNames );
}

void
GetPropertiesProc ( SmsConn smsConn, SmPointer managerData )
{
    ClientRec *client = ( ClientRec * ) managerData;
    SmProp **propsRet, *propRet;
    SmPropValue *propValRet;
    Prop *pprop;
    PropValue *pval;
    GSList *pl, *pj;
    int  numProps;
    int  index, i;

    if ( verbose )
    {
        printf ( "Client Id = %s, received GET PROPERTIES\n", client->clientId );
        printf ( "\n" );
    }

    /*
     * Unfortunately, we store the properties in a format different
     * from the one required by SMlib.
     */

    numProps = g_slist_length ( client->props );
    propsRet = ( SmProp ** ) g_malloc ( numProps * sizeof ( SmProp * ) );

    index = 0;
    for ( pl = client->props; pl; pl = g_slist_next ( pl ) )
    {
        propsRet[index] = propRet = ( SmProp * ) g_malloc ( sizeof ( SmProp ) );

        pprop = ( Prop * ) pl->data;

        propRet->name = g_strdup ( pprop->name );
        propRet->type = g_strdup ( pprop->type );
        propRet->num_vals = g_slist_length ( pprop->values );
        propRet->vals = propValRet = ( SmPropValue * ) g_malloc (
                                         propRet->num_vals * sizeof ( SmPropValue ) );

        for ( pj = pprop->values; pj; pj = g_slist_next ( pj ) )
        {
            pval = ( PropValue * ) pj->data;

            propValRet->length = pval->length;
            propValRet->value = ( SmPointer ) g_malloc ( pval->length );
            memcpy ( propValRet->value, pval->value, pval->length );

            propValRet++;
        }

        index++;
    }

    SmsReturnProperties ( smsConn, numProps, propsRet );

    if ( verbose )
    {
        printf ( "Client Id = %s, sent PROPERTIES REPLY [Num props = %d]\n",
                 client->clientId, numProps );
    }

    for ( i = 0; i < numProps; i++ )
        SmFreeProperty ( propsRet[i] );
    g_free ( ( char * ) propsRet );
}
