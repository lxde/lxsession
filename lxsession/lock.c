/* $Xorg: lock.c,v 1.4 2001/02/09 02:05:59 xorgcvs Exp $ */
/******************************************************************************

Copyright 1994, 1998  The Open Group

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
/* $XFree86: xc/programs/xsm/lock.c,v 3.4 2001/12/14 20:02:25 dawes Exp $ */

#include "xsm.h"
#include "lock.h"
// #include "choose.h"
#include <sys/types.h>

static void
GetLockPath( char* buf, const char* session_name, gboolean is_tmp )
{
#ifndef __UNIXOS2__
/* FIXME:  will getenv("DISPLAY") have problems? */
    sprintf ( buf, "/tmp/.LXSM%slock-%s%s-%s", is_tmp ? "t":"",
              session_name, g_getenv( "DISPLAY" ), g_get_user_name() );
#else
    // FIXME: Is this needed?
#endif
}

Status
LockSession ( char *session_name, Bool write_id )
{
    char lock_file[PATH_MAX];
    char temp_lock_file[PATH_MAX];
    Status status;
    int fd;
    int len;

    GetLockPath( lock_file, session_name, FALSE );
    GetLockPath( temp_lock_file, session_name, TRUE );
g_debug("Lock: %s", temp_lock_file);
    if ( ( fd = creat ( temp_lock_file, 0444 ) ) < 0 )
    {
        g_debug ( "creat(%s) failed", temp_lock_file );
        return ( 0 );
    }
    len = strlen ( networkIds );
    if ( ( write_id &&
            ( write ( fd, networkIds, len ) != len ) ) ||
            ( write ( fd, "\n", 1 ) != 1 ) )
    {
        close ( fd );
        // g_debug ( "write error" );
        return ( 0 );
    }
    close ( fd );
#ifndef __UNIXOS2__
    status = 1;

    if ( link ( temp_lock_file, lock_file ) < 0 )
        status = 0;

    if ( unlink ( temp_lock_file ) < 0 )
        status = 0;
#else
    status = 0;
#endif
    return ( status );
}


void
UnlockSession ( char *session_name )
{
    char lock_file[PATH_MAX];

    GetLockPath (lock_file, session_name, FALSE);
    unlink ( lock_file );
}


char *
GetLockId ( char *session_name )
{
    FILE *fp;
    char lock_file[PATH_MAX];
    char buf[256];
    char *ret;

    GetLockPath (lock_file, session_name, FALSE);

    if ( ( fp = fopen ( lock_file, "r" ) ) == NULL )
    {
        return ( NULL );
    }

    buf[0] = '\0';
    fscanf ( fp, "%s\n", buf );
    ret = g_strdup ( buf );

    fclose ( fp );

    return ( ret );
}


Bool
CheckSessionLocked ( char *session_name, Bool get_id, char **id_ret )
{
    if ( get_id )
        *id_ret = GetLockId ( session_name );

    if ( !LockSession ( session_name, False ) )
        return ( 1 );

    UnlockSession ( session_name );
    return ( 0 );
}


void
UnableToLockSession ( char *session_name )
{
    /*
     * FIXME: We should popup a dialog here giving error.
     */
}
