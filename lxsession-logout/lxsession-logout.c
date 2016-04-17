/**
 * Copyright (c) 2010 LxDE Developers, see the file AUTHORS for details.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <config.h>
#include <locale.h>
#include <stdlib.h>
#include <gdk/gdkkeysyms.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <glib/gi18n.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <X11/Xatom.h>
#include <X11/Xlib.h>

#include "lxsession-logout-dbus-interface.h"

/* Command parameters. */
static char * prompt = NULL;
static char * banner_side = NULL;
static char * banner_path = NULL;

static GOptionEntry opt_entries[] =
{
    { "prompt", 'p', 0, G_OPTION_ARG_STRING, &prompt, N_("Custom message to show on the dialog"), N_("message") },
    { "banner", 'b', 0, G_OPTION_ARG_STRING, &banner_path, N_("Banner to show on the dialog"), N_("image file") },
    { "side", 's', 0, G_OPTION_ARG_STRING, &banner_side, N_("Position of the banner"), "top|left|right|bottom" },
    { NULL }
};

typedef struct {
    GPid lxsession_pid;			/* Process ID of lxsession */
    GtkWidget * error_label;		/* Text of an error, if we get one */

    int shutdown_available : 1;		/* Shutdown is available */
    int reboot_available : 1;		/* Reboot is available */
    int suspend_available : 1;		/* Suspend is available */
    int hibernate_available : 1;	/* Hibernate is available */
    int switch_user_available : 1;	/* Switch User is available */

    int shutdown_systemd : 1;		/* Shutdown is available via systemd */
    int reboot_systemd : 1;		/* Reboot is available via systemd */
    int suspend_systemd : 1;		/* Suspend is available via systemd */
    int hibernate_systemd : 1;		/* Hibernate is available via systemd */
    int shutdown_ConsoleKit : 1;	/* Shutdown is available via ConsoleKit */
    int reboot_ConsoleKit : 1;		/* Reboot is available via ConsoleKit */
    int suspend_ConsoleKit : 1;		/* Suspend is available via ConsoleKit */
    int hibernate_ConsoleKit : 1;	/* Hibernate is available via ConsoleKit */
    int suspend_UPower : 1;		/* Suspend is available via UPower */
    int hibernate_UPower : 1;		/* Hibernate is available via UPower */
    int switch_user_GDM : 1;		/* Switch User is available via GDM */
    int switch_user_LIGHTDM : 1;	/* Switch User is available via GDM */
    int switch_user_KDM : 1;		/* Switch User is available via LIGHTDM */
    int switch_user_LXDM : 1;		/* Switch User is available via LXDM */
    int ltsp : 1;			/* Shutdown and reboot is accomplished via LTSP */

    int lock_screen : 1;                /* Lock screen available */

} HandlerContext;

static gboolean lock_screen(void);
static const gchar* determine_lock_screen(void);
static gboolean verify_running(const char * display_manager, const char * executable);
static void logout_clicked(GtkButton * button, HandlerContext * handler_context);
static void change_root_property(GtkWidget* w, const char* prop_name, const char* value);
static void shutdown_clicked(GtkButton * button, HandlerContext * handler_context);
static void reboot_clicked(GtkButton * button, HandlerContext * handler_context);
static void suspend_clicked(GtkButton * button, HandlerContext * handler_context);
static void hibernate_clicked(GtkButton * button, HandlerContext * handler_context);
static void switch_user_clicked(GtkButton * button, HandlerContext * handler_context);
static void cancel_clicked(GtkButton * button, gpointer user_data);
static GtkPositionType get_banner_position(void);
static GdkPixbuf * get_background_pixbuf(void);
#ifdef USE_GTK3
gboolean draw(GtkWidget * widget, cairo_t * cr, GdkPixbuf * pixbuf);
#else
gboolean expose_event(GtkWidget * widget, GdkEventExpose * event, GdkPixbuf * pixbuf);
#endif

/* Try to run lxlock command in order to lock the screen, return TRUE on
 * success, FALSE if command execution failed
 */
static gboolean lock_screen(void)
{
    const gchar* program = determine_lock_screen();

    if (program)
    {
        g_spawn_command_line_async(program, NULL);
        return TRUE;
    }
    return FALSE;
}

static const gchar* determine_lock_screen(void)
{
    const gchar* program = NULL;

    if (g_find_program_in_path("lxlock"))
    {
        program = "lxlock";
    }
    else if (g_find_program_in_path("xdg-screensaver"))
    {
        program = "xdg-screensaver lock";
    }
    return program;
}


/* Verify that a program is running and that an executable is available. */
static gboolean verify_running(const char * display_manager, const char * executable)
{
    /* See if the executable we need to run is in the path. */
    gchar * full_path = g_find_program_in_path(executable);
    if (full_path != NULL)
    {
        g_free(full_path);

        /* Form the filespec of the pid file for the display manager. */
        char buffer[PATH_MAX];
        sprintf(buffer, "/var/run/%s.pid", display_manager);

        if (!g_file_test (buffer, G_FILE_TEST_IS_REGULAR))
            sprintf(buffer, "/var/run/%s/%s.pid", display_manager, display_manager);

        /* Open the pid file. */
        int fd = open(buffer, O_RDONLY);
        if (fd >= 0)
        {
            /* Pid file exists.  Read it. */
            ssize_t length = read(fd, buffer, sizeof(buffer));
            close(fd);
            if (length > 0)
            {
                /* Null terminate the buffer and convert the pid. */
                buffer[length] = '\0';
                pid_t pid = atoi(buffer);
                if (pid > 0)
                {
                    /* Form the filespec of the command line file under /proc.
                     * This is Linux specific.  Should be conditionalized to the appropriate /proc layout for
                     * other systems.  Your humble developer has no way to test on other systems. */
                    sprintf(buffer, "/proc/%d/cmdline", pid);

                    /* Open the file. */
                    int fd = open(buffer, O_RDONLY);
                    if (fd >= 0)
                    {
                        /* Read the command line. */
                        ssize_t length = read(fd, buffer, sizeof(buffer));
                        close(fd);
                        if (length > 0)
                        {
                            /* Null terminate the buffer and look for the display manager name in the command.
                             * If found, return success. */
                            buffer[length] = '\0';
                            if (strstr(buffer, display_manager) != NULL)
                                return TRUE;
                        }
                    }
                }
            }
        }
    }
    return FALSE;
}

/* Handler for "clicked" signal on Logout button. */
static void logout_clicked(GtkButton * button, HandlerContext * handler_context)
{
    if (handler_context->lxsession_pid != 0)
    {
        kill(handler_context->lxsession_pid, SIGTERM);
    }
    else
    {
        /* Assume we are under openbox */
        g_spawn_command_line_async("openbox --exit", NULL);
    }
    gtk_main_quit();
}

/* Replace a property on the root window. */
static void change_root_property(GtkWidget* w, const char* prop_name, const char* value)
{
    GdkDisplay* dpy = gtk_widget_get_display(w);
    GdkWindow* root = gtk_widget_get_root_window(w);
    XChangeProperty(GDK_DISPLAY_XDISPLAY(dpy), GDK_WINDOW_XID(root),
                      XInternAtom(GDK_DISPLAY_XDISPLAY(dpy), prop_name, False), XA_STRING, 8,
                      PropModeReplace, (unsigned char*) value, strlen(value) + 1);
}

/* Handler for "clicked" signal on Shutdown button. */
static void shutdown_clicked(GtkButton * button, HandlerContext * handler_context)
{
    GError *err = NULL;
    gtk_label_set_text(GTK_LABEL(handler_context->error_label), NULL);

    if (handler_context->ltsp)
    {
        change_root_property(GTK_WIDGET(button), "LTSP_LOGOUT_ACTION", "HALT");
        if (handler_context->lxsession_pid != 0)
        {
            kill(handler_context->lxsession_pid, SIGTERM);
        }
    }
    else if (handler_context->shutdown_ConsoleKit)
        dbus_ConsoleKit_PowerOff(&err);
    else if (handler_context->shutdown_systemd)
        dbus_systemd_PowerOff(&err);

	if (err)
	{
		gtk_label_set_text(GTK_LABEL(handler_context->error_label), err->message);
		g_error_free (err);
	}
	else
    {
        gtk_main_quit();
    }
}

/* Handler for "clicked" signal on Reboot button. */
static void reboot_clicked(GtkButton * button, HandlerContext * handler_context)
{
    GError *err = NULL;
    gtk_label_set_text(GTK_LABEL(handler_context->error_label), NULL);

    if (handler_context->ltsp)
    {
        change_root_property(GTK_WIDGET(button), "LTSP_LOGOUT_ACTION", "REBOOT");
        if (handler_context->lxsession_pid != 0)
        {
            kill(handler_context->lxsession_pid, SIGTERM);
        }
    }
    else if (handler_context->reboot_ConsoleKit)
        dbus_ConsoleKit_Reboot(&err);
    else if (handler_context->reboot_systemd)
        dbus_systemd_Reboot(&err);

	if (err)
	{
		gtk_label_set_text(GTK_LABEL(handler_context->error_label), err->message);
		g_error_free (err);
	}
	else
    {
        gtk_main_quit();
    }
}

/* Handler for "clicked" signal on Suspend button. */
static void suspend_clicked(GtkButton * button, HandlerContext * handler_context)
{
    GError *err = NULL;
    gtk_label_set_text(GTK_LABEL(handler_context->error_label), NULL);

    lock_screen();
    if (handler_context->suspend_UPower)
        dbus_UPower_Suspend(&err);
    else if (handler_context->suspend_ConsoleKit)
        dbus_ConsoleKit_Suspend(&err);
    else if (handler_context->suspend_systemd)
        dbus_systemd_Suspend(&err);

	if (err)
	{
		gtk_label_set_text(GTK_LABEL(handler_context->error_label), err->message);
		g_error_free (err);
	}
	else
    {
        gtk_main_quit();
    }
}

/* Handler for "clicked" signal on Hibernate button. */
static void hibernate_clicked(GtkButton * button, HandlerContext * handler_context)
{
    GError *err = NULL;
    gtk_label_set_text(GTK_LABEL(handler_context->error_label), NULL);

    lock_screen();
    if (handler_context->hibernate_UPower)
        dbus_UPower_Hibernate(&err);
    else if (handler_context->hibernate_ConsoleKit)
        dbus_ConsoleKit_Hibernate(&err);
    else if (handler_context->hibernate_systemd)
        dbus_systemd_Hibernate(&err);

	if (err)
	{
		gtk_label_set_text(GTK_LABEL(handler_context->error_label), err->message);
		g_error_free (err);
	}
	else
    {
        gtk_main_quit();
    }
}

/* Handler for "clicked" signal on Switch User button. */
static void switch_user_clicked(GtkButton * button, HandlerContext * handler_context)
{
    GError *err = NULL;
    gtk_label_set_text(GTK_LABEL(handler_context->error_label), NULL);

    lock_screen();
    if (handler_context->switch_user_GDM)
        g_spawn_command_line_sync("gdmflexiserver --startnew", NULL, NULL, NULL, NULL);
    else if (handler_context->switch_user_KDM)
        g_spawn_command_line_sync("kdmctl reserve", NULL, NULL, NULL, NULL);
    else if (handler_context->switch_user_LIGHTDM)
        dbus_Lightdm_SwitchToGreeter(&err);
    else if(handler_context->switch_user_LXDM)
        g_spawn_command_line_sync("lxdm-binary -c USER_SWITCH", NULL, NULL, NULL, NULL);

	if (err)
	{
		gtk_label_set_text(GTK_LABEL(handler_context->error_label), err->message);
		g_error_free (err);
	}
	else
    {
        gtk_main_quit();
    }
}

/* Handler for "clicked" signal on Lock button. */
static void lock_screen_clicked(GtkButton * button, HandlerContext * handler_context)
{
    gtk_label_set_text(GTK_LABEL(handler_context->error_label), NULL);

    lock_screen();
    gtk_main_quit();
}

/* Handler for "clicked" signal on Cancel button. */
static void cancel_clicked(GtkButton * button, gpointer user_data)
{
    gtk_main_quit();
}

/* Convert the --side parameter to a GtkPositionType. */
static GtkPositionType get_banner_position(void)
{
    if (banner_side != NULL)
    {
        if (strcmp(banner_side, "right") == 0)
            return GTK_POS_RIGHT;
        if (strcmp(banner_side, "top") == 0)
            return GTK_POS_TOP;
        if (strcmp(banner_side, "bottom") == 0)
            return GTK_POS_BOTTOM;
    }
    return GTK_POS_LEFT;
}

/* Get the background pixbuf. */
static GdkPixbuf * get_background_pixbuf(void)
{
    /* Get the root window pixmap. */
    GdkScreen * screen = gdk_screen_get_default();
#ifdef USE_GTK3
    GdkPixbuf * pixbuf = gdk_pixbuf_get_from_window(
        gdk_get_default_root_window(),
        0,
        0,
        gdk_screen_get_width(screen),		/* Width */
        gdk_screen_get_height(screen));		/* Height */
#else
    GdkPixbuf * pixbuf = gdk_pixbuf_get_from_drawable(
        NULL,					/* Allocate a new pixbuf */
        gdk_get_default_root_window(),		/* The drawable */
        NULL,					/* Its colormap */
        0, 0, 0, 0,				/* Coordinates */
        gdk_screen_get_width(screen),		/* Width */
        gdk_screen_get_height(screen));		/* Height */
#endif

    /* Make the background darker. */
    if (pixbuf != NULL)
    {
        unsigned char * pixels = gdk_pixbuf_get_pixels(pixbuf);
        int width = gdk_pixbuf_get_width(pixbuf);
        int height = gdk_pixbuf_get_height(pixbuf);
        int pixel_stride = ((gdk_pixbuf_get_has_alpha(pixbuf)) ? 4 : 3);
        int row_stride = gdk_pixbuf_get_rowstride(pixbuf);
        int y;
        for (y = 0; y < height; y += 1)
        {
            unsigned char * p = pixels;
            int x;
            for (x = 0; x < width; x += 1)
            {
                p[0] = p[0] / 2;
                p[1] = p[1] / 2;
                p[2] = p[2] / 2;
                p += pixel_stride;
            }
            pixels += row_stride;
        }
    }
    return pixbuf;
}

/* Handler for "expose_event" on background. */
#ifdef USE_GTK3
gboolean draw(GtkWidget * widget, cairo_t * cr, GdkPixbuf * pixbuf)
#else
gboolean expose_event(GtkWidget * widget, GdkEventExpose * event, GdkPixbuf * pixbuf)
#endif
{
    gint x, y;

    if (pixbuf != NULL)
    {
        /* Copy the appropriate rectangle of the root window pixmap to the drawing area.
         * All drawing areas are immediate children of the toplevel window, so the allocation yields the source coordinates directly. */
#ifdef USE_GTK3
#elif GTK_CHECK_VERSION(2,14,0)
       cairo_t * cr = gdk_cairo_create (gtk_widget_get_window(widget));
       gdk_window_get_origin(gtk_widget_get_window(widget), &x, &y);
#else
       cairo_t * cr = gdk_cairo_create (widget->window);
       gdk_window_get_origin(widget->window, &x, &y);
#endif
       gdk_cairo_set_source_pixbuf (
           cr,
           pixbuf,
           -x,
           -y);

       cairo_paint (cr);
#ifndef USE_GTK3
       cairo_destroy(cr);
#endif
    }
    return FALSE;
}

static char lockfile[PATH_MAX];

/* Unlink lockfile on exit. */
static void main_at_exit(void)
{
    unlink(lockfile);
}

/* Main program. */
int main(int argc, char * argv[])
{
#ifdef ENABLE_NLS
    setlocale(LC_ALL, "");
    bindtextdomain(GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR);
    bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
    textdomain (GETTEXT_PACKAGE);
#endif

    HandlerContext handler_context;
    memset(&handler_context, 0, sizeof(handler_context));

    /* Get the lxsession PID. */
    const char * p = g_getenv("_LXSESSION_PID");
    if (p != NULL) handler_context.lxsession_pid = atoi(p);

    /* Create lock file to prevent more than one logout dialog per lxsession process. */
    sprintf(lockfile, "/tmp/.lxsession-logout-%d.lock", handler_context.lxsession_pid);
    int fd = open(lockfile, O_RDONLY|O_CREAT, 00600);
    if (fd >= 0)
    {
        if (flock(fd, LOCK_EX | LOCK_NB))
        {
            exit(EXIT_FAILURE);
        }
    }
    atexit(main_at_exit);

    /* Query DBus before GTK+ initialization!!! Otherwise a race may occur. */

    /* Initialize capabilities of the systemd mechanism. */
    if (dbus_systemd_CanPowerOff())
    {
        handler_context.shutdown_available = TRUE;
        handler_context.shutdown_systemd = TRUE;
    }
    if (dbus_systemd_CanReboot())
    {
        handler_context.reboot_available = TRUE;
        handler_context.reboot_systemd = TRUE;
    }
    if (dbus_systemd_CanSuspend())
    {
        handler_context.suspend_available = TRUE;
        handler_context.suspend_systemd = TRUE;
    }
    if (dbus_systemd_CanHibernate())
    {
        handler_context.hibernate_available = TRUE;
        handler_context.hibernate_systemd = TRUE;
    }

    /* Initialize capabilities of the ConsoleKit mechanism. */
    if (!handler_context.shutdown_available && dbus_ConsoleKit_CanPowerOff())
    {
        handler_context.shutdown_available = TRUE;
        handler_context.shutdown_ConsoleKit = TRUE;
    }
    if (!handler_context.reboot_available && dbus_ConsoleKit_CanReboot())
    {
        handler_context.reboot_available = TRUE;
        handler_context.reboot_ConsoleKit = TRUE;
    }
    if (!handler_context.suspend_available && dbus_ConsoleKit_CanSuspend())
    {
        handler_context.suspend_available = TRUE;
        handler_context.suspend_ConsoleKit = TRUE;
    }
    if (!handler_context.hibernate_available && dbus_ConsoleKit_CanHibernate())
    {
        handler_context.hibernate_available = TRUE;
        handler_context.hibernate_ConsoleKit = TRUE;
    }

    /* Initialize capabilities of the UPower mechanism. */
    if (!handler_context.suspend_available && dbus_UPower_CanSuspend())
    {
        handler_context.suspend_available = TRUE;
        handler_context.suspend_UPower = TRUE;
    }
    if (!handler_context.hibernate_available && dbus_UPower_CanHibernate())
    {
        handler_context.hibernate_available = TRUE;
        handler_context.hibernate_UPower = TRUE;
    }

    /* If we are under GDM, its "Switch User" is available. */
    if (verify_running("gdm", "gdmflexiserver"))
    {
        handler_context.switch_user_available = TRUE;
        handler_context.switch_user_GDM = TRUE;
    }

    /* If we are under GDM3, its "Switch User" is available. */
    if (verify_running("gdm3", "gdmflexiserver"))
    {
        handler_context.switch_user_available = TRUE;
        handler_context.switch_user_GDM = TRUE;
    }

    /* lightdm can be found by the env */
    if (g_getenv("XDG_SEAT_PATH"))
    {
        handler_context.switch_user_available = TRUE;
        handler_context.switch_user_LIGHTDM = TRUE;
    }

    /* If we are under KDM, its "Switch User" is available. */
    if (verify_running("kdm", "kdmctl"))
    {
        handler_context.switch_user_available = TRUE;
        handler_context.switch_user_KDM = TRUE;
    }

    if (verify_running("lxdm", "lxdm-binary"))
    {
        handler_context.switch_user_available = TRUE;
        handler_context.switch_user_LXDM = TRUE;
    }

    /* LTSP support */
    if (g_getenv("LTSP_CLIENT"))
    {
        handler_context.ltsp = TRUE;
        handler_context.shutdown_available = TRUE;
        handler_context.reboot_available = TRUE;
    }

    /* Lock screen */
    const gchar* very_lock_screen = determine_lock_screen();
    if (very_lock_screen)
    {
        handler_context.lock_screen = TRUE;
    }

    /* Initialize GTK (via g_option_context_parse) and parse command line arguments. */
    GOptionContext * context = g_option_context_new("");
    g_option_context_add_main_entries(context, opt_entries, GETTEXT_PACKAGE);
    g_option_context_add_group(context, gtk_get_option_group(TRUE));
    GError * err = NULL;
    if ( ! g_option_context_parse(context, &argc, &argv, &err))
    {
        g_print(_("Error: %s\n"), err->message);
        g_error_free(err);
        return 1;
    }
    g_option_context_free(context);

    /* Make the button images accessible. */
    gtk_icon_theme_append_search_path(gtk_icon_theme_get_default(), PACKAGE_DATA_DIR "/lxsession/images");

    /* Get the background pixbuf. */
    GdkPixbuf * pixbuf = get_background_pixbuf();

    /* Create the toplevel window. */
    GtkWidget * window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
    gtk_window_fullscreen(GTK_WINDOW(window));
    gtk_widget_set_app_paintable(window, TRUE);
#ifdef USE_GTK3
    g_signal_connect(G_OBJECT(window), "draw", G_CALLBACK(draw), pixbuf);
#else
    g_signal_connect(G_OBJECT(window), "expose_event", G_CALLBACK(expose_event), pixbuf);
#endif
    g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(gtk_main_quit), NULL);

    /* Toplevel container */
    GtkWidget* alignment = gtk_alignment_new(0.5, 0.5, 0.0, 0.0);
    gtk_container_add(GTK_CONTAINER(window), alignment);

    GtkWidget* center_area = gtk_event_box_new();
    gtk_container_add(GTK_CONTAINER(alignment), center_area);

#ifdef USE_GTK3
    gtk_style_context_add_class (gtk_widget_get_style_context (center_area), GTK_STYLE_CLASS_BACKGROUND);
#endif

    GtkWidget* center_vbox = gtk_vbox_new(FALSE, 6);
    gtk_container_set_border_width(GTK_CONTAINER(center_vbox), 12);
    gtk_container_add(GTK_CONTAINER(center_area), center_vbox);

    GtkWidget* controls = gtk_vbox_new(FALSE, 6);

    /* If specified, apply a user-specified banner image. */
    if (banner_path != NULL)
    {
        GtkWidget * banner_image = gtk_image_new_from_file(banner_path);
        GtkPositionType banner_position = get_banner_position();

        switch (banner_position)
        {
            case GTK_POS_LEFT:
            case GTK_POS_RIGHT:
                {
                /* Create a horizontal box to contain the image and the controls. */
                GtkWidget * box = gtk_hbox_new(FALSE, 2);
                gtk_box_pack_start(GTK_BOX(center_vbox), box, FALSE, FALSE, 0);

                /* Pack the image and a separator. */
                gtk_misc_set_alignment(GTK_MISC(banner_image), 0.5, 0.0);
                if (banner_position == GTK_POS_LEFT)
                {
                    gtk_box_pack_start(GTK_BOX(box), banner_image, FALSE, FALSE, 2);
                    gtk_box_pack_start(GTK_BOX(box), gtk_vseparator_new(), FALSE, FALSE, 2);
                    gtk_box_pack_start(GTK_BOX(box), controls, FALSE, FALSE, 2);
                }
                else
                {
                    gtk_box_pack_start(GTK_BOX(box), controls, FALSE, FALSE, 2);
                    gtk_box_pack_end(GTK_BOX(box), gtk_vseparator_new(), FALSE, FALSE, 2);
                    gtk_box_pack_end(GTK_BOX(box), banner_image, FALSE, FALSE, 2);
                }
                }
                break;

            case GTK_POS_TOP:
                gtk_box_pack_start(GTK_BOX(controls), banner_image, FALSE, FALSE, 2);
                gtk_box_pack_start(GTK_BOX(controls), gtk_hseparator_new(), FALSE, FALSE, 2);
                gtk_box_pack_start(GTK_BOX(center_vbox), controls, FALSE, FALSE, 0);
                break;

            case GTK_POS_BOTTOM:
                gtk_box_pack_end(GTK_BOX(controls), banner_image, FALSE, FALSE, 2);
                gtk_box_pack_end(GTK_BOX(controls), gtk_hseparator_new(), FALSE, FALSE, 2);
                gtk_box_pack_start(GTK_BOX(center_vbox), controls, FALSE, FALSE, 0);
                break;
        }
    }
    else
        gtk_box_pack_start(GTK_BOX(center_vbox), controls, FALSE, FALSE, 0);

    /* Create the label. */
    GtkWidget * label = gtk_label_new("");
    if (prompt == NULL)
    {
        const char * session_name = g_getenv("DESKTOP_SESSION");
        if (session_name == NULL)
            session_name = "LXDE";

        gchar *output = NULL;

        if (g_find_program_in_path("lsb_release"))
        {
            const gchar *command_line = "lsb_release -r -s";
            GError *error;
            if (!g_spawn_command_line_sync( command_line,
                                            &output,
                                            NULL,
                                            NULL,
                                            &error))
            {

                fprintf (stderr, "Error: %s\n", error->message);
                g_error_free (error);

            }
        }

        if (output == NULL)
        {
            output = "";
        }
        else
        {
            output[strlen ( output ) - 1] = '\0';
        }

        prompt = g_strdup_printf(_("<b><big>Logout %s %s session ?</big></b>"), session_name, output);
    }
    gtk_label_set_markup(GTK_LABEL(label), prompt);
    gtk_box_pack_start(GTK_BOX(controls), label, FALSE, FALSE, 4);

    /* Create the Shutdown button. */
    if (handler_context.shutdown_available)
    {
        GtkWidget * shutdown_button = gtk_button_new_with_mnemonic(_("Sh_utdown"));
        GtkWidget * image = gtk_image_new_from_icon_name("system-shutdown", GTK_ICON_SIZE_BUTTON);
        gtk_button_set_image(GTK_BUTTON(shutdown_button), image);
        gtk_button_set_alignment(GTK_BUTTON(shutdown_button), 0.0, 0.5);
        g_signal_connect(G_OBJECT(shutdown_button), "clicked", G_CALLBACK(shutdown_clicked), &handler_context);
        gtk_box_pack_start(GTK_BOX(controls), shutdown_button, FALSE, FALSE, 4);
    }

    /* Create the Reboot button. */
    if (handler_context.reboot_available)
    {
        GtkWidget * reboot_button = gtk_button_new_with_mnemonic(_("_Reboot"));
        GtkWidget * image = gtk_image_new_from_icon_name("gnome-session-reboot", GTK_ICON_SIZE_BUTTON);
        gtk_button_set_image(GTK_BUTTON(reboot_button), image);
        gtk_button_set_alignment(GTK_BUTTON(reboot_button), 0.0, 0.5);
        g_signal_connect(G_OBJECT(reboot_button), "clicked", G_CALLBACK(reboot_clicked), &handler_context);
        gtk_box_pack_start(GTK_BOX(controls), reboot_button, FALSE, FALSE, 4);
    }

    /* Create the Suspend button. */
    if (handler_context.suspend_available && !handler_context.ltsp)
    {
        GtkWidget * suspend_button = gtk_button_new_with_mnemonic(_("_Suspend"));
        GtkWidget * image = gtk_image_new_from_icon_name("gnome-session-suspend", GTK_ICON_SIZE_BUTTON);
        gtk_button_set_image(GTK_BUTTON(suspend_button), image);
        gtk_button_set_alignment(GTK_BUTTON(suspend_button), 0.0, 0.5);
        g_signal_connect(G_OBJECT(suspend_button), "clicked", G_CALLBACK(suspend_clicked), &handler_context);
        gtk_box_pack_start(GTK_BOX(controls), suspend_button, FALSE, FALSE, 4);
    }

    /* Create the Hibernate button. */
    if (handler_context.hibernate_available && !handler_context.ltsp)
    {
        GtkWidget * hibernate_button = gtk_button_new_with_mnemonic(_("_Hibernate"));
        GtkWidget * image = gtk_image_new_from_icon_name("gnome-session-hibernate", GTK_ICON_SIZE_BUTTON);
        gtk_button_set_image(GTK_BUTTON(hibernate_button), image);
        gtk_button_set_alignment(GTK_BUTTON(hibernate_button), 0.0, 0.5);
        g_signal_connect(G_OBJECT(hibernate_button), "clicked", G_CALLBACK(hibernate_clicked), &handler_context);
        gtk_box_pack_start(GTK_BOX(controls), hibernate_button, FALSE, FALSE, 4);
    }

    /* Create the Switch User button. */
    if (handler_context.switch_user_available && !handler_context.ltsp)
    {
        GtkWidget * switch_user_button = gtk_button_new_with_mnemonic(_("S_witch User"));
        GtkWidget * image = gtk_image_new_from_icon_name("gnome-session-switch", GTK_ICON_SIZE_BUTTON);
        gtk_button_set_image(GTK_BUTTON(switch_user_button), image);
        gtk_button_set_alignment(GTK_BUTTON(switch_user_button), 0.0, 0.5);
        g_signal_connect(G_OBJECT(switch_user_button), "clicked", G_CALLBACK(switch_user_clicked), &handler_context);
        gtk_box_pack_start(GTK_BOX(controls), switch_user_button, FALSE, FALSE, 4);
    }

    /* Create the Lock Screen button. */
    if (handler_context.lock_screen && !handler_context.ltsp)
    {
        GtkWidget * lock_screen_button = gtk_button_new_with_mnemonic(_("L_ock Screen"));
        GtkWidget * image = gtk_image_new_from_icon_name("system-lock-screen", GTK_ICON_SIZE_BUTTON);
        gtk_button_set_image(GTK_BUTTON(lock_screen_button), image);
        gtk_button_set_alignment(GTK_BUTTON(lock_screen_button), 0.0, 0.5);
        g_signal_connect(G_OBJECT(lock_screen_button), "clicked", G_CALLBACK(lock_screen_clicked), &handler_context);
        gtk_box_pack_start(GTK_BOX(controls), lock_screen_button, FALSE, FALSE, 4);
    }

    /* Create the Logout button. */
    GtkWidget * logout_button = gtk_button_new_with_mnemonic(_("_Logout"));
    GtkWidget * image = gtk_image_new_from_icon_name("system-log-out", GTK_ICON_SIZE_BUTTON);
    gtk_button_set_image(GTK_BUTTON(logout_button), image);
    gtk_button_set_alignment(GTK_BUTTON(logout_button), 0.0, 0.5);
    g_signal_connect(G_OBJECT(logout_button), "clicked", G_CALLBACK(logout_clicked), &handler_context);
    gtk_box_pack_start(GTK_BOX(controls), logout_button, FALSE, FALSE, 4);

    /* Create the Cancel button. */
    GtkWidget * cancel_button = gtk_button_new_from_stock(GTK_STOCK_CANCEL);
    gtk_button_set_alignment(GTK_BUTTON(cancel_button), 0.0, 0.5);
    g_signal_connect(G_OBJECT(cancel_button), "clicked", G_CALLBACK(cancel_clicked), NULL);
    GtkAccelGroup* accel_group = gtk_accel_group_new();
    gtk_window_add_accel_group(GTK_WINDOW(window), accel_group);
#if GTK_CHECK_VERSION(3,0,0)
    gtk_widget_add_accelerator(cancel_button, "activate", accel_group,
        GDK_KEY_Escape, (GdkModifierType)0, GTK_ACCEL_VISIBLE);
#else
    gtk_widget_add_accelerator(cancel_button, "activate", accel_group,
        GDK_Escape, (GdkModifierType)NULL, GTK_ACCEL_VISIBLE);
#endif
    gtk_box_pack_start(GTK_BOX(controls), cancel_button, FALSE, FALSE, 4);

    /* Create the error text. */
    handler_context.error_label = gtk_label_new("");
    gtk_label_set_justify(GTK_LABEL(handler_context.error_label), GTK_JUSTIFY_CENTER);
    gtk_box_pack_start(GTK_BOX(controls), handler_context.error_label, FALSE, FALSE, 4);

    /* Show everything. */
    gtk_widget_show_all(window);

    /* Run the main event loop. */
    gtk_main();

    /* Return. */
    return 0;
}
