#include <gtk/gtk.h>
#include <glib/gi18n.h>

#include "gdm-logout-action.h"

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

int main( int argc, char** argv )
{
    GtkWidget *back = NULL, *img, *dlg, *check;
    GdkPixbuf *tmp, *shot;
    GdkScreen *screen;
    int res;
    const char* p;
    GPid pid;

#ifdef ENABLE_NLS
    bindtextdomain ( GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR );
    bind_textdomain_codeset ( GETTEXT_PACKAGE, "UTF-8" );
    textdomain ( GETTEXT_PACKAGE );
#endif

    p = g_getenv("_LXSESSION_PID");
    if( ! p || (pid = atoi( p)) == 0 )
    {
        g_print( _("LXSession is not running..." ));
        return 1;
    }

    gtk_init( &argc, &argv );

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
    gtk_widget_show_all( back );
//#endif

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
//#if 0
            gtk_widget_destroy( back );
//#endif
            GDK_THREADS_LEAVE();
            gdk_pointer_ungrab( GDK_CURRENT_TIME );
            gdk_keyboard_ungrab( GDK_CURRENT_TIME );
            return;
    }

    gdk_pointer_ungrab( GDK_CURRENT_TIME );
    gdk_keyboard_ungrab( GDK_CURRENT_TIME );

    if( gtk_toggle_button_get_active( check ) )
    {
#if 0
        wantShutdown = 1;
        checkpoint_from_signal = 1;
#endif
    }
    /*
    else
        sig_term_handler( SIGTERM );
    */

    gtk_widget_destroy( dlg );
    gtk_widget_destroy( back );


    if( res != GTK_RESPONSE_OK ) {
        gdm_set_logout_action( res );
    }

    return 0;
}
