/* 
    Copyright 2012 Julien Lavergne <gilir@ubuntu.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using Posix;

namespace LDefaultApps
{

    public static int main(string[] args)
    {
        /* Init GTK */
        Gtk.init (ref args);

        /* Load the .ui file */
        var builder = new Builder ();

        try
        {
            // If the UI contains custom widgets, their types must've been instantiated once
            // Type type = typeof(Foo.BarEntry);
            // assert(type != 0);

            var builder_file_path = Path.build_filename("data","ui","lxsession-default-apps.ui");
            var builder_file = File.new_for_path(builder_file_path);

            if (builder_file.query_exists())
            {
                builder.add_from_file (builder_file_path);
            }
            else
            {
                /* TODO Make it smart with prefix */
                builder_file_path = Path.build_filename("/usr","share","lxsession","ui","lxsession-default-apps.ui");
                builder.add_from_file (builder_file_path);
            }
        } 
        catch (GLib.Error e)
        {
            critical ("Could not load UI: %s\n", e.message);
            return 1;
        } 

        /* Log on .log file */
        string log_directory = Path.build_filename(Environment.get_user_cache_dir(), "lxsession-default-apps");
        var dir_log = File.new_for_path (log_directory);

        string log_path = Path.build_filename(log_directory, "run.log");

        message ("log directory: %s",log_directory);
        message ("log path: %s",log_path);

        if (!dir_log.query_exists ())
        {
            try
            {
                dir_log.make_directory_with_parents();
            }
            catch (GLib.Error e)
            {
                GLib.stderr.printf ("Could not write log: %s\n", e.message);
            }
        }

        int fint;
        fint = open (log_path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
        dup2 (fint, STDOUT_FILENO);
        dup2 (fint, STDERR_FILENO);
        close(fint);

        /* Build the UI */
        builder.connect_signals (null);
        var window = builder.get_object ("main-win") as Window;
        window.destroy.connect (Gtk.main_quit);

        try
        {
            window.icon = IconTheme.get_default ().load_icon ("xfwm4", 48, 0);
        }
        catch (Error e)
        {
            message ("Could not load application icon: %s\n", e.message);
        }

        /* Autostart list */
        manual_autostart_init(builder);

        var dbus_backend = new DbusBackend();

        /* Panel init */
        var panel_command_combobox = new Gtk.ComboBox();
        var panel_command_entry = builder.get_object ("panel_command_entry") as Entry;
        string[] panel_commands = { "", "lxpanel", "awn"};
        string panel_command_default = dbus_backend.PanelCommandGet();
        panel_command_combobox = ui_combobox_init(  builder,
                                                    "panel_command_combobox",
                                                    panel_commands,
                                                    "panel_command_entry",
                                                    panel_command_default);


        var panel_session_combobox = new Gtk.ComboBox();
        var panel_session_entry = builder.get_object ("panel_session_entry") as Entry;
        string[] panel_sessions = { "", "Lubuntu", "LXDE"};
        string panel_session_default = dbus_backend.PanelSessionGet();
        panel_session_combobox = ui_combobox_init(  builder,
                                                    "panel_session_combobox",
                                                    panel_sessions,
                                                    "panel_session_entry",
                                                    panel_session_default);

        var panel_apply_button = builder.get_object("panel_apply") as Gtk.Button;
        panel_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(panel_command_combobox) == 99)
            {
                dbus_backend.PanelCommandSet(panel_command_entry.get_text());
            }
            else
            {
                dbus_backend.PanelCommandSet(return_combobox_text(panel_command_combobox));
            }


            if (return_combobox_position(panel_session_combobox) == 99)
            {
                dbus_backend.PanelSessionSet(panel_session_entry.get_text());
            }
            else
            {
                dbus_backend.PanelSessionSet(return_combobox_text(panel_session_combobox));
            }

        });


        var panel_reload_button = builder.get_object("panel_reload") as Gtk.Button;
        panel_reload_button.clicked.connect (() => {
            dbus_backend.PanelReload();
        });

        /* Dock init */
        var dock_command_combobox = new Gtk.ComboBox();
        var dock_command_entry = builder.get_object ("dock_command_entry") as Entry;
        string[] dock_commands = { "", "lxpanel", "awn"};
        string dock_command_default = dbus_backend.DockCommandGet();
        dock_command_combobox = ui_combobox_init(  builder,
                                                    "dock_command_combobox",
                                                    dock_commands,
                                                    "dock_command_entry",
                                                    dock_command_default);


        var dock_session_combobox = new Gtk.ComboBox();
        var dock_session_entry = builder.get_object ("dock_session_entry") as Entry;
        string[] dock_sessions = { "", "Lubuntu", "LXDE"};
        string dock_session_default = dbus_backend.DockSessionGet();
        dock_session_combobox = ui_combobox_init(  builder,
                                                    "dock_session_combobox",
                                                    dock_sessions,
                                                    "dock_session_entry",
                                                    dock_session_default);

        var dock_apply_button = builder.get_object("dock_apply") as Gtk.Button;
        dock_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(dock_command_combobox) == 99)
            {
                dbus_backend.DockCommandSet(dock_command_entry.get_text());
            }
            else
            {
                dbus_backend.DockCommandSet(return_combobox_text(dock_command_combobox));
            }


            if (return_combobox_position(dock_session_combobox) == 99)
            {
                dbus_backend.DockSessionSet(dock_session_entry.get_text());
            }
            else
            {
                dbus_backend.DockSessionSet(return_combobox_text(dock_session_combobox));
            }

        });

        var dock_reload_button = builder.get_object("dock_reload") as Gtk.Button;
        dock_reload_button.clicked.connect (() => {
            dbus_backend.DockReload();
        });

        /* Window manager init */
        var window_command_combobox = new Gtk.ComboBox();
        var window_command_entry = builder.get_object ("window_command_entry") as Entry;
        string[] window_commands = { "", "openbox", "openbox-custom"};
        string window_command_default = dbus_backend.WindowsManagerCommandGet();
        window_command_combobox = ui_combobox_init(  builder,
                                                    "window_command_combobox",
                                                    window_commands,
                                                    "window_command_entry",
                                                    window_command_default);


        var window_session_combobox = new Gtk.ComboBox();
        var window_session_entry = builder.get_object ("window_session_entry") as Entry;
        string[] window_sessions = { "", "Lubuntu", "LXDE"};
        string window_session_default = dbus_backend.WindowsManagerSessionGet();
        window_session_combobox = ui_combobox_init(  builder,
                                                    "window_session_combobox",
                                                    window_sessions,
                                                    "window_session_entry",
                                                    window_session_default);

        var window_extras_combobox = new Gtk.ComboBox();
        var window_extras_entry = builder.get_object ("window_extras_entry") as Entry;
        string[] window_extras = { ""};
        string window_extras_default = dbus_backend.WindowsManagerExtrasGet();
        window_extras_combobox = ui_combobox_init(  builder,
                                                    "window_extras_combobox",
                                                    window_extras,
                                                    "window_extras_entry",
                                                    window_extras_default);

        var window_apply_button = builder.get_object("window_apply") as Gtk.Button;
        window_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(window_command_combobox) == 99)
            {
                dbus_backend.WindowsManagerCommandSet(window_command_entry.get_text());
            }
            else
            {
                dbus_backend.WindowsManagerCommandSet(return_combobox_text(window_command_combobox));
            }


            if (return_combobox_position(window_session_combobox) == 99)
            {
                dbus_backend.WindowsManagerSessionSet(window_session_entry.get_text());
            }
            else
            {
                dbus_backend.WindowsManagerSessionSet(return_combobox_text(window_session_combobox));
            }

            if (return_combobox_position(window_extras_combobox) == 99)
            {
                dbus_backend.WindowsManagerExtrasSet(window_extras_entry.get_text());
            }
            else
            {
                dbus_backend.WindowsManagerExtrasSet(return_combobox_text(window_extras_combobox));
            }

        });

        var window_reload_button = builder.get_object("window_reload") as Gtk.Button;
        window_reload_button.clicked.connect (() => {
            dbus_backend.WindowsManagerReload();
        });

        /* Screensaver init */
        var screensaver_command_combobox = new Gtk.ComboBox();
        var screensaver_command_entry = builder.get_object ("screensaver_command_entry") as Entry;
        string[] screensaver_commands = { "", "xscreensaver"};
        string screensaver_command_default = dbus_backend.ScreensaverCommandGet();
        screensaver_command_combobox = ui_combobox_init(  builder,
                                                    "screensaver_command_combobox",
                                                    screensaver_commands,
                                                    "screensaver_command_entry",
                                                    screensaver_command_default);

        var screensaver_apply_button = builder.get_object("screensaver_apply") as Gtk.Button;
        screensaver_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(screensaver_command_combobox) == 99)
            {
                dbus_backend.ScreensaverCommandSet(screensaver_command_entry.get_text());
            }
            else
            {
                dbus_backend.ScreensaverCommandSet(return_combobox_text(screensaver_command_combobox));
            }

        });


        var screensaver_reload_button = builder.get_object("screensaver_reload") as Gtk.Button;
        screensaver_reload_button.clicked.connect (() => {
            dbus_backend.ScreensaverReload();
        });

        /* Power Manager init */
        var power_command_combobox = new Gtk.ComboBox();
        var power_command_entry = builder.get_object ("power_command_entry") as Entry;
        string[] power_commands = { "", "auto", "no"};
        string power_command_default = dbus_backend.PowerManagerCommandGet();
        power_command_combobox = ui_combobox_init(  builder,
                                                    "power_command_combobox",
                                                    power_commands,
                                                    "power_command_entry",
                                                    power_command_default);

        var power_apply_button = builder.get_object("power_apply") as Gtk.Button;
        power_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(power_command_combobox) == 99)
            {
                dbus_backend.PowerManagerCommandSet(power_command_entry.get_text());
            }
            else
            {
                dbus_backend.PowerManagerCommandSet(return_combobox_text(power_command_combobox));
            }

        });


        var power_reload_button = builder.get_object("power_reload") as Gtk.Button;
        power_reload_button.clicked.connect (() => {
            dbus_backend.PowerManagerReload();
        });

        /* File manager init */
        var file_command_combobox = new Gtk.ComboBox();
        var file_command_entry = builder.get_object ("file_command_entry") as Entry;
        string[] file_commands = { "", "pcmanfm", "pcmanfm-qt", "nautilus"};
        string file_command_default = dbus_backend.FileManagerCommandGet();
        file_command_combobox = ui_combobox_init(  builder,
                                                    "file_command_combobox",
                                                    file_commands,
                                                    "file_command_entry",
                                                    file_command_default);


        var file_session_combobox = new Gtk.ComboBox();
        var file_session_entry = builder.get_object ("file_session_entry") as Entry;
        string[] file_sessions = { "", "Lubuntu", "LXDE"};
        string file_session_default = dbus_backend.FileManagerSessionGet();
        file_session_combobox = ui_combobox_init(  builder,
                                                    "file_session_combobox",
                                                    file_sessions,
                                                    "file_session_entry",
                                                    file_session_default);

        var file_extras_combobox = new Gtk.ComboBox();
        var file_extras_entry = builder.get_object ("file_extras_entry") as Entry;
        string[] file_extras = { ""};
        string file_extras_default = dbus_backend.FileManagerExtrasGet();
        file_extras_combobox = ui_combobox_init(  builder,
                                                    "file_extras_combobox",
                                                    file_extras,
                                                    "file_extras_entry",
                                                    file_extras_default);

        var file_apply_button = builder.get_object("file_apply") as Gtk.Button;
        file_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(file_command_combobox) == 99)
            {
                dbus_backend.FileManagerCommandSet(file_command_entry.get_text());
            }
            else
            {
                dbus_backend.FileManagerCommandSet(return_combobox_text(file_command_combobox));
            }


            if (return_combobox_position(file_session_combobox) == 99)
            {
                dbus_backend.FileManagerSessionSet(file_session_entry.get_text());
            }
            else
            {
                dbus_backend.FileManagerSessionSet(return_combobox_text(file_session_combobox));
            }

            if (return_combobox_position(file_extras_combobox) == 99)
            {
                dbus_backend.FileManagerExtrasSet(file_extras_entry.get_text());
            }
            else
            {
                dbus_backend.FileManagerExtrasSet(return_combobox_text(file_extras_combobox));
            }

        });

        var file_reload_button = builder.get_object("file_reload") as Gtk.Button;
        file_reload_button.clicked.connect (() => {
            dbus_backend.FileManagerReload();
        });

        /* Desktop manager init */
        var desktop_command_combobox = new Gtk.ComboBox();
        var desktop_command_entry = builder.get_object ("desktop_command_entry") as Entry;
        string[] desktop_commands = { "", "filemanager", "feh"};
        string desktop_command_default = dbus_backend.DesktopCommandGet();
        desktop_command_combobox = ui_combobox_init(  builder,
                                                    "desktop_command_combobox",
                                                    desktop_commands,
                                                    "desktop_command_entry",
                                                    desktop_command_default);


        var desktop_wallpaper_combobox = new Gtk.ComboBox();
        var desktop_wallpaper_entry = builder.get_object ("desktop_wallpaper_entry") as Entry;
        string[] desktop_wallpapers = {""};
        string desktop_wallpaper_default = dbus_backend.DesktopWallpaperGet();
        desktop_wallpaper_combobox = ui_combobox_init(  builder,
                                                    "desktop_wallpaper_combobox",
                                                    desktop_wallpapers,
                                                    "desktop_wallpaper_entry",
                                                    desktop_wallpaper_default);

        var desktop_apply_button = builder.get_object("desktop_apply") as Gtk.Button;
        desktop_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(desktop_command_combobox) == 99)
            {
                dbus_backend.DesktopCommandSet(desktop_command_entry.get_text());
            }
            else
            {
                dbus_backend.DesktopCommandSet(return_combobox_text(desktop_command_combobox));
            }


            if (return_combobox_position(desktop_wallpaper_combobox) == 99)
            {
                dbus_backend.DesktopWallpaperSet(desktop_wallpaper_entry.get_text());
            }
            else
            {
                dbus_backend.DesktopWallpaperSet(return_combobox_text(desktop_wallpaper_combobox));
            }

        });

        var desktop_reload_button = builder.get_object("desktop_reload") as Gtk.Button;
        desktop_reload_button.clicked.connect (() => {
            dbus_backend.DesktopReload();
        });

        /* Composite manager init */
        var composite_command_combobox = new Gtk.ComboBox();
        var composite_command_entry = builder.get_object ("composite_command_entry") as Entry;
        string[] composite_commands = {""};
        string composite_command_default = dbus_backend.CompositeManagerCommandGet();
        composite_command_combobox = ui_combobox_init(  builder,
                                                    "composite_command_combobox",
                                                    composite_commands,
                                                    "composite_command_entry",
                                                    composite_command_default);


        var composite_autostart_combobox = new Gtk.ComboBox();
        var composite_autostart_entry = builder.get_object ("composite_autostart_entry") as Entry;
        string[] composite_autostart = {"", "true", "false"};
        string composite_autostart_default = dbus_backend.CompositeManagerAutostartGet();
        composite_autostart_combobox = ui_combobox_init(  builder,
                                                    "composite_autostart_combobox",
                                                    composite_autostart,
                                                    "composite_autostart_entry",
                                                    composite_autostart_default);

        var composite_apply_button = builder.get_object("composite_apply") as Gtk.Button;
        composite_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(composite_command_combobox) == 99)
            {
                dbus_backend.CompositeManagerCommandSet(composite_command_entry.get_text());
            }
            else
            {
                dbus_backend.CompositeManagerCommandSet(return_combobox_text(composite_command_combobox));
            }


            if (return_combobox_position(composite_autostart_combobox) == 99)
            {
                dbus_backend.CompositeManagerAutostartSet(composite_autostart_entry.get_text());
            }
            else
            {
                dbus_backend.CompositeManagerAutostartSet(return_combobox_text(composite_autostart_combobox));
            }

        });

        var composite_reload_button = builder.get_object("composite_reload") as Gtk.Button;
        composite_reload_button.clicked.connect (() => {
            dbus_backend.CompositeManagerReload();
        });

        /* IM1 init */
        var im1_command_combobox = new Gtk.ComboBox();
        var im1_command_entry = builder.get_object ("im1_command_entry") as Entry;
        string[] im1_commands = {""};
        string im1_command_default = dbus_backend.IM1CommandGet();
        im1_command_combobox = ui_combobox_init(  builder,
                                                    "im1_command_combobox",
                                                    im1_commands,
                                                    "im1_command_entry",
                                                    im1_command_default);


        var im1_autostart_combobox = new Gtk.ComboBox();
        var im1_autostart_entry = builder.get_object ("im1_autostart_entry") as Entry;
        string[] im1_autostart = {"", "true", "false"};
        string im1_autostart_default = dbus_backend.IM1AutostartGet();
        im1_autostart_combobox = ui_combobox_init(  builder,
                                                    "im1_autostart_combobox",
                                                    im1_autostart,
                                                    "im1_autostart_entry",
                                                    im1_autostart_default);

        var im1_apply_button = builder.get_object("im1_apply") as Gtk.Button;
        im1_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(im1_command_combobox) == 99)
            {
                dbus_backend.IM1CommandSet(im1_command_entry.get_text());
            }
            else
            {
                dbus_backend.IM1CommandSet(return_combobox_text(im1_command_combobox));
            }


            if (return_combobox_position(im1_autostart_combobox) == 99)
            {
                dbus_backend.IM1AutostartSet(im1_autostart_entry.get_text());
            }
            else
            {
                dbus_backend.IM1AutostartSet(return_combobox_text(im1_autostart_combobox));
            }

        });

        var im1_reload_button = builder.get_object("im1_reload") as Gtk.Button;
        im1_reload_button.clicked.connect (() => {
            dbus_backend.IM1Reload();
        });

        /* IM2 init */
        var im2_command_combobox = new Gtk.ComboBox();
        var im2_command_entry = builder.get_object ("im2_command_entry") as Entry;
        string[] im2_commands = {""};
        string im2_command_default = dbus_backend.IM2CommandGet();
        im2_command_combobox = ui_combobox_init(  builder,
                                                    "im2_command_combobox",
                                                    im2_commands,
                                                    "im2_command_entry",
                                                    im2_command_default);


        var im2_autostart_combobox = new Gtk.ComboBox();
        var im2_autostart_entry = builder.get_object ("im2_autostart_entry") as Entry;
        string[] im2_autostart = {"", "true", "false"};
        string im2_autostart_default = dbus_backend.IM2AutostartGet();
        im2_autostart_combobox = ui_combobox_init(  builder,
                                                    "im2_autostart_combobox",
                                                    im2_autostart,
                                                    "im2_autostart_entry",
                                                    im2_autostart_default);

        var im2_apply_button = builder.get_object("im2_apply") as Gtk.Button;
        im2_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(im2_command_combobox) == 99)
            {
                dbus_backend.IM2CommandSet(im2_command_entry.get_text());
            }
            else
            {
                dbus_backend.IM2CommandSet(return_combobox_text(im2_command_combobox));
            }


            if (return_combobox_position(im2_autostart_combobox) == 99)
            {
                dbus_backend.IM2AutostartSet(im2_autostart_entry.get_text());
            }
            else
            {
                dbus_backend.IM2AutostartSet(return_combobox_text(im2_autostart_combobox));
            }

        });

        var im2_reload_button = builder.get_object("im2_reload") as Gtk.Button;
        im2_reload_button.clicked.connect (() => {
            dbus_backend.IM2Reload();
        });

        /* Widget1 manager init */
        var widget1_command_combobox = new Gtk.ComboBox();
        var widget1_command_entry = builder.get_object ("widget1_command_entry") as Entry;
        string[] widget1_commands = {""};
        string widget1_command_default = dbus_backend.Widget1CommandGet();
        widget1_command_combobox = ui_combobox_init(  builder,
                                                    "widget1_command_combobox",
                                                    widget1_commands,
                                                    "widget1_command_entry",
                                                    widget1_command_default);


        var widget1_autostart_combobox = new Gtk.ComboBox();
        var widget1_autostart_entry = builder.get_object ("widget1_autostart_entry") as Entry;
        string[] widget1_autostart = {"", "true", "false"};
        string widget1_autostart_default = dbus_backend.Widget1AutostartGet();
        widget1_autostart_combobox = ui_combobox_init(  builder,
                                                    "widget1_autostart_combobox",
                                                    widget1_autostart,
                                                    "widget1_autostart_entry",
                                                    widget1_autostart_default);

        var widget1_apply_button = builder.get_object("widget1_apply") as Gtk.Button;
        widget1_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(widget1_command_combobox) == 99)
            {
                dbus_backend.Widget1CommandSet(widget1_command_entry.get_text());
            }
            else
            {
                dbus_backend.Widget1CommandSet(return_combobox_text(widget1_command_combobox));
            }


            if (return_combobox_position(widget1_autostart_combobox) == 99)
            {
                dbus_backend.Widget1AutostartSet(widget1_autostart_entry.get_text());
            }
            else
            {
                dbus_backend.Widget1AutostartSet(return_combobox_text(widget1_autostart_combobox));
            }

        });

        var widget1_reload_button = builder.get_object("widget1_reload") as Gtk.Button;
        widget1_reload_button.clicked.connect (() => {
            dbus_backend.Widget1Reload();
        });

        /* Polkit agent init */
        var polkit_command_combobox = new Gtk.ComboBox();
        var polkit_command_entry = builder.get_object ("polkit_command_entry") as Entry;
        string[] polkit_commands = { "", "gnome", "razorqt", "lxpolkit"};
        string polkit_command_default = dbus_backend.PolkitCommandGet();
        polkit_command_combobox = ui_combobox_init(  builder,
                                                    "polkit_command_combobox",
                                                    polkit_commands,
                                                    "polkit_command_entry",
                                                    polkit_command_default);

        var polkit_apply_button = builder.get_object("polkit_apply") as Gtk.Button;
        polkit_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(polkit_command_combobox) == 99)
            {
                dbus_backend.PolkitCommandSet(polkit_command_entry.get_text());
            }
            else
            {
                dbus_backend.PolkitCommandSet(return_combobox_text(polkit_command_combobox));
            }

        });


        var polkit_reload_button = builder.get_object("polkit_reload") as Gtk.Button;
        polkit_reload_button.clicked.connect (() => {
            dbus_backend.PolkitReload();
        });

        /* Network GUI init */
        var network_command_combobox = new Gtk.ComboBox();
        var network_command_entry = builder.get_object ("network_command_entry") as Entry;
        string[] network_commands = { "", "auto", "no", "nm-applet", "wicd"};
        string network_command_default = dbus_backend.NetworkGuiCommandGet();
        network_command_combobox = ui_combobox_init(  builder,
                                                    "network_command_combobox",
                                                    network_commands,
                                                    "network_command_entry",
                                                    network_command_default);

        var network_apply_button = builder.get_object("network_apply") as Gtk.Button;
        network_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(network_command_combobox) == 99)
            {
                dbus_backend.NetworkGuiCommandSet(network_command_entry.get_text());
            }
            else
            {
                dbus_backend.NetworkGuiCommandSet(return_combobox_text(network_command_combobox));
            }

        });


        var network_reload_button = builder.get_object("network_reload") as Gtk.Button;
        network_reload_button.clicked.connect (() => {
            dbus_backend.NetworkGuiReload();
        });

        /* Audio manager init */
        var audio_command_combobox = new Gtk.ComboBox();
        var audio_command_entry = builder.get_object ("audio_command_entry") as Entry;
        string[] audio_commands = { "", "alsamixer"};
        string audio_command_default = dbus_backend.AudioManagerCommandGet();
        audio_command_combobox = ui_combobox_init(  builder,
                                                    "audio_command_combobox",
                                                    audio_commands,
                                                    "audio_command_entry",
                                                    audio_command_default);

        var audio_apply_button = builder.get_object("audio_apply") as Gtk.Button;
        audio_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(audio_command_combobox) == 99)
            {
                dbus_backend.AudioManagerCommandSet(audio_command_entry.get_text());
            }
            else
            {
                dbus_backend.AudioManagerCommandSet(return_combobox_text(audio_command_combobox));
            }

        });


        var audio_reload_button = builder.get_object("audio_reload") as Gtk.Button;
        audio_reload_button.clicked.connect (() => {
            dbus_backend.AudioManagerLaunch();
        });

        /* Quit manager init */
        var quit_command_combobox = new Gtk.ComboBox();
        var quit_command_entry = builder.get_object ("quit_command_entry") as Entry;
        string[] quit_commands = { "", "lxsession-logout"};
        string quit_command_default = dbus_backend.QuitManagerCommandGet();
        quit_command_combobox = ui_combobox_init(  builder,
                                                    "quit_command_combobox",
                                                    quit_commands,
                                                    "quit_command_entry",
                                                    quit_command_default);


        var quit_image_combobox = new Gtk.ComboBox();
        var quit_image_entry = builder.get_object ("quit_image_entry") as Entry;
        string[] quit_image = { "" };
        string quit_image_default = dbus_backend.QuitManagerImageGet();
        quit_image_combobox = ui_combobox_init(  builder,
                                                    "quit_image_combobox",
                                                    quit_image,
                                                    "quit_image_entry",
                                                    quit_image_default);

        var quit_layout_combobox = new Gtk.ComboBox();
        var quit_layout_entry = builder.get_object ("quit_layout_entry") as Entry;
        string[] quit_layout = { ""};
        string quit_layout_default = dbus_backend.QuitManagerLayoutGet();
        quit_layout_combobox = ui_combobox_init(  builder,
                                                    "quit_layout_combobox",
                                                    quit_layout,
                                                    "quit_layout_entry",
                                                    quit_layout_default);

        var quit_apply_button = builder.get_object("quit_apply") as Gtk.Button;
        quit_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(quit_command_combobox) == 99)
            {
                dbus_backend.QuitManagerCommandSet(quit_command_entry.get_text());
            }
            else
            {
                dbus_backend.QuitManagerCommandSet(return_combobox_text(quit_command_combobox));
            }


            if (return_combobox_position(quit_image_combobox) == 99)
            {
                dbus_backend.QuitManagerImageSet(quit_image_entry.get_text());
            }
            else
            {
                dbus_backend.QuitManagerImageSet(return_combobox_text(quit_image_combobox));
            }

            if (return_combobox_position(quit_layout_combobox) == 99)
            {
                dbus_backend.QuitManagerLayoutSet(quit_layout_entry.get_text());
            }
            else
            {
                dbus_backend.QuitManagerLayoutSet(return_combobox_text(quit_layout_combobox));
            }

        });

        var quit_reload_button = builder.get_object("quit_reload") as Gtk.Button;
        quit_reload_button.clicked.connect (() => {
            dbus_backend.QuitManagerLaunch();
        });

        /* Workspace manager init */
        var workspace_command_combobox = new Gtk.ComboBox();
        var workspace_command_entry = builder.get_object ("workspace_command_entry") as Entry;
        string[] workspace_commands = { "", "obconf"};
        string workspace_command_default = dbus_backend.WorkspaceManagerCommandGet();
        workspace_command_combobox = ui_combobox_init(  builder,
                                                    "workspace_command_combobox",
                                                    workspace_commands,
                                                    "workspace_command_entry",
                                                    workspace_command_default);

        var workspace_apply_button = builder.get_object("workspace_apply") as Gtk.Button;
        workspace_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(workspace_command_combobox) == 99)
            {
                dbus_backend.WorkspaceManagerCommandSet(workspace_command_entry.get_text());
            }
            else
            {
                dbus_backend.WorkspaceManagerCommandSet(return_combobox_text(workspace_command_combobox));
            }

        });


        var workspace_reload_button = builder.get_object("workspace_reload") as Gtk.Button;
        workspace_reload_button.clicked.connect (() => {
            dbus_backend.WorkspaceManagerLaunch();
        });

        /* Launcher manager init */
        var launcher_command_combobox = new Gtk.ComboBox();
        var launcher_command_entry = builder.get_object ("launcher_command_entry") as Entry;
        string[] launcher_commands = { "", "lxpanelctl" };
        string launcher_command_default = dbus_backend.LauncherManagerCommandGet();
        launcher_command_combobox = ui_combobox_init(  builder,
                                                    "launcher_command_combobox",
                                                    launcher_commands,
                                                    "launcher_command_entry",
                                                    launcher_command_default);

        var launcher_apply_button = builder.get_object("launcher_apply") as Gtk.Button;
        launcher_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(launcher_command_combobox) == 99)
            {
                dbus_backend.LauncherManagerCommandSet(launcher_command_entry.get_text());
            }
            else
            {
                dbus_backend.LauncherManagerCommandSet(return_combobox_text(launcher_command_combobox));
            }

        });


        var launcher_reload_button = builder.get_object("launcher_reload") as Gtk.Button;
        launcher_reload_button.clicked.connect (() => {
            dbus_backend.LauncherManagerLaunch();
        });

        var launcher_autostart_checkbutton = new Gtk.CheckButton.with_label ("Autostart");
        var launcher_vbox = builder.get_object ("launcher_vbox") as Gtk.VBox;

        launcher_vbox.add(launcher_autostart_checkbutton);

        if (dbus_backend.LauncherManagerAutostartGet() == "true")
        {
            launcher_autostart_checkbutton.set_active(true);
        }
        else
        {
            launcher_autostart_checkbutton.set_active(false);
        }

        launcher_autostart_checkbutton.toggled.connect (() => {
            message ("Click !");
            if (launcher_autostart_checkbutton.get_active())
            {
                dbus_backend.LauncherManagerAutostartSet("true");
            }
            else
            {
                dbus_backend.LauncherManagerAutostartSet("false");
            }
        });

        /* Terminal manager init */
        var terminal_command_combobox = new Gtk.ComboBox();
        var terminal_command_entry = builder.get_object ("terminal_command_entry") as Entry;
        string[] terminal_commands = { "" };
        string terminal_command_default = dbus_backend.TerminalManagerCommandGet();
        terminal_command_combobox = ui_combobox_init(  builder,
                                                    "terminal_command_combobox",
                                                    terminal_commands,
                                                    "terminal_command_entry",
                                                    terminal_command_default);

        var terminal_apply_button = builder.get_object("terminal_apply") as Gtk.Button;
        terminal_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(terminal_command_combobox) == 99)
            {
                dbus_backend.TerminalManagerCommandSet(terminal_command_entry.get_text());
            }
            else
            {
                dbus_backend.TerminalManagerCommandSet(return_combobox_text(terminal_command_combobox));
            }

        });


        var terminal_reload_button = builder.get_object("terminal_reload") as Gtk.Button;
        terminal_reload_button.clicked.connect (() => {
            dbus_backend.TerminalManagerLaunch();
        });

        /* Screenshot manager init */
        var screenshot_command_combobox = new Gtk.ComboBox();
        var screenshot_command_entry = builder.get_object ("screenshot_command_entry") as Entry;
        string[] screenshot_commands = { "", "scrot"};
        string screenshot_command_default = dbus_backend.ScreenshotManagerCommandGet();
        screenshot_command_combobox = ui_combobox_init(  builder,
                                                    "screenshot_command_combobox",
                                                    screenshot_commands,
                                                    "screenshot_command_entry",
                                                    screenshot_command_default);

        var screenshot_apply_button = builder.get_object("screenshot_apply") as Gtk.Button;
        screenshot_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(screenshot_command_combobox) == 99)
            {
                dbus_backend.ScreenshotManagerCommandSet(screenshot_command_entry.get_text());
            }
            else
            {
                dbus_backend.ScreenshotManagerCommandSet(return_combobox_text(screenshot_command_combobox));
            }

        });


        var screenshot_reload_button = builder.get_object("screenshot_reload") as Gtk.Button;
        screenshot_reload_button.clicked.connect (() => {
            dbus_backend.ScreenshotManagerLaunch();
        });

        /* Lock manager init */
        var lock_command_combobox = new Gtk.ComboBox();
        var lock_command_entry = builder.get_object ("lock_command_entry") as Entry;
        string[] lock_commands = { "", "lxlock"};
        string lock_command_default = dbus_backend.LockManagerCommandGet();
        lock_command_combobox = ui_combobox_init(  builder,
                                                    "lock_command_combobox",
                                                    lock_commands,
                                                    "lock_command_entry",
                                                    lock_command_default);

        var lock_apply_button = builder.get_object("lock_apply") as Gtk.Button;
        lock_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(lock_command_combobox) == 99)
            {
                dbus_backend.LockManagerCommandSet(lock_command_entry.get_text());
            }
            else
            {
                dbus_backend.LockManagerCommandSet(return_combobox_text(lock_command_combobox));
            }

        });


        var lock_reload_button = builder.get_object("lock_reload") as Gtk.Button;
        lock_reload_button.clicked.connect (() => {
            dbus_backend.LockManagerLaunch();
        });

        /* Upgrade manager init */
        var upgrade_command_combobox = new Gtk.ComboBox();
        var upgrade_command_entry = builder.get_object ("upgrade_command_entry") as Entry;
        string[] upgrade_commands = { "", "update-manager"};
        string upgrade_command_default = dbus_backend.UpgradeManagerCommandGet();
        upgrade_command_combobox = ui_combobox_init(  builder,
                                                    "upgrade_command_combobox",
                                                    upgrade_commands,
                                                    "upgrade_command_entry",
                                                    upgrade_command_default);

        var upgrade_apply_button = builder.get_object("upgrade_apply") as Gtk.Button;
        upgrade_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(upgrade_command_combobox) == 99)
            {
                dbus_backend.UpgradeManagerCommandSet(upgrade_command_entry.get_text());
            }
            else
            {
                dbus_backend.UpgradeManagerCommandSet(return_combobox_text(upgrade_command_combobox));
            }

        });


        var upgrade_reload_button = builder.get_object("upgrade_reload") as Gtk.Button;
        upgrade_reload_button.clicked.connect (() => {
            dbus_backend.UpgradeManagerLaunch();
        });

        /* Clipboard manager init */
        var clipboard_command_combobox = new Gtk.ComboBox();
        var clipboard_command_entry = builder.get_object ("clipboard_command_entry") as Entry;
        string[] clipboard_commands = { "", "lxclipboard"};
        string clipboard_command_default = dbus_backend.ClipboardCommandGet();
        clipboard_command_combobox = ui_combobox_init(  builder,
                                                    "clipboard_command_combobox",
                                                    clipboard_commands,
                                                    "clipboard_command_entry",
                                                    clipboard_command_default);

        var clipboard_apply_button = builder.get_object("clipboard_apply") as Gtk.Button;
        clipboard_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(clipboard_command_combobox) == 99)
            {
                dbus_backend.ClipboardCommandSet(clipboard_command_entry.get_text());
            }
            else
            {
                dbus_backend.ClipboardCommandSet(return_combobox_text(clipboard_command_combobox));
            }

        });


        var clipboard_reload_button = builder.get_object("clipboard_reload") as Gtk.Button;
        clipboard_reload_button.clicked.connect (() => {
            dbus_backend.ClipboardActivate();
        });

        /* Keymap init */
        var keymap_mode_combobox = new Gtk.ComboBox();
        string[] keymap_mode_commands = { "", "user"};
        string keymap_mode_default = dbus_backend.KeymapModeGet();
        keymap_mode_combobox = ui_combobox_init(    builder,
                                                    "keymap_mode_combobox",
                                                    keymap_mode_commands,
                                                    null,
                                                    keymap_mode_default);

        var keymap_model_entry = builder.get_object("keymap_model_entry") as Gtk.Entry;
        keymap_model_entry.set_text(dbus_backend.KeymapModelGet());

        var keymap_layout_entry = builder.get_object("keymap_layout_entry") as Gtk.Entry;
        keymap_layout_entry.set_text(dbus_backend.KeymapLayoutGet());

        var keymap_variant_entry = builder.get_object("keymap_variant_entry") as Gtk.Entry;
        keymap_variant_entry.set_text(dbus_backend.KeymapVariantGet());

        var keymap_options_entry = builder.get_object("keymap_options_entry") as Gtk.Entry;
        keymap_options_entry.set_text(dbus_backend.KeymapOptionsGet());

        var keymap_apply_button = builder.get_object("keymap_apply") as Gtk.Button;
        keymap_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.KeymapModeSet(return_combobox_text(keymap_mode_combobox));
            dbus_backend.KeymapModelSet(keymap_model_entry.get_text());
            dbus_backend.KeymapLayoutSet(keymap_layout_entry.get_text());
            dbus_backend.KeymapVariantSet(keymap_variant_entry.get_text());
            dbus_backend.KeymapOptionsSet(keymap_options_entry.get_text());
        });

        var keymap_reload_button = builder.get_object("keymap_reload") as Gtk.Button;
        keymap_reload_button.clicked.connect (() => {
            dbus_backend.KeymapActivate();
        });

        /* Xrandr */
        var xrandr_mode_combobox = new Gtk.ComboBox();
        string[] xrandr_mode_commands = { "", "command"};
        string xrandr_mode_default = dbus_backend.XrandrModeGet();
        xrandr_mode_combobox = ui_combobox_init(    builder,
                                                    "xrandr_mode_combobox",
                                                    xrandr_mode_commands,
                                                    null,
                                                    xrandr_mode_default);

        var xrandr_command_entry = builder.get_object("xrandr_command_entry") as Gtk.Entry;
        xrandr_command_entry.set_text(dbus_backend.XrandrCommandGet());

        var xrandr_apply_button = builder.get_object("xrandr_apply") as Gtk.Button;
        xrandr_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.XrandrModeSet(return_combobox_text(xrandr_mode_combobox));
            dbus_backend.XrandrCommandSet(xrandr_command_entry.get_text());
        });

        var xrandr_reload_button = builder.get_object("xrandr_reload") as Gtk.Button;
        xrandr_reload_button.clicked.connect (() => {
            dbus_backend.XrandrActivate();
        });

        /* Security */
        var security_keyring_combobox = new Gtk.ComboBox();
        string[] security_keyring_commands = { "", "gnome", "ssh-agent"};
        string security_keyring_default = dbus_backend.SecurityKeyringGet();
        security_keyring_combobox = ui_combobox_init(   builder,
                                                        "security_keyring_combobox",
                                                        security_keyring_commands,
                                                        null,
                                                        security_keyring_default);

        var security_apply_button = builder.get_object("security_apply") as Gtk.Button;
        security_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.SecurityKeyringSet(return_combobox_text(security_keyring_combobox));
        });

        var security_reload_button = builder.get_object("security_reload") as Gtk.Button;
        security_reload_button.clicked.connect (() => {
            dbus_backend.SecurityActivate();
        });

        /* a11y */
        var a11y_type_combobox = new Gtk.ComboBox();
        string[] a11y_type_commands = { "", "gnome"};
        string a11y_type_default = dbus_backend.A11yTypeGet();
        a11y_type_combobox = ui_combobox_init(   builder,
                                                    "a11y_type_combobox",
                                                    a11y_type_commands,
                                                    null,
                                                    a11y_type_default);

        var a11y_apply_button = builder.get_object("a11y_apply") as Gtk.Button;
        a11y_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.A11yTypeSet(return_combobox_text(a11y_type_combobox));
        });

        var a11y_reload_button = builder.get_object("a11y_reload") as Gtk.Button;
        a11y_reload_button.clicked.connect (() => {
            dbus_backend.A11yActivate();
        });

        /* Updates */
        var updates_type_combobox = new Gtk.ComboBox();
        string[] updates_type_commands = { "", "build-in", "update-notifier"};
        string updates_type_default = dbus_backend.UpdatesTypeGet();
        updates_type_combobox = ui_combobox_init(   builder,
                                                    "updates_type_combobox",
                                                    updates_type_commands,
                                                    null,
                                                    updates_type_default);

        var updates_apply_button = builder.get_object("updates_apply") as Gtk.Button;
        updates_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.UpdatesTypeSet(return_combobox_text(updates_type_combobox));
        });

        var updates_reload_button = builder.get_object("updates_reload") as Gtk.Button;
        updates_reload_button.clicked.connect (() => {
            dbus_backend.UpdatesActivate();
        });

        /* Disable autostart */
        var disable_autostart_combobox = new Gtk.ComboBox();
        string[] disable_autostart_commands = { "no", "config-only", "all"};
        string disable_autostart_default = dbus_backend.DisableAutostartGet();
        disable_autostart_combobox = ui_combobox_init(  builder,
                                                        "disable_autostart_combobox",
                                                        disable_autostart_commands,
                                                        null,
                                                        disable_autostart_default);


        disable_autostart_combobox.changed.connect (() => {
            dbus_backend.DisableAutostartSet(return_combobox_text(disable_autostart_combobox));
            var auto_vbox = builder.get_object("manual_autostart_vbox") as Gtk.VBox;
            var running_apps = builder.get_object("running_apps_vbox") as Gtk.VBox;

            var known_apps_box = builder.get_object("autostart_known_box") as Gtk.HBox;
            var known_apps =  builder.get_object("autostart_treeview") as Gtk.TreeView;

            init_list_view(known_apps);
            load_autostart(Environment.get_variable("XDG_CURRENT_DESKTOP"));
            known_apps.set_model (get_autostart_list ());

            if (return_combobox_text(disable_autostart_combobox) == "all")
            {
                auto_vbox.hide_all();
                running_apps.hide_all();
            }
            else
            {
                running_apps.show_all();
                auto_vbox.show_all();
            }

            if (return_combobox_text(disable_autostart_combobox) == "no")
            {
                known_apps_box.show_all();
            }
            else
            {
                known_apps_box.hide_all();
            }
        });

        /* Laptop mode */
        var laptop_mode_combobox = new Gtk.ComboBox();
        string[] laptop_mode_commands = { "no", "yes", "unknown"};
        string laptop_mode_default = dbus_backend.LaptopModeGet();
        laptop_mode_combobox = ui_combobox_init(  builder,
                                                  "laptop_mode_combobox",
                                                  laptop_mode_commands,
                                                  null,
                                                  laptop_mode_default);

        laptop_mode_combobox.changed.connect (() => {
            dbus_backend.LaptopModeSet(return_combobox_text(laptop_mode_combobox));
        });

        /* Upstart Session */
        /* Note using glade + Vala for checkbutton doesnt work, so we have to create it in the code */
        var upstart_session_checkbutton = new Gtk.CheckButton.with_label ("Upstart Session");
        var upstart_session_hbox = builder.get_object ("upstart_session_hbox") as Gtk.HBox;
        upstart_session_hbox.add(upstart_session_checkbutton);

        if (dbus_backend.UpstartUserSessionGet() == "true")
        {
            upstart_session_checkbutton.set_active(true);
        }
        else
        {
            upstart_session_checkbutton.set_active(false);
        }

        upstart_session_checkbutton.toggled.connect (() => {
            message ("Click !");
            if (upstart_session_checkbutton.get_active())
            {
                dbus_backend.UpstartUserSessionSet("true");
            }
            else
            {
                dbus_backend.UpstartUserSessionSet("false");
            }
        });

        /* Dbus */
        var dbus_gnome_checkbutton = new Gtk.CheckButton.with_label ("Gnome");
        var dbus_vbox = builder.get_object ("dbus_vbox") as Gtk.VBox;

        dbus_vbox.add(dbus_gnome_checkbutton);

        if (dbus_backend.DbusGnomeGet() == "true")
        {
            dbus_gnome_checkbutton.set_active(true);
        }
        else
        {
            dbus_gnome_checkbutton.set_active(false);
        }

        dbus_gnome_checkbutton.toggled.connect (() => {
            message ("Click !");
            if (dbus_gnome_checkbutton.get_active())
            {
                dbus_backend.DbusGnomeSet("true");
            }
            else
            {
                dbus_backend.DbusGnomeSet("false");
            }
        });

        /* Environment */
        var environment_type_combobox = new Gtk.ComboBox();
        string[] environment_type_commands = { "", "lubuntu"};
        string environment_type_default = dbus_backend.EnvTypeGet();
        environment_type_combobox = ui_combobox_init(   builder,
                                                        "environment_type_combobox",
                                                        environment_type_commands,
                                                        null,
                                                        environment_type_default);

        environment_type_combobox.changed.connect (() => {
            dbus_backend.EnvTypeSet(return_combobox_text(environment_type_combobox));
        });

        var enviroment_menu_prefix_entry = builder.get_object("environment_menu_prefix_entry") as Gtk.Entry;
        enviroment_menu_prefix_entry.set_text(dbus_backend.EnvMenuPrefixGet());

        var env_apply_button = builder.get_object("env_apply") as Gtk.Button;
        env_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.EnvMenuPrefixSet(enviroment_menu_prefix_entry.get_text());
        });

        /* Proxy */
        var proxy_http_entry = builder.get_object("proxy_http_entry") as Gtk.Entry;
        proxy_http_entry.set_text(dbus_backend.ProxyHttpGet());

        var proxy_apply_button = builder.get_object("proxy_apply") as Gtk.Button;
        proxy_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.ProxyHttpSet(proxy_http_entry.get_text());
        });

        var proxy_reload_button = builder.get_object("proxy_reload") as Gtk.Button;
        proxy_reload_button.clicked.connect (() => {
            dbus_backend.ProxyActivate();
        });

        /* Show all */
        window.show_all ();

        /* Panel hide */
        if (return_combobox_position(panel_command_combobox) != 99)
        {
            panel_command_entry.hide_all();
        }

        if (return_combobox_position(panel_session_combobox) != 99)
        {
            panel_session_entry.hide_all();
        }

        /* Dock hide */
        if (return_combobox_position(dock_command_combobox) != 99)
        {
            dock_command_entry.hide_all();
        }

        if (return_combobox_position(dock_session_combobox) != 99)
        {
            dock_session_entry.hide_all();
        }

        /* Window manager hide */
        if (return_combobox_position(window_command_combobox) != 99)
        {
            window_command_entry.hide_all();
        }

        if (return_combobox_position(window_session_combobox) != 99)
        {
            window_session_entry.hide_all();
        }

        if (return_combobox_position(window_extras_combobox) != 99)
        {
            window_extras_entry.hide_all();
        }

        /* Screensaver hide */
        if (return_combobox_position(screensaver_command_combobox) != 99)
        {
            screensaver_command_entry.hide_all();
        }

        /* Power Manager hide */
        if (return_combobox_position(power_command_combobox) != 99)
        {
            power_command_entry.hide_all();
        }

        /* File manager hide */
        if (return_combobox_position(file_command_combobox) != 99)
        {
            file_command_entry.hide_all();
        }

        if (return_combobox_position(file_session_combobox) != 99)
        {
            file_session_entry.hide_all();
        }

        if (return_combobox_position(file_extras_combobox) != 99)
        {
            file_extras_entry.hide_all();
        }

        /* Desktop hide */
        if (return_combobox_position(desktop_command_combobox) != 99)
        {
            desktop_command_entry.hide_all();
        }

        if (return_combobox_position(desktop_wallpaper_combobox) != 99)
        {
            desktop_wallpaper_entry.hide_all();
        }

        /* Composite hide */
        if (return_combobox_position(composite_command_combobox) != 99)
        {
            composite_command_entry.hide_all();
        }

        if (return_combobox_position(composite_autostart_combobox) != 99)
        {
            composite_autostart_entry.hide_all();
        }

        /* IM1 hide */
        if (return_combobox_position(im1_command_combobox) != 99)
        {
            im1_command_entry.hide_all();
        }

        if (return_combobox_position(im1_autostart_combobox) != 99)
        {
            im1_autostart_entry.hide_all();
        }

        /* IM2 hide */
        if (return_combobox_position(im2_command_combobox) != 99)
        {
            im2_command_entry.hide_all();
        }

        if (return_combobox_position(im2_autostart_combobox) != 99)
        {
            im2_autostart_entry.hide_all();
        }

        /* Widget1 hide */
        if (return_combobox_position(widget1_command_combobox) != 99)
        {
            widget1_command_entry.hide_all();
        }

        if (return_combobox_position(widget1_autostart_combobox) != 99)
        {
            widget1_autostart_entry.hide_all();
        }

        /* Polkit hide */
        if (return_combobox_position(polkit_command_combobox) != 99)
        {
            polkit_command_entry.hide_all();
        }

        /* Network GUI hide */
        if (return_combobox_position(network_command_combobox) != 99)
        {
            network_command_entry.hide_all();
        }

        /* Audio manager hide */
        if (return_combobox_position(audio_command_combobox) != 99)
        {
            audio_command_entry.hide_all();
        }

        /* Quit manager hide */
        if (return_combobox_position(quit_command_combobox) != 99)
        {
            quit_command_entry.hide_all();
        }

        if (return_combobox_position(quit_image_combobox) != 99)
        {
            quit_image_entry.hide_all();
        }

        if (return_combobox_position(quit_layout_combobox) != 99)
        {
            quit_layout_entry.hide_all();
        }

        /* Workspace manager hide */
        if (return_combobox_position(workspace_command_combobox) != 99)
        {
            workspace_command_entry.hide_all();
        }

        /* Launcher manager hide */
        if (return_combobox_position(launcher_command_combobox) != 99)
        {
            launcher_command_entry.hide_all();
        }

        /* Terminal manager hide */
        if (return_combobox_position(terminal_command_combobox) != 99)
        {
            terminal_command_entry.hide_all();
        }

        /* Screenshot manager hide */
        if (return_combobox_position(screenshot_command_combobox) != 99)
        {
            screenshot_command_entry.hide_all();
        }

        /* Lock manager hide */
        if (return_combobox_position(lock_command_combobox) != 99)
        {
            lock_command_entry.hide_all();
        }

        /* Upgrade manager hide */
        if (return_combobox_position(upgrade_command_combobox) != 99)
        {
            upgrade_command_entry.hide_all();
        }

        /* Clipboard manager hide */
        if (return_combobox_position(clipboard_command_combobox) != 99)
        {
            clipboard_command_entry.hide_all();
        }

        /* start main loop */
        Gtk.main ();


        return 0;
    }
}
