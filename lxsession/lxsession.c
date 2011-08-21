/*
 *      lxsession.c
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <glib/gi18n.h>
#include <stdio.h>
#include <glib.h>

#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>

#include <wordexp.h> /* for shell expansion */

/* for X11 stuff */
#include <X11/X.h>
#include <X11/Xproto.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

#include "lxsession.h"
#include "xdg-autostart.h"
#include "settings-daemon.h"
#include "polkit-agent/lxpolkit.h"

static gboolean no_xsettings = FALSE; /* disable settings daemon */
static gboolean reload_settings = FALSE; /* reload settings daemon */
static gboolean no_autostart = FALSE; /* no autostart */
static gboolean no_polkit = FALSE; /* no policykit agent. */

const char *session_name = NULL;
const char* de_name = NULL;

char* window_manager = NULL; /* will be accessed by settings-daemon.c */

static GOptionEntry option_entries[] =
{
    {"session", 's', 0, G_OPTION_ARG_STRING, &session_name, "specify name of the desktop session profile", "<name>"},
    {"desktop-environment", 'e', 0, G_OPTION_ARG_STRING, &de_name, "specify name of DE, such as LXDE, GNOME, or XFCE.", "<name>"},
    {"reload", 'r', 0, G_OPTION_ARG_NONE, &reload_settings, "reload configurations (for Xsettings daemon)", NULL},
    {"disable-xsettings", 'n', 0, G_OPTION_ARG_NONE, &no_xsettings, "disable Xsettings daemon support", NULL},
    {"disable-autostart", 'd', 0, G_OPTION_ARG_NONE, &no_autostart, "disable autostart applications", NULL},
    {"disable-polkit", 'p', 0, G_OPTION_ARG_NONE, &no_polkit, "disable PolicyKit authentication agent", NULL},
    { NULL }
};

static Atom CMD_ATOM; /* for private client message */
Display* xdisplay = NULL; /* X11 Display */

/* name of environment variables */
/* Disable not used
static char sm_env[] = "SESSION_MANAGER";
*/
static char display_env[] = "DISPLAY";
static char pid_env[] = "_LXSESSION_PID";

static char prog_name[]="lxsession";
static char autostart_filename[]="autostart";

static GPid run_app( const char* cmd, gboolean guarded );
static void start_session();

static void sig_term_handler ( int sig )
{
    /* FIXME: this is not correct as we should not do complicated thing here.
     * Writing to a fd to signal TERM and monitor the fd with io channel
     * is the standard way. */
    gtk_main_quit();
}

void lxsession_quit()
{
    gtk_main_quit();
}

static void register_signals()
{
    /* Ignore SIGPIPE */
    signal( SIGPIPE, SIG_IGN );

#if 0
    action.sa_handler = g_child_watch_signal_handler;
    sigemptyset (&action.sa_mask);
    action.sa_flags = SA_RESTART | SA_NOCLDSTOP;
    sigaction (SIGCHLD, &action, NULL);
#endif

    /* If we get a SIGTERM, do logout */
    signal( SIGTERM, sig_term_handler );
}

GKeyFile* load_session_config( const char* config_filename )
{
    const gchar* const *dirs = g_get_system_config_dirs();
    const gchar* const *dir;
    GKeyFile* kf = g_key_file_new();
    char* filename;
    gboolean ret;

    /* load user-specific session config */
    filename = g_build_filename( g_get_user_config_dir(), prog_name, session_name, config_filename, NULL );
    ret = g_key_file_load_from_file(kf, filename, 0, NULL);
    g_free( filename );

    if( ! ret ) /* user specific file is not found */
    {
        /* load system-wide session config files */
        for( dir = dirs; *dir; ++dir )
        {
            filename = g_build_filename( *dir, prog_name, session_name, config_filename, NULL );
            ret = g_key_file_load_from_file(kf, filename, 0, NULL);
            g_free( filename );
            if(ret)
                break;
        }
    }

    if( G_UNLIKELY(!ret) )
    {
        g_key_file_free(kf);
        return NULL;
    }
    return kf;
}

static void on_child_exit( GPid pid, gint status, gchar* cmd )
{
    int sig = WTERMSIG( status );
    /* if the term signal is not SIGTERM or SIGKILL, this might be a crash! */
    if( sig && sig != SIGTERM && sig != SIGKILL )
        run_app( cmd, TRUE );
}

/* Returns pid if succesful, returns -1 if errors happen. */
GPid run_app( const char* cmd, gboolean guarded )
{
    GPid pid = -1;
    wordexp_t we;
    GSpawnFlags flags = guarded ? G_SPAWN_DO_NOT_REAP_CHILD|G_SPAWN_SEARCH_PATH : G_SPAWN_SEARCH_PATH;

    if( wordexp(cmd, &we, 0) == 0)
    {
        g_spawn_async( NULL, we.we_wordv, NULL, flags, NULL, NULL, &pid, NULL );
        wordfree(&we);
    }

    if(guarded && pid > 0)
    {
        g_child_watch_add_full( G_PRIORITY_DEFAULT_IDLE, pid,
                                (GChildWatchFunc)on_child_exit,
                                g_strdup( cmd ), (GDestroyNotify)g_free );
    }
    return pid;
}

static void load_default_apps( const char* filename )
{
    char buf[1024];
    int len;
    FILE* file = fopen( filename, "r" );
    if( file )
    {
        while ( fgets( buf, sizeof(buf) - 2, file ) )
        {
            if ( buf[0] == '\0' || buf[0] == '\n' || buf[0] == '#' )
                continue;  /* a comment */
            len = strlen ( buf );
            if( buf[ len - 1 ] == '\n' ) /* remove the '\n' at the end of line */
            {
                --len;
                buf[ len ] = '\0';
            }
            switch(buf[0])
            {
            case '@': /* if the app should be restarted on crash */
                run_app( buf + 1, TRUE );
                break;
            default: /* just run the program */
                run_app( buf, FALSE );
            }
        }
        fclose( file );
    }
}

/*
 * system wide default config is /etc/xdg/lxsession/SESSION_NAME/desktop.conf
 * system wide default apps are listed in /etc/xdg/lxsession/SESSION_NAME/autostart
 */
void start_session()
{
    const gchar* const *dirs = g_get_system_config_dirs();
    const gchar* const *dir;
    char* filename;

    /* run window manager first */
    if( G_LIKELY( window_manager ) )
        run_app( window_manager, TRUE );

    if( G_UNLIKELY( !no_autostart ) )

    {
    /* load system-wide default apps */
    for( dir = dirs; *dir; ++dir )
    {
        filename = g_build_filename( *dir, prog_name, session_name, autostart_filename, NULL );
        load_default_apps( filename );
        g_free( filename );
    }
    /* load user-specific default apps */
    filename = g_build_filename( g_get_user_config_dir(), prog_name, session_name, autostart_filename, NULL );
    load_default_apps( filename );
    g_free( filename );

    /* Support autostart spec of freedesktop.org if not disable*/
    xdg_autostart( session_name );

    }
}


static gboolean single_instance_check()
{
    /* NOTE: this is a hack to do single instance */
    XGrabServer(xdisplay);
    if(XGetSelectionOwner(xdisplay, CMD_ATOM))
    {
        XUngrabServer(xdisplay);
        XCloseDisplay(xdisplay);
        return FALSE;
    }
    XSetSelectionOwner(xdisplay, CMD_ATOM, DefaultRootWindow(xdisplay), CurrentTime);
    XUngrabServer(xdisplay);
    return TRUE;
}

static GdkFilterReturn x11_event_filter(GdkXEvent *xevent, GdkEvent *event, gpointer data)
{
    GdkAtom message_type;
    /* we only want client message */
    if(((XEvent *)xevent)->type == ClientMessage)
    {
        XClientMessageEvent *evt = (XClientMessageEvent *)xevent;
        if (evt->message_type == CMD_ATOM)
        {
            int cmd = evt->data.b[0];
            switch( cmd )
            {
            case LXS_RELOAD:    /* reload all settings */
                settings_deamon_reload();
                break;
            case LXS_EXIT:
                lxsession_quit();
                break;
            }
        }
    }
    return GDK_FILTER_CONTINUE;
}

void send_internal_command(int cmd)
{
    Window root = DefaultRootWindow(xdisplay);
    XEvent ev;

    memset(&ev, 0, sizeof(ev));
    ev.xclient.type = ClientMessage;
    ev.xclient.window = root;
    ev.xclient.message_type = CMD_ATOM;
    ev.xclient.format = 8;

    ev.xclient.data.l[0] = cmd;

    XSendEvent(xdisplay, root, False,
               SubstructureRedirectMask|SubstructureNotifyMask, &ev);
    XSync(xdisplay, False);
}

int main(int argc, char** argv)
{
    char str[16];
    GKeyFile* kf;
    GError* err = NULL;

    /* gettext support */
#ifdef ENABLE_NLS
    bindtextdomain ( GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR );
    bind_textdomain_codeset ( GETTEXT_PACKAGE, "UTF-8" );
    textdomain ( GETTEXT_PACKAGE );
#endif

    /* initialize GTK+ and parse the command line arguments */
    if(G_UNLIKELY(!gtk_init_with_args(&argc, &argv, "",
                  option_entries, GETTEXT_PACKAGE, &err)))
    {
        g_print( "Error: %s\n", err->message );
        return 1;
    }

    xdisplay = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    /* Initialize XAtom for use in single instance check.
     * FIXME: later this may be replaced with gdbus.
     * according to the spec, private Atoms should prefix their names with _. */
    CMD_ATOM = XInternAtom(xdisplay, "_LXSESSION", False);

    /* send command to existing daemon to reload settings */
    if(G_UNLIKELY(reload_settings))
    {
        send_internal_command(LXS_RELOAD);
        return 0;
    }
    else if(G_UNLIKELY(!single_instance_check()))
    {
        /* only one instance is allowed for each X. */
        g_print(_("Only one lxsession can be executed at a time\n"));
        return 1;
    }

    /* setup signal handlers */
    register_signals();

    /* add a filter to listen to client message */
    gdk_window_add_filter(NULL, x11_event_filter, NULL);

    /* set pid */
    g_snprintf( str, 16, "%d", getpid() );
    g_setenv(pid_env, str, TRUE );

    if(G_UNLIKELY(!session_name))
        session_name = "LXDE";
    g_setenv( "DESKTOP_SESSION", session_name, TRUE );

    if (G_UNLIKELY(!de_name))
        de_name = session_name;
    g_setenv( "XDG_CURRENT_DESKTOP", de_name, TRUE );

    /* FIXME: load environment variables? */

    /* Load desktop session config file */
    kf = load_session_config(CONFIG_FILE_NAME);
    if( !kf )
        return 1;

    window_manager = g_key_file_get_string( kf, "Session", "window_manager", NULL );

    if( G_LIKELY(!no_xsettings) )
        start_settings_daemon(kf);

    g_key_file_free(kf);

    /* launch built-in policykit agent */
    if(!no_polkit)
        policykit_agent_init();

    /* start desktop session and load autostart applications */
    start_session();

    /* run the main loop */
    gtk_main();

    gdk_window_remove_filter(NULL, x11_event_filter, NULL);

    if(!no_polkit)
        policykit_agent_finalize();

    return 0;
}

void lxsession_show_msg(GtkWindow* parent, GtkMessageType type, const char* msg)
{
    GtkWidget* dlg = gtk_message_dialog_new(parent, GTK_DIALOG_MODAL, type, GTK_BUTTONS_OK, msg);
    const char* title = NULL;
    switch(type)
    {
    case GTK_MESSAGE_ERROR:
        title = _("Error");
        break;
    case GTK_MESSAGE_INFO:
        title = _("Information");
        break;
    }
    if(title)
        gtk_window_set_title(GTK_WINDOW(dlg), title);
    gtk_dialog_run(GTK_DIALOG(dlg));
    gtk_widget_destroy(dlg);
}
