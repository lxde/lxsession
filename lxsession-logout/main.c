/*
 *      main.c -lxsession-logout for LXSession
 *
 *      Copyright 2008 PCMan <pcman.tw@gmail.com>
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

#include "gdm-logout-action.h"

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

static GtkWidget* create_background()
{
    GtkWidget *back = NULL, *img;
    GdkPixbuf *tmp, *shot;
    GdkScreen *screen;

    screen = gdk_screen_get_default();

    tmp = gdk_pixbuf_get_from_drawable( NULL,
                                        gdk_get_default_root_window(),
                                        NULL,
                                        0, 0, 0, 0,
                                        gdk_screen_get_width(screen),
                                        gdk_screen_get_height(screen) );

    shot = gdk_pixbuf_composite_color_simple( tmp,
                                              gdk_screen_get_width(screen),
                                              gdk_screen_get_height(screen),
                                              GDK_INTERP_NEAREST,
                          128, gdk_screen_get_width(screen),
                          0x000000, 0x000000);
    g_object_unref( tmp );

    back = gtk_window_new( GTK_WINDOW_TOPLEVEL );
    gtk_widget_set_app_paintable( back, TRUE );
    gtk_widget_set_double_buffered( back, FALSE );
    img = gtk_image_new_from_pixbuf( shot );
    g_object_unref( shot );
    gtk_container_add( back, img );
    gtk_window_fullscreen( back );
    gtk_window_set_decorated( back, FALSE );
    gtk_window_set_keep_above( (GtkWindow*)back, TRUE );
    gtk_widget_show_all( back );

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
    gtk_button_set_alignment( (GtkButton*)btn, 0.1, 0.5 );
    g_signal_connect( btn, "clicked", G_CALLBACK(btn_clicked), GINT_TO_POINTER(response) );
    if( icon )
    {
        GtkWidget* img = gtk_image_new_from_icon_name( icon, GTK_ICON_SIZE_BUTTON );
        gtk_button_set_image( btn, img );
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

int main( int argc, char** argv )
{
    GtkWidget *back = NULL, *dlg, *check, *btn, *label, *box = NULL, *vbox;
    GtkPositionType banner_pos;
    GdkPixbuf *tmp, *shot;
    GdkScreen *screen;
    int res;
    const char* p;
    char* file;
    GPid pid;
    GOptionContext *context;
    GError* err = NULL;

#ifdef ENABLE_NLS
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

    gtk_icon_theme_append_search_path( gtk_icon_theme_get_default(),
                                            PACKAGE_DATA_DIR "/images" );

    dlg = gtk_dialog_new_with_buttons( _("Logout"), (GtkWindow*)back, GTK_DIALOG_MODAL,
                                               GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL, NULL );

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
            gtk_box_pack_start( vbox, box, TRUE, TRUE, 2 );

            if( banner_pos == GTK_POS_LEFT )
            {
                gtk_box_pack_start( box, img, FALSE, TRUE, 2 );
                gtk_box_pack_start( box, gtk_vseparator_new(), FALSE, TRUE, 2 );
            }
            else
            {
                gtk_box_pack_end( box, img, FALSE, TRUE, 2 );
                gtk_box_pack_end( box, gtk_vseparator_new(), FALSE, TRUE, 2 );
            }
            vbox = gtk_vbox_new( FALSE, 2 );
            gtk_box_pack_start( box, vbox, TRUE, TRUE, 2 );
            gtk_misc_set_alignment( (GtkMisc*)img, 0.5, 0.0 );
            break;
        case GTK_POS_TOP:
        case GTK_POS_BOTTOM:
            if( banner_pos == GTK_POS_TOP )
            {
                gtk_box_pack_start( vbox, img, FALSE, TRUE, 2 );
                gtk_box_pack_start( vbox, gtk_hseparator_new(), FALSE, TRUE, 2 );
            }
            else
            {
                gtk_box_pack_end( vbox, img, FALSE, TRUE, 2 );
                gtk_box_pack_end( vbox, gtk_hseparator_new(), FALSE, TRUE, 2 );
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

    gtk_label_set_markup( label, prompt );
    gtk_box_pack_start( vbox, label, FALSE, FALSE, 4 );

    check = gtk_check_button_new_with_label(_("Save current session"));

    if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_SHUTDOWN) )
    {
        btn = create_dlg_btn(_("Sh_utdown"), "gnome-session-halt", GDM_LOGOUT_ACTION_SHUTDOWN );
        gtk_box_pack_start( vbox, btn, FALSE, FALSE, 4 );
    }
    if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_REBOOT) )
    {
        btn = create_dlg_btn(_("_Reboot"), "gnome-session-reboot", GDM_LOGOUT_ACTION_REBOOT );
        gtk_box_pack_start( vbox, btn, FALSE, FALSE, 4 );
    }
    if( gdm_supports_logout_action(GDM_LOGOUT_ACTION_SUSPEND) )
    {
        btn = create_dlg_btn(_("_Suspend"), "gnome-session-suspend", GDM_LOGOUT_ACTION_SUSPEND );
        gtk_box_pack_start( vbox, btn, FALSE, FALSE, 4 );
    }

    btn = create_dlg_btn(_("_Logout"), "gnome-session-logout", GTK_RESPONSE_OK );
    gtk_box_pack_start( vbox, btn, FALSE, FALSE, 4 );

    gtk_toggle_button_set_active( check, TRUE );
    gtk_box_pack_start( vbox, check, FALSE, FALSE, 4);
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
            gtk_widget_destroy( back );
            gdk_pointer_ungrab( GDK_CURRENT_TIME );
            gdk_keyboard_ungrab( GDK_CURRENT_TIME );
            return 0;
    }

    gdk_pointer_ungrab( GDK_CURRENT_TIME );
    gdk_keyboard_ungrab( GDK_CURRENT_TIME );

    file = g_strdup_printf( "/tmp/lx-save_session-%s-%s" , g_get_user_name(), g_getenv("DISPLAY") );

    if( gtk_toggle_button_get_active( check ) )
    {
        creat( file, 0600 );
    }
    else
    {
        unlink( file );
    }
    g_free( file );

    gtk_widget_destroy( dlg );
    gtk_widget_destroy( back );

    if( res != GTK_RESPONSE_OK )
    {
        gdm_set_logout_action( res );
        if( res != GDM_LOGOUT_ACTION_SUSPEND )
            kill( pid, SIGTERM );   /* ask the session manager to do fast log out */
    }
    else
    {
        kill( pid, SIGUSR1 );   /* ask the session manager to slow log out */
    }

    return 0;
}
