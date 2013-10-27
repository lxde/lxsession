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

        /* Show all */
        window.show_all ();

        /* Autostart list */
        manual_autostart_init(builder);

        var dbus_backend = new DbusBackend();

        /* Default value */
        string[] panel_commands = { "", "lxpanel", "awn"};
        string[] panel_sessions = { "", "Lubuntu", "LXDE"};
        init_combobox_gui(builder, dbus_backend, "panel", "command", panel_commands);
        init_combobox_gui(builder, dbus_backend, "panel", "session", panel_sessions);
        init_launch_button(builder, dbus_backend, "panel", "");

        string[] dock_commands = { "", "lxpanel", "awn"};
        string[] dock_sessions = { "", "Lubuntu", "LXDE"};
        init_combobox_gui(builder, dbus_backend, "dock", "command", dock_commands);
        init_combobox_gui(builder, dbus_backend, "dock", "session", dock_sessions);
        init_launch_button(builder, dbus_backend, "dock", "");

        string[] window_commands = { "", "openbox", "openbox-custom"};
        string[] window_sessions = { "", "Lubuntu", "LXDE"};
        string[] window_extras = { "" };
        init_combobox_gui(builder, dbus_backend, "windows_manager", "command", window_commands);
        init_combobox_gui(builder, dbus_backend, "windows_manager", "session", window_sessions);
        init_combobox_gui(builder, dbus_backend, "windows_manager", "extras", window_extras);
        init_launch_button(builder, dbus_backend, "dock", "");

        string[] screensaver_commands = { "", "xscreensaver"};
        init_combobox_gui(builder, dbus_backend, "screensaver_manager", "command", screensaver_commands);
        init_launch_button(builder, dbus_backend, "screensaver_manager", "");

        string[] power_commands = { "", "auto", "no"};
        init_combobox_gui(builder, dbus_backend, "power_manager", "command", power_commands);
        init_launch_button(builder, dbus_backend, "power_manager", "");

        string[] file_commands = { "", "pcmanfm", "pcmanfm-qt", "nautilus"};
        string[] file_sessions = { "", "lubuntu", "LXDE"};
        string[] file_extras = { ""};
        init_combobox_gui(builder, dbus_backend, "file_manager", "command", file_commands);
        init_combobox_gui(builder, dbus_backend, "file_manager", "session", file_sessions);
        init_combobox_gui(builder, dbus_backend, "file_manager", "extras", file_extras);
        init_launch_button(builder, dbus_backend, "file_manager", "");

        string[] desktop_commands = { "", "filemanager", "feh"};
        string[] desktop_wallpapers = {""};
        init_combobox_gui(builder, dbus_backend, "desktop_manager", "command", desktop_commands);
        init_combobox_gui(builder, dbus_backend, "desktop_manager", "wallpaper", desktop_wallpapers);
        init_launch_button(builder, dbus_backend, "desktop_manager", "");

        string[] composite_commands = {""};
        string[] composite_autostart = {"", "true", "false"};
        init_combobox_gui(builder, dbus_backend, "composite_manager", "command", composite_commands);
        init_combobox_gui(builder, dbus_backend, "composite_manager", "autostart", composite_autostart);
        init_launch_button(builder, dbus_backend, "composite_manager", "");

        string[] im1_commands = {"", "pidgin"};
        string[] im1_autostart = {"", "true", "false"};
        init_combobox_gui(builder, dbus_backend, "im1", "command", im1_commands);
        init_combobox_gui(builder, dbus_backend, "im1", "autostart", im1_autostart);
        init_launch_button(builder, dbus_backend, "im1", "");

        string[] im2_commands = {"", "pidgin"};
        string[] im2_autostart = {"", "true", "false"};
        init_combobox_gui(builder, dbus_backend, "im2", "command", im2_commands);
        init_combobox_gui(builder, dbus_backend, "im2", "autostart", im2_autostart);
        init_launch_button(builder, dbus_backend, "im2", "");

        string[] widget1_commands = {""};
        string[] widget1_autostart = {"", "true", "false"};
        init_combobox_gui(builder, dbus_backend, "widget1", "command", widget1_commands);
        init_combobox_gui(builder, dbus_backend, "widget1", "autostart", widget1_autostart);
        init_launch_button(builder, dbus_backend, "widget1", "");

        string[] polkit_commands = { "", "gnome", "razorqt", "lxpolkit"};
        init_combobox_gui(builder, dbus_backend, "polkit", "command", polkit_commands);
        init_launch_button(builder, dbus_backend, "polkit", "");

        string[] network_commands = { "", "auto", "no", "nm-applet", "wicd"};
        init_combobox_gui(builder, dbus_backend, "network_gui", "command", network_commands);
        init_launch_button(builder, dbus_backend, "network_gui", "");

        string[] audio_commands = { "", "alsamixer"};
        init_combobox_gui(builder, dbus_backend, "audio_manager", "command", audio_commands);
        init_launch_button(builder, dbus_backend, "audio_manager", "");

        string[] quit_commands = { "", "lxsession-logout"};
        string[] quit_image = { "" };
        string[] quit_layout = { ""};
        init_combobox_gui(builder, dbus_backend, "quit_manager", "command", quit_commands);
        init_combobox_gui(builder, dbus_backend, "quit_manager", "image", quit_image);
        init_combobox_gui(builder, dbus_backend, "quit_manager", "layout", quit_layout);
        init_launch_button(builder, dbus_backend, "quit_manager", "");

        string[] workspace_commands = { "", "obconf"};
        init_combobox_gui(builder, dbus_backend, "workspace_manager", "command", workspace_commands);
        init_launch_button(builder, dbus_backend, "workspace_manager", "");

        string[] launcher_commands = { "", "lxpanelctl", "synapse" };
        init_combobox_gui(builder, dbus_backend, "launcher_manager", "command", launcher_commands);
        init_launch_button(builder, dbus_backend, "launcher_manager", "");

        string[] terminal_commands = { "", "lxterminal", "xterm" };
        init_combobox_gui(builder, dbus_backend, "terminal_manager", "command", terminal_commands);
        init_launch_button(builder, dbus_backend, "terminal_manager", "");

        string[] screenshot_commands = { "", "scrot"};
        init_combobox_gui(builder, dbus_backend, "screenshot_manager", "command", screenshot_commands);
        init_launch_button(builder, dbus_backend, "screenshot_manager", "");

        string[] lock_commands = { "", "lxlock"};
        init_combobox_gui(builder, dbus_backend, "lock_manager", "command", lock_commands);
        init_launch_button(builder, dbus_backend, "lock_manager", "");

        string[] upgrade_commands = { "", "update-manager"};
        init_combobox_gui(builder, dbus_backend, "upgrade_manager", "command", upgrade_commands);
        init_launch_button(builder, dbus_backend, "upgrade_manager", "");

        string[] clipboard_commands = { "", "lxclipboard"};
        init_combobox_gui(builder, dbus_backend, "clipboard", "command", clipboard_commands);
        init_launch_button(builder, dbus_backend, "clipboard", "");


        /* TODO Adapat to be generic ? A bit too complex for now */
        var disable_autostart_combobox = new Gtk.ComboBox();
        string[] disable_autostart_commands = { "no", "config-only", "all"};
        string disable_autostart_default = dbus_backend.SessionGet("disable_autostart", "");
        disable_autostart_combobox = ui_combobox_init(  builder,
                                                        "disable_autostart_combobox",
                                                        disable_autostart_commands,
                                                        null,
                                                        disable_autostart_default);


        disable_autostart_combobox.changed.connect (() => {
            dbus_backend.SessionSet("disable_autostart", "", return_combobox_text(disable_autostart_combobox));
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


        /* TODO Make this generic */
        /* Note using glade + Vala for checkbutton doesnt work, so we have to create it in the code */
        var launcher_autostart_checkbutton = new Gtk.CheckButton.with_label ("Autostart");
        var launcher_vbox = builder.get_object ("launcher_vbox") as Gtk.VBox;
        launcher_vbox.add(launcher_autostart_checkbutton);

        if (dbus_backend.SessionGet("launcher_manager", "autostart") == "true")
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
                dbus_backend.SessionSet("launcher_manager", "autostart", "true");
            }
            else
            {
                 dbus_backend.SessionSet("launcher_manager", "autostart", "false");
            }
        });

        var upstart_session_checkbutton = new Gtk.CheckButton.with_label ("Upstart Session");
        var upstart_session_hbox = builder.get_object ("upstart_session_hbox") as Gtk.HBox;
        upstart_session_hbox.add(upstart_session_checkbutton);

        if (dbus_backend.SessionGet("upstart_user_session", "") == "true")
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
                dbus_backend.SessionSet("upstart_user_session", "", "true");
            }
            else
            {
                dbus_backend.SessionSet("upstart_user_session", "", "false");
            }
        });

        /* Keymap init */
        var keymap_mode_combobox = new Gtk.ComboBox();
        string[] keymap_mode_commands = { "", "user"};
        string keymap_mode_default = dbus_backend.KeymapGet("mode", null);
        keymap_mode_combobox = ui_combobox_init(    builder,
                                                    "keymap_mode_combobox",
                                                    keymap_mode_commands,
                                                    null,
                                                    keymap_mode_default);

        var keymap_model_entry = builder.get_object("keymap_model_entry") as Gtk.Entry;
        keymap_model_entry.set_text(dbus_backend.KeymapGet("model", null));

        var keymap_layout_entry = builder.get_object("keymap_layout_entry") as Gtk.Entry;
        keymap_layout_entry.set_text(dbus_backend.KeymapGet("layout", null));

        var keymap_variant_entry = builder.get_object("keymap_variant_entry") as Gtk.Entry;
        keymap_variant_entry.set_text(dbus_backend.KeymapGet("variant", null));

        var keymap_options_entry = builder.get_object("keymap_options_entry") as Gtk.Entry;
        keymap_options_entry.set_text(dbus_backend.KeymapGet("options", null));

        var keymap_apply_button = builder.get_object("keymap_apply") as Gtk.Button;
        keymap_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.KeymapSet("mode", null, return_combobox_text(keymap_mode_combobox));
            dbus_backend.KeymapSet("model", null, keymap_model_entry.get_text());
            dbus_backend.KeymapSet("layout", null, keymap_layout_entry.get_text());
            dbus_backend.KeymapSet("variant", null, keymap_variant_entry.get_text());
            dbus_backend.KeymapSet("options", null, keymap_options_entry.get_text());
        });

        var keymap_reload_button = builder.get_object("keymap_reload") as Gtk.Button;
        keymap_reload_button.clicked.connect (() => {
            dbus_backend.KeymapActivate();
        });

        /* Xrandr */
        var xrandr_mode_combobox = new Gtk.ComboBox();
        string[] xrandr_mode_commands = { "", "command"};
        string xrandr_mode_default = dbus_backend.XrandrGet("mode", null);
        xrandr_mode_combobox = ui_combobox_init(    builder,
                                                    "xrandr_mode_combobox",
                                                    xrandr_mode_commands,
                                                    null,
                                                    xrandr_mode_default);

        var xrandr_command_entry = builder.get_object("xrandr_command_entry") as Gtk.Entry;
        xrandr_command_entry.set_text(dbus_backend.XrandrGet("command", null));

        var xrandr_apply_button = builder.get_object("xrandr_apply") as Gtk.Button;
        xrandr_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.XrandrSet("mode", null, return_combobox_text(xrandr_mode_combobox));
            dbus_backend.XrandrSet("command", null, xrandr_command_entry.get_text());
        });

        var xrandr_reload_button = builder.get_object("xrandr_reload") as Gtk.Button;
        xrandr_reload_button.clicked.connect (() => {
            dbus_backend.XrandrActivate();
        });

        /* Security */
        var security_keyring_combobox = new Gtk.ComboBox();
        string[] security_keyring_commands = { "", "gnome", "ssh-agent"};
        string security_keyring_default = dbus_backend.SecurityGet("keyring", null);
        security_keyring_combobox = ui_combobox_init(   builder,
                                                        "security_keyring_combobox",
                                                        security_keyring_commands,
                                                        null,
                                                        security_keyring_default);

        var security_apply_button = builder.get_object("security_apply") as Gtk.Button;
        security_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.SecuritySet("keyring", null, return_combobox_text(security_keyring_combobox));
        });

        var security_reload_button = builder.get_object("security_reload") as Gtk.Button;
        security_reload_button.clicked.connect (() => {
            dbus_backend.SecurityActivate();
        });

        /* a11y */
        var a11y_type_combobox = new Gtk.ComboBox();
        string[] a11y_type_commands = { "", "gnome"};
        string a11y_type_default = dbus_backend.A11yGet("type", null);
        a11y_type_combobox = ui_combobox_init(   builder,
                                                    "a11y_type_combobox",
                                                    a11y_type_commands,
                                                    null,
                                                    a11y_type_default);

        var a11y_apply_button = builder.get_object("a11y_apply") as Gtk.Button;
        a11y_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.A11ySet("type", null, return_combobox_text(a11y_type_combobox));
        });

        var a11y_reload_button = builder.get_object("a11y_reload") as Gtk.Button;
        a11y_reload_button.clicked.connect (() => {
            dbus_backend.A11yActivate();
        });

        /* Updates */
        var updates_type_combobox = new Gtk.ComboBox();
        string[] updates_type_commands = { "", "build-in", "update-notifier"};
        string updates_type_default = dbus_backend.UpdatesGet("type", null);
        updates_type_combobox = ui_combobox_init(   builder,
                                                    "updates_type_combobox",
                                                    updates_type_commands,
                                                    null,
                                                    updates_type_default);

        var updates_apply_button = builder.get_object("updates_apply") as Gtk.Button;
        updates_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.UpdatesSet("type", null, return_combobox_text(updates_type_combobox));
        });

        var updates_reload_button = builder.get_object("updates_reload") as Gtk.Button;
        updates_reload_button.clicked.connect (() => {
            dbus_backend.UpdatesActivate();
        });

        /* Laptop mode */
        var laptop_mode_combobox = new Gtk.ComboBox();
        string[] laptop_mode_commands = { "no", "yes", "unknown"};
        string laptop_mode_default = dbus_backend.StateGet("laptop_mode", null);
        laptop_mode_combobox = ui_combobox_init(  builder,
                                                  "laptop_mode_combobox",
                                                  laptop_mode_commands,
                                                  null,
                                                  laptop_mode_default);

        laptop_mode_combobox.changed.connect (() => {
            dbus_backend.StateSet("laptop_mode", null, return_combobox_text(laptop_mode_combobox));
        });

        /* Dbus */
        var dbus_gnome_checkbutton = new Gtk.CheckButton.with_label ("Gnome");
        var dbus_vbox = builder.get_object ("dbus_vbox") as Gtk.VBox;

        dbus_vbox.add(dbus_gnome_checkbutton);

        if (dbus_backend.DbusGet("gnome", null) == "true")
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
                dbus_backend.DbusSet("gnome", null, "true");
            }
            else
            {
                dbus_backend.DbusSet("gnome", null, "false");
            }
        });

        /* Environment */
        var environment_type_combobox = new Gtk.ComboBox();
        string[] environment_type_commands = { "", "lubuntu"};
        string environment_type_default = dbus_backend.EnvironmentGet("type", null);
        environment_type_combobox = ui_combobox_init(   builder,
                                                        "environment_type_combobox",
                                                        environment_type_commands,
                                                        null,
                                                        environment_type_default);

        environment_type_combobox.changed.connect (() => {
            dbus_backend.EnvironmentSet("type", null, return_combobox_text(environment_type_combobox));
        });

        var enviroment_menu_prefix_entry = builder.get_object("environment_menu_prefix_entry") as Gtk.Entry;
        enviroment_menu_prefix_entry.set_text(dbus_backend.EnvironmentGet("menu_prefix", null));

        var env_apply_button = builder.get_object("env_apply") as Gtk.Button;
        env_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.EnvironmentSet("menu_prefix", null, enviroment_menu_prefix_entry.get_text());
        });

        /* Proxy */
        var proxy_http_entry = builder.get_object("proxy_http_entry") as Gtk.Entry;
        proxy_http_entry.set_text(dbus_backend.ProxyGet("http", null));

        var proxy_apply_button = builder.get_object("proxy_apply") as Gtk.Button;
        proxy_apply_button.clicked.connect (() => {
            message ("Click !");
            dbus_backend.ProxySet("http", null, proxy_http_entry.get_text());
        });

        var proxy_reload_button = builder.get_object("proxy_reload") as Gtk.Button;
        proxy_reload_button.clicked.connect (() => {
            dbus_backend.ProxyActivate();
        });

        /* start main loop */
        Gtk.main ();


        return 0;
    }
}
