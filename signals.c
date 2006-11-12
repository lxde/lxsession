/* $Xorg: signals.c,v 1.4 2001/02/09 02:06:01 xorgcvs Exp $ */
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
/* $XFree86: xc/programs/xsm/signals.c,v 3.5 2001/12/08 18:33:45 herrb Exp $ */

#include <stdlib.h>
#include <glib/gi18n.h>

#include <X11/Xos.h>
#include <X11/Xfuncs.h>
#include <X11/Intrinsic.h>

#include <X11/SM/SMlib.h>

#include "save.h"

#include "gdm-logout-action.h"

#include <errno.h>
#ifdef USG
#ifndef __TYPES__
#include <sys/types.h>   /* forgot to protect it... */
#define __TYPES__
#endif /* __TYPES__ */
#else
#if defined(_POSIX_SOURCE) && defined(MOTOROLA)
#undef _POSIX_SOURCE
#include <sys/types.h>
#define _POSIX_SOURCE
#else
#include <sys/types.h>
#endif
#endif /* USG */

#ifdef X_POSIX_C_SOURCE
#define _POSIX_C_SOURCE X_POSIX_C_SOURCE
#include <signal.h>
#include <sys/wait.h>
#undef _POSIX_C_SOURCE
#else
#if defined(X_NOT_POSIX) || defined(_POSIX_SOURCE)
#include <signal.h>
#include <sys/wait.h>
#else
#define _POSIX_SOURCE
#include <signal.h>
#ifdef SCO325
#include <sys/procset.h>
#include <sys/siginfo.h>
#endif
#include <sys/wait.h>
#undef _POSIX_SOURCE
#endif
#endif
#include "save.h"

#if defined(X_NOT_POSIX) && defined(SIGNALRETURNSINT)
#define SIGVAL int
#else
#define SIGVAL void
#endif

#ifndef X_NOT_POSIX
#define USE_POSIX_WAIT
#endif

#if defined(linux) || defined(SYSV)
#define USE_SYSV_SIGNALS
#endif

#if defined(SCO) || defined(ISC)
#undef SIGTSTP   /* defined, but not the BSD way */
#endif

#if defined(X_NOT_POSIX) && defined(SYSV)
#define SIGNALS_RESET_WHEN_CAUGHT
#endif

#include <stddef.h>

#include <gtk/gtk.h>

int checkpoint_from_signal = 0;

extern Bool wantShutdown;


SIGVAL ( *Signal ( sig, handler ) ) ()
int sig;
SIGVAL ( *handler ) ();
{
#ifndef X_NOT_POSIX
    struct sigaction sigact, osigact;
    sigact.sa_handler = handler;
    sigemptyset ( &sigact.sa_mask );
    sigact.sa_flags = 0;
    sigaction ( sig, &sigact, &osigact );
    return osigact.sa_handler;
#else
    return signal ( sig, handler );
#endif
}


void
sig_child_handler ( gpointer closure )

{
    int pid, olderrno = errno;

#if !defined(USE_POSIX_WAIT) && (defined(USE_SYSV_SIGNALS) && \
    (defined(CRAY) || !defined(SIGTSTP)))
    wait ( NULL );
#endif

#ifdef SIGNALS_RESET_WHEN_CAUGHT
    Signal ( SIGCHLD, sig_child_handler );
#endif

    /*
     * The wait() above must come before re-establishing the signal handler.
     * In between this time, a new child might have died.  If we can do
     * a non-blocking wait, we can check for this race condition.  If we
     * don't have non-blocking wait, we lose.
     */

    do
    {
#ifdef USE_POSIX_WAIT
        pid = waitpid ( -1, NULL, WNOHANG );
#else
#if defined(USE_SYSV_SIGNALS) && (defined(CRAY) || !defined(SIGTSTP))
        /* cannot do non-blocking wait */
        pid = 0;
#else
        union wait status;

        pid = wait3 ( &status, WNOHANG, ( struct rusage * ) NULL );
#endif
#endif /* USE_POSIX_WAIT else */
    }
    while ( pid > 0 );
    errno = olderrno;
}


void
sig_term_handler ( int sig )
{
    wantShutdown = 1;
    checkpoint_from_signal = 1;
    // DoSave ( SmSaveLocal, SmInteractStyleNone, 1 /* fast */ );
    /* FIXME: all lists should be freed */
    EndSession(0);
}
/*
static gboolean
on_back_expose( GtkWidget* w, GdkEventExpose* evt, GdkPixbuf* pix )
{
    gdk_draw_pixbuf( evt->window, w->style->fg_gc, pix,
                     evt->area.x, evt->area.y, evt->area.x, evt->area.y,
                     evt->area.width, evt->area.height,
                     GDK_RGB_DITHER_NONE, 0, 0 );
    g_debug("expose! %d, %d, %d, %d", evt->area.x, evt->area.y,
                     evt->area.width, evt->area.height);
    return TRUE;
}
*/
static gboolean
popup_logout( gpointer user_data )
{
    GtkWidget *back = NULL, *img, *dlg, *check;
    GdkPixbuf *tmp, *shot;
    GdkScreen *screen;
    int res;
    GDK_THREADS_ENTER();
#if 0
    screen = gdk_screen_get_default();

    tmp = gdk_pixbuf_get_from_drawable( NULL,
                                        gdk_get_default_root_window(),
                                        NULL,
                                        0, 0, 0, 0,
                                        gdk_screen_get_width(screen),
                                        gdk_screen_get_height(screen) );

    shot = tmp;
/*
    shot = gdk_pixbuf_composite_color_simple( tmp,
                                              gdk_screen_get_width(screen),
                                              gdk_screen_get_height(screen),
                                              GDK_INTERP_NEAREST,
					      128, gdk_screen_get_width(screen),
					      0x000000, 0x000000);
    g_object_unref( shot );
*/
    back = gtk_window_new( GTK_WINDOW_TOPLEVEL );
    gtk_widget_set_app_paintable( back, TRUE );
    gtk_widget_set_double_buffered( back, FALSE );
    img = gtk_image_new_from_pixbuf( shot );
    g_object_unref( shot );
    gtk_container_add( back, img );
    gtk_window_fullscreen( back );
    gtk_window_set_decorated( back, FALSE );
    gtk_widget_show_all( back );
#endif

    dlg = gtk_message_dialog_new_with_markup( back,
                                              GTK_DIALOG_MODAL,
                                              GTK_MESSAGE_QUESTION,
                                              GTK_BUTTONS_NONE,
                                              _("<b><big>Logout Session?</big></b>") );
    check = gtk_check_button_new_with_label(_("Save current session"));
    /*
    gtk_message_dialog_set_image( (GtkMessageDialog*)dlg,
                                  gtk_image_new_from_stock(GTK_STOCK_QUIT, GTK_ICON_SIZE_DIALOG) );
    */

    gtk_dialog_add_button( (GtkDialog*)dlg, GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL );

    if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_SHUTDOWN) )
        gtk_dialog_add_button( (GtkDialog*)dlg, _("Sh_utdown"), GDM_LOGOUT_ACTION_SHUTDOWN );
    if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_REBOOT) )
        gtk_dialog_add_button( (GtkDialog*)dlg, _("_Reboot"), GDM_LOGOUT_ACTION_REBOOT );
    if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_SUSPEND) )
        gtk_dialog_add_button( (GtkDialog*)dlg, _("_Suspend"), GDM_LOGOUT_ACTION_SUSPEND );

    gtk_dialog_add_button( (GtkDialog*)dlg, _("_Logout"), GTK_RESPONSE_OK );

    gtk_toggle_button_set_active( check, TRUE );
    gtk_box_pack_start( GTK_DIALOG(dlg)->vbox, check, FALSE, FALSE, 2);
    gtk_window_set_position( GTK_WINDOW(dlg), GTK_WIN_POS_CENTER_ALWAYS );
    gtk_widget_show_all( dlg );

    gtk_window_set_keep_above( (GtkWindow*)dlg, TRUE );

    gdk_pointer_grab( dlg->window, TRUE, 0, NULL, NULL, GDK_CURRENT_TIME );
    gdk_keyboard_grab( dlg->window, TRUE, GDK_CURRENT_TIME );

    switch( (res = gtk_dialog_run( (GtkDialog*)dlg )) )
    {
        case GDM_LOGOUT_ACTION_SHUTDOWN:
        case GDM_LOGOUT_ACTION_REBOOT:
        case GDM_LOGOUT_ACTION_SUSPEND:
        case GTK_RESPONSE_OK:
            break;
        default:
            gtk_widget_destroy( dlg );
#if 0
            gtk_widget_destroy( back );
#endif
            GDK_THREADS_LEAVE();
            gdk_pointer_ungrab( GDK_CURRENT_TIME );
            gdk_keyboard_ungrab( GDK_CURRENT_TIME );
            return;
    }

    gdk_pointer_ungrab( GDK_CURRENT_TIME );
    gdk_keyboard_ungrab( GDK_CURRENT_TIME );

    if( gtk_toggle_button_get_active( check ) )
    {
        wantShutdown = 1;
        checkpoint_from_signal = 1;
        DoSave ( SmSaveLocal, SmInteractStyleAny, 0 /* fast */ );
    }
    else
        sig_term_handler( SIGTERM );
    gtk_widget_destroy( dlg );
#if 0
    gtk_widget_destroy( back );
#endif
    GDK_THREADS_LEAVE();

    if( res != GTK_RESPONSE_OK ) {
        gdm_set_logout_action( res );
    }
    return FALSE;
}

void sig_usr1_handler ( int sig )
{
    g_idle_add( popup_logout, NULL );
}


void
register_signals ()

{
    /*
     * Ignore SIGPIPE
     */

    Signal ( SIGPIPE, SIG_IGN );


    /*
     * If child process dies, call our handler
     */

    Signal ( SIGCHLD, sig_child_handler );


    /*
     * If we get a SIGTERM, do shutdown, fast, local, no interact
     */

    Signal ( SIGTERM, sig_term_handler );

    /*
     * If we get a SIGUSR1, do checkpoint, local, no interact
     */

    Signal ( SIGUSR1, sig_usr1_handler );
}



int
execute_system_command ( s )

char *s;

{
    int stat;

#ifdef X_NOT_POSIX
    /*
     * Non-POSIX system() uses wait().  We must disable our sig child
     * handler because if it catches the signal, system() will block
     * forever in wait().
     */

    int pid;

    Signal ( SIGCHLD, SIG_IGN );
#endif

    stat = system ( s );

#ifdef X_NOT_POSIX
    /*
     * Re-enable our sig child handler.  We might have missed some signals,
     * so do non-blocking waits until there are no signals left.
     */

    Signal ( SIGCHLD, sig_child_handler );

#if !(defined(USE_SYSV_SIGNALS) && (defined(CRAY) || !defined(SIGTSTP)))
    do
    {
        union wait status;

        pid = wait3 ( &status, WNOHANG, ( struct rusage * ) NULL );
    }
    while ( pid > 0 );
#endif
#endif   /* X_NOT_POSIX */

    return ( stat );
}


