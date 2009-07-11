/*
 *      main.c -lxsession-logout for LXSession
 *
 *      Copyright 2008 PCMan <pcman.tw@gmail.com>
 *      Copyright (c) 2003-2006 Benedikt Meurer <benny@xfce.org>
 *
 *      HAL-related parts are taken from xfsm-shutdown-helper.c of
 *      xfce4-session originally written by Benedikt Meurer, with some
 *      modification to be used in this project.
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

#include <config.h>

#include <gtk/gtk.h>
#include <glib/gi18n.h>
#include <signal.h>
#include <gdk/gdk.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <locale.h>

#include "gdm-logout-action.h"

#ifdef HAVE_HAL
#include <dbus/dbus.h>
#endif

typedef enum {
        LOGOUT_ACTION_NONE     = GDM_LOGOUT_ACTION_NONE,
        LOGOUT_ACTION_SHUTDOWN = GDM_LOGOUT_ACTION_SHUTDOWN,
        LOGOUT_ACTION_REBOOT   = GDM_LOGOUT_ACTION_REBOOT,
        LOGOUT_ACTION_SUSPEND  = GDM_LOGOUT_ACTION_SUSPEND,
        LOGOUT_ACTION_HIBERNATE = GDM_LOGOUT_ACTION_SUSPEND << 1,    /* HAL only */
        LOGOUT_ACTION_SWITCH_USER = GDM_LOGOUT_ACTION_SUSPEND << 2   /* not supported */
}LogoutAction;

static gboolean use_hal = FALSE;
static LogoutAction available_actions = GDM_LOGOUT_ACTION_NONE;

static char* prompt = NULL;
static char* side = NULL;
static char* banner = NULL;

static GOptionEntry opt_entries[] =
{
    { "prompt", 'p', 0, G_OPTION_ARG_STRING, &prompt, N_("Custom message to show on the dialog"), N_("message") },
    { "banner", 'b', 0, G_OPTION_ARG_STRING, &banner, N_("Banner to show on the dialog"), N_("image file") },
    { "side", 's', 0, G_OPTION_ARG_STRING, &side, N_("Position of the banner"), "top|left|right|botom" },
/*    {G_OPTION_REMAINING, 0, 0, G_OPTION_ARG_FILENAME_ARRAY, &files, NULL, N_("[FILE1, FILE2,...]")}, */
    { NULL }
};

static gboolean on_expose( GtkWidget* w, GdkEventExpose* evt, GdkPixbuf* shot )
{
    if( GTK_WIDGET_REALIZED(w) && GDK_IS_DRAWABLE(w->window) )
    {
        gdk_draw_pixbuf( w->window, w->style->black_gc, shot,
                                    evt->area.x, evt->area.y,
                                    evt->area.x, evt->area.y,
                                    evt->area.width, evt->area.height,
                                    GDK_RGB_DITHER_NORMAL, 0, 0 );
    }
    return TRUE;
}

static GtkWidget* create_background()
{
    GtkWidget *back = NULL, *img;
    GdkPixbuf *tmp, *shot;
    GdkScreen *screen;

    guchar *pixels, *p;
    int x, y, width, height, rowstride;
    gboolean has_alpha;

    screen = gdk_screen_get_default();

    shot = gdk_pixbuf_get_from_drawable( NULL,
                                         gdk_get_default_root_window(),
                                         NULL,
                                         0, 0, 0, 0,
                                         gdk_screen_get_width(screen),
                                         gdk_screen_get_height(screen) );

    /* make the background darker */
    pixels = gdk_pixbuf_get_pixels(shot);
    width = gdk_pixbuf_get_width(shot);
    height = gdk_pixbuf_get_height(shot);
    has_alpha = gdk_pixbuf_get_has_alpha(shot);
    rowstride = gdk_pixbuf_get_rowstride(shot);
    
    for (y = 0; y < height; y++)
    {
        p = pixels;
        for (x = 0; x < width; x++)
        {
            p[0] = p[0] / 2;
            p[1] = p[1] / 2;
            p[2] = p[2] / 2;
            if( has_alpha )
                p += 4;
            else
                p += 3;
        }
        pixels += rowstride;
    }
     
    back = gtk_window_new( GTK_WINDOW_TOPLEVEL );
    gtk_widget_set_app_paintable( back, TRUE );
    gtk_widget_set_double_buffered( back, FALSE );
    g_signal_connect( back, "expose-event", G_CALLBACK(on_expose), shot );
    g_object_weak_ref( (GObject *) back, (GWeakNotify)g_object_unref,  shot );

    gtk_window_fullscreen( GTK_WINDOW(back) );
    gtk_window_set_decorated( GTK_WINDOW(back), FALSE );
    gtk_window_set_keep_above( GTK_WINDOW(back), TRUE );
    gtk_widget_show_all( GTK_WIDGET(back) );

    return back;
}

static void btn_clicked( GtkWidget* btn, gpointer id )
{
    GtkWidget* dlg = gtk_widget_get_toplevel( btn );
    gtk_dialog_response( GTK_DIALOG(dlg), GPOINTER_TO_INT(id) );
}

static GtkWidget* create_dlg_btn(const char* label, const char* icon, int response )
{
    GtkWidget* btn = gtk_button_new_with_mnemonic( label );
    gtk_button_set_alignment( GTK_BUTTON(btn), 0.0, 0.5 );
    g_signal_connect( btn, "clicked", G_CALLBACK(btn_clicked), GINT_TO_POINTER(response) );
    if( icon )
    {
        GtkWidget* img = gtk_image_new_from_icon_name( icon, GTK_ICON_SIZE_BUTTON );
        gtk_button_set_image( GTK_BUTTON(btn), img );
    }
    return btn;
}

GtkPositionType get_banner_position()
{
    if( side )
    {
        if( 0 == strcmp( side, "right" ) )
            return GTK_POS_RIGHT;
        if( 0 == strcmp( side, "top" ) )
            return GTK_POS_TOP;
        if( 0 == strcmp( side, "bottom" ) )
            return GTK_POS_BOTTOM;
    }
    return GTK_POS_LEFT;
}

/*
 *  These functions with the prefix "xfsm_" are taken from
 *  xfsm-shutdown-helper.c of xfce4-session with some modification.
 *  Copyright (c) 2003-2006 Benedikt Meurer <benny@xfce.org>
 */
static gboolean xfsm_shutdown_helper_hal_check ()
{
#ifdef HAVE_HAL
    DBusConnection *connection;
    DBusMessage        *message;
    DBusMessage        *result;
    DBusError             error;

    /* initialize the error */
    dbus_error_init (&error);

    /* connect to the system message bus */
    connection = dbus_bus_get (DBUS_BUS_SYSTEM, &error);
    if (G_UNLIKELY (connection == NULL))
    {
        g_warning (G_STRLOC ": Failed to connect to the system message bus: %s", error.message);
        dbus_error_free (&error);
        return FALSE;
    }

    /* this is a simple trick to check whether we are allowed to
     * use the org.freedesktop.Hal.Device.SystemPowerManagement
     * interface without shutting down/rebooting now.
     */
    message = dbus_message_new_method_call ("org.freedesktop.Hal",
                                            "/org/freedesktop/Hal/devices/computer",
                                            "org.freedesktop.Hal.Device.SystemPowerManagement",
                                            "ThisMethodMustNotExistInHal");
    result = dbus_connection_send_with_reply_and_block (connection, message, 2000, &error);
    dbus_message_unref (message);

    /* translate error results appropriately */
    if (result != NULL && dbus_set_error_from_message (&error, result))
    {
        /* release and reset the result */
        dbus_message_unref (result);
        result = NULL;
    }
    else if (G_UNLIKELY (result != NULL))
    {
        /* we received a valid message return?! HAL must be on crack! */
        dbus_message_unref (result);
        return FALSE;
    }

    /* if we receive org.freedesktop.DBus.Error.UnknownMethod, then
     * we are allowed to shutdown/reboot the computer via HAL.
     */
    if (strcmp (error.name, "org.freedesktop.DBus.Error.UnknownMethod") == 0)
    {
        dbus_error_free (&error);
        return TRUE;
    }

    /* otherwise, we failed for some reason */
    g_warning (G_STRLOC ": Failed to contact HAL: %s", error.message);
    dbus_error_free (&error);
#endif

    return FALSE;
}

/*
 *  These functions with the prefix "xfsm_" are taken from
 *  xfsm-shutdown-helper.c of xfce4-session with some modification.
 *  Copyright (c) 2003-2006 Benedikt Meurer <benny@xfce.org>
 */
static gboolean
xfsm_shutdown_helper_hal_send ( LogoutAction action )
{
#ifdef HAVE_HAL
    DBusConnection *connection;
    DBusMessage        *message;
    DBusMessage        *result;
    DBusError             error;
    const char* method;
    dbus_int32_t suspend_arg = 0;

    /* The spec:
     http://people.freedesktop.org/~david/hal-spec/hal-spec.html#interface-device-systempower */
    switch( action )
    {
    case LOGOUT_ACTION_SHUTDOWN:
        method = "Shutdown";
        break;
    case LOGOUT_ACTION_REBOOT:
        method = "Reboot";
        break;
    case LOGOUT_ACTION_SUSPEND:
        method = "Suspend";
        break;
    case LOGOUT_ACTION_HIBERNATE:
        method = "Hibernate";
        break;
    default:
        return FALSE;    /* It's impossible to reach here, or it's a bug. */
    }

    /* initialize the error */
    dbus_error_init (&error);

    /* connect to the system message bus */
    connection = dbus_bus_get (DBUS_BUS_SYSTEM, &error);
    if (G_UNLIKELY (connection == NULL))
    {
        g_warning (G_STRLOC ": Failed to connect to the system message bus: %s", error.message);
        dbus_error_free (&error);
        return FALSE;
    }

    /* send the appropriate message to HAL, telling it to shutdown or reboot the system */
    message = dbus_message_new_method_call ("org.freedesktop.Hal",
                                                                                    "/org/freedesktop/Hal/devices/computer",
                                                                                    "org.freedesktop.Hal.Device.SystemPowerManagement",
                                                                                    method );
    if( action == LOGOUT_ACTION_SUSPEND )
        dbus_message_append_args( message, DBUS_TYPE_INT32, &suspend_arg, DBUS_TYPE_INVALID );

    result = dbus_connection_send_with_reply_and_block (connection, message, 2000, &error);
    dbus_message_unref (message);

    /* check if we received a result */
    if (G_UNLIKELY (result == NULL))
    {
        g_warning (G_STRLOC ": Failed to contact HAL: %s", error.message);
        dbus_error_free (&error);
        return FALSE;
    }

    /* pretend that we succeed */
    dbus_message_unref (result);
    return TRUE;
#else
    return FALSE;
#endif
}

static void check_available_actions()
{
    /* check if we can use HAL to shutdown the computer */
    use_hal = xfsm_shutdown_helper_hal_check ();
    if( use_hal )   /* check if hal is available */
    {
        available_actions = LOGOUT_ACTION_SHUTDOWN | LOGOUT_ACTION_REBOOT | LOGOUT_ACTION_SUSPEND | LOGOUT_ACTION_HIBERNATE;
    }
    else /* check if gdm is available */
    {
        if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_SHUTDOWN) )
            available_actions |= GDM_LOGOUT_ACTION_SHUTDOWN;
        if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_REBOOT) )
            available_actions |= GDM_LOGOUT_ACTION_REBOOT;
        if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_SUSPEND) )
            available_actions |= GDM_LOGOUT_ACTION_SUSPEND;
    }
}

int main( int argc, char** argv )
{
    GtkWidget *back = NULL, *dlg, *check, *btn, *label, *box = NULL, *vbox;
    GtkPositionType banner_pos;
    int res;
    const char* p;
    char* file;
    GPid pid;
    GOptionContext *context;
    GError* err = NULL;
    gboolean composited;

#ifdef ENABLE_NLS
    setlocale(LC_ALL, "");
    bindtextdomain ( GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR );
    bind_textdomain_codeset ( GETTEXT_PACKAGE, "UTF-8" );
    textdomain ( GETTEXT_PACKAGE );
#endif

    p = g_getenv("_LXSESSION_PID");
    if( ! p || (pid = atoi( p)) == 0 )
    {
        g_print( _("Error: %s\n"), _("LXSession is not running." ));
        return 1;
    }

    /* parse command line arguments */
    context = g_option_context_new ("");
    g_option_context_add_main_entries (context, opt_entries, GETTEXT_PACKAGE);
    g_option_context_add_group (context, gtk_get_option_group(TRUE));
    /* gtk_init( &argc, &argv ); is not needed if g_option_context_parse is called */
    if( G_UNLIKELY( ! g_option_context_parse (context, &argc, &argv, &err) ) )
    {
        g_print( _("Error: %s\n"), err->message );
        g_error_free( err );
        return 1;
    }
    g_option_context_free( context );

    back = create_background();

    /* check if the window is composited */
    composited = gtk_widget_is_composited( back );

    gtk_icon_theme_append_search_path( gtk_icon_theme_get_default(),
                                            PACKAGE_DATA_DIR "/lxsession/images" );

    dlg = gtk_dialog_new_with_buttons( _("Logout"), (GtkWindow*)back, GTK_DIALOG_MODAL,
                                               GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL, NULL );
    gtk_container_set_border_width( (GtkContainer*)dlg, 6 );
    vbox = ((GtkDialog*)dlg)->vbox;

    if( banner )
    {
        GtkWidget* img = gtk_image_new_from_file( banner );
        banner_pos = get_banner_position();
        switch( banner_pos )
        {
        case GTK_POS_LEFT:
        case GTK_POS_RIGHT:
            box = gtk_hbox_new( FALSE,2 );
            gtk_box_pack_start( GTK_BOX(vbox), box, TRUE, TRUE, 2 );

            if( banner_pos == GTK_POS_LEFT )
            {
                gtk_box_pack_start( GTK_BOX(box), img, FALSE, TRUE, 2 );
                gtk_box_pack_start( GTK_BOX(box), gtk_vseparator_new(), FALSE, TRUE, 2 );
            }
            else
            {
                gtk_box_pack_end( GTK_BOX(box), img, FALSE, TRUE, 2 );
                gtk_box_pack_end( GTK_BOX(box), gtk_vseparator_new(), FALSE, TRUE, 2 );
            }
            vbox = gtk_vbox_new( FALSE, 2 );
            gtk_box_pack_start( GTK_BOX(box), vbox, TRUE, TRUE, 2 );
            gtk_misc_set_alignment( GTK_MISC(img), 0.5, 0.0 );
            break;
        case GTK_POS_TOP:
        case GTK_POS_BOTTOM:
            if( banner_pos == GTK_POS_TOP )
            {
                gtk_box_pack_start( GTK_BOX(vbox), img, FALSE, TRUE, 2 );
                gtk_box_pack_start( GTK_BOX(vbox), gtk_hseparator_new(), FALSE, TRUE, 2 );
            }
            else
            {
                gtk_box_pack_end( GTK_BOX(vbox), img, FALSE, TRUE, 2 );
                gtk_box_pack_end( GTK_BOX(vbox), gtk_hseparator_new(), FALSE, TRUE, 2 );
            }
            break;
        }
    }

    label = gtk_label_new("");
    if( ! prompt ) {
        const char* session_name = g_getenv("DESKTOP_SESSION");
        if( ! session_name )
            session_name = "LXDE";
        /* %s is the name of the desktop session */
        prompt = g_strdup_printf( _("<b><big>Logout %s session?</big></b>"), session_name );
    }

    gtk_label_set_markup( GTK_LABEL(label), prompt );
    gtk_box_pack_start( GTK_BOX(vbox), label, FALSE, FALSE, 4 );

    check_available_actions();

    if( available_actions & LOGOUT_ACTION_SHUTDOWN )
    {
        btn = create_dlg_btn(_("Sh_utdown"), "system-shutdown", LOGOUT_ACTION_SHUTDOWN );
        gtk_box_pack_start( GTK_BOX(vbox), btn, FALSE, FALSE, 4 );
    }
    if( available_actions & LOGOUT_ACTION_REBOOT )
    {
        btn = create_dlg_btn(_("_Reboot"), "gnome-session-reboot", LOGOUT_ACTION_REBOOT );
        gtk_box_pack_start( GTK_BOX(vbox), btn, FALSE, FALSE, 4 );
    }
    if( available_actions & LOGOUT_ACTION_SUSPEND )
    {
        btn = create_dlg_btn(_("_Suspend"), "gnome-session-suspend", LOGOUT_ACTION_SUSPEND );
        gtk_box_pack_start( GTK_BOX(vbox), btn, FALSE, FALSE, 4 );
    }
    if( available_actions & LOGOUT_ACTION_HIBERNATE )
    {
        btn = create_dlg_btn(_("_Hibernate"), "gnome-session-hibernate", LOGOUT_ACTION_HIBERNATE );
        gtk_box_pack_start( GTK_BOX(vbox), btn, FALSE, FALSE, 4 );
    }

    /* If GDM or KDM is running */
    if( g_file_test("/var/run/gdm_socket", G_FILE_TEST_EXISTS)
        || g_file_test("/tmp/.gdm_socket", G_FILE_TEST_EXISTS)
        || g_file_test("/var/run/kdm.pid", G_FILE_TEST_EXISTS) )
    {
        btn = create_dlg_btn(_("S_witch User"), "gnome-session-switch", LOGOUT_ACTION_SWITCH_USER );
        gtk_box_pack_start( GTK_BOX(vbox), btn, FALSE, FALSE, 4 );
    }

    btn = create_dlg_btn(_("_Logout"), "system-log-out", GTK_RESPONSE_OK );
    gtk_box_pack_start( GTK_BOX(vbox), btn, FALSE, FALSE, 4 );

    gtk_window_set_position( GTK_WINDOW(dlg), GTK_WIN_POS_CENTER_ALWAYS );
    gtk_window_set_decorated( GTK_WINDOW(dlg), FALSE );
    gtk_widget_show_all( dlg );

    gtk_window_set_keep_above( (GtkWindow*)dlg, TRUE );

    gdk_pointer_grab( dlg->window, TRUE, 0, NULL, NULL, GDK_CURRENT_TIME );
    gdk_keyboard_grab( dlg->window, TRUE, GDK_CURRENT_TIME );
//  if( !composited ) gdk_x11_grab_server();

    switch( (res = gtk_dialog_run( (GtkDialog*)dlg )) )
    {
        case LOGOUT_ACTION_SHUTDOWN:
        case LOGOUT_ACTION_REBOOT:
        case LOGOUT_ACTION_SUSPEND:
        case LOGOUT_ACTION_HIBERNATE:
        case LOGOUT_ACTION_SWITCH_USER:
        case GTK_RESPONSE_OK:
            break;
        default:
            gtk_widget_destroy( dlg );
            gtk_widget_destroy( back );
            gdk_pointer_ungrab( GDK_CURRENT_TIME );
            gdk_keyboard_ungrab( GDK_CURRENT_TIME );
            return 0;
    }
//  if( !composited ) gdk_x11_ungrab_server();
    gdk_pointer_ungrab( GDK_CURRENT_TIME );
    gdk_keyboard_ungrab( GDK_CURRENT_TIME );

    gtk_widget_destroy( dlg );
    gtk_widget_destroy( back );

    if( res != GTK_RESPONSE_OK )
    {
        if( res == LOGOUT_ACTION_SWITCH_USER )
        {
	   	    if( g_file_test("/var/run/gdm_socket", G_FILE_TEST_EXISTS) || g_file_test("/tmp/.gdm_socket", G_FILE_TEST_EXISTS) )
            	g_spawn_command_line_sync ("gdmflexiserver --startnew", NULL, NULL, NULL, NULL);
            else if ( g_file_test("/var/run/kdm.pid", G_FILE_TEST_EXISTS) )
            	g_spawn_command_line_sync ("kdmctl reserve", NULL, NULL, NULL, NULL);
            return 0;
        }

        if( use_hal )
            xfsm_shutdown_helper_hal_send( res );
        else
            gdm_set_logout_action( res );

        if( res != LOGOUT_ACTION_SUSPEND && res != LOGOUT_ACTION_HIBERNATE )
            kill( pid, SIGTERM );   /* ask the session manager to do fast logout */
    }
    else
    {
        kill( pid, SIGUSR1 );   /* ask the session manager to slow log out */
    }

    return 0;
}
