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

        /* start main loop */
        Gtk.main ();
        new MainLoop().run();


        return 0;
    }
}
