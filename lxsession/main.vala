/* 
 *      Copyright 2011 Julien Lavergne <gilir@ubuntu.com>
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
using Posix;
using Intl;

#if USE_GTK
using Gtk;
#endif

const string GETTEXT_PACKAGE = "lxsession";

namespace Lxsession {

    /* Global objects */
    LxSignals global_sig;
    LxsessionConfigKeyFile global_settings;

    PanelApp global_panel;
    DockApp global_dock;
    WindowsManagerApp global_windows_manager;
    FileManagerApp global_file_manager;
    DesktopApp global_desktop;
    PolkitApp global_polkit;
    ScreensaverApp global_screensaver;
    PowerManagerApp global_power_manager;
    NetworkGuiApp global_network_gui;
    GenericSimpleApp global_composite_manager;
    AudioManagerApp global_audio_manager;
    QuitManagerApp global_quit_manager;
    WorkspaceManagerApp global_workspace_manager;
    LauncherManagerApp global_launcher_manager;
    TerminalManagerApp global_terminal_manager;
    ScreenshotManagerApp global_screenshot_manager;
    GenericSimpleApp global_message_manager;
    ClipboardOption global_clipboard;
    KeymapOption global_keymap;
    GenericSimpleApp global_im_manager;
    XrandrApp global_xrandr;
    KeyringApp global_keyring;
    A11yApp global_a11y;
    UpdatesManagerApp global_updates;
    CrashManagerApp global_crash;
    GenericSimpleApp global_im1;
    GenericSimpleApp global_im2;
    GenericSimpleApp global_widget1;
    GenericSimpleApp global_notification;
    GenericSimpleApp global_keybindings;
    ProxyManagerApp global_proxy;
    UpstartUserSessionOption global_upstart_session;
    XSettingsOption global_xsettings_manager;

    public class Main: GLib.Object
    {
        static string session = "LXDE";
        static string desktop_environnement = "LXDE";
        static bool reload = false;
        static bool noxsettings = false;
        static bool autostart = false;
        static string compatibility = "";

        const OptionEntry[] option_entries = {
        { "session", 's', 0, OptionArg.STRING, ref session, "specify name of the desktop session profile", "NAME" },
        { "de", 'e', 0, OptionArg.STRING, ref desktop_environnement, "specify name of DE, such as LXDE, GNOME, or XFCE.", "NAME" },
        { "reload", 'r', 0, OptionArg.NONE, ref reload, "reload configurations (for Xsettings daemon)", null },
        { "noxsettings", 'n', 0, OptionArg.NONE, ref noxsettings, "disable Xsettings daemon support", null },
        { "noautostart", 'a', 0, OptionArg.NONE, ref autostart, "autostart applications disable (window-manager mode only)", null },
        { "compatibility", 'c', 0, OptionArg.STRING, ref compatibility, "specify a compatibility mode for settings (only razor-qt supported)", "NAME" },
        { null }
        };

    public static int main(string[] args) {

        Intl.textdomain(GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");

        try {
            var options_args = new OptionContext("- Lightweight Session manager");
            options_args.set_help_enabled(true);
            options_args.add_main_entries(option_entries, null);
            options_args.parse(ref args);
        } catch (OptionError e) {
            critical ("Option parsing failed: %s\n", e.message);
            return -1;
        }

        message ("Session is %s",session);
        message ("DE is %s", desktop_environnement);

        if (session == null)
        {
            message ("No session set, fallback to LXDE session");
            session = "LXDE";
        }

        if (desktop_environnement == null)
        {
            message ("No desktop environnement set, fallback to LXDE");
            desktop_environnement = "LXDE";
        }

        session_global = session;

#if USE_GTK
        Gtk.init (ref args);
#if USE_ADVANCED_NOTIFICATIONS
        Notify.init ("LXsession");
#endif
#endif

        /* 
           Log on .log file
        */
        string log_directory = Path.build_filename(Environment.get_user_cache_dir(), "lxsession", session);
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
            catch (GLib.Error err)
            {
		        message (err.message);
            }
        }

        int fint;
        fint = open (log_path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
        dup2 (fint, STDOUT_FILENO);
        dup2 (fint, STDERR_FILENO);
        close(fint);

        /* Init signals */
        var sig = new LxSignals();
        global_sig = sig;

        var environment = new LxsessionEnv(session, desktop_environnement);
        /* First export env variable which doesn't need the settings. useful to set xdg directories */
        environment.export_primary_env();

        /* Configuration */
        if (compatibility == "razor-qt")
        {
            var config = new RazorQtConfigKeyFile(session, desktop_environnement);
            global_settings = config;
        }
        else
        {
            var config = new LxsessionConfigKeyFile(session, desktop_environnement);
            global_settings = config;
        }

        /* Sync desktop.conf and autostart setting files */
        global_settings.sync_setting_files ();

        /* 
           Check is lxsession is alone
        */
/*
        if (environment.check_alone() == false)
        {
            critical ("Lxsession is already running, exit.");
            return -1;
        }
*/
/* TODO implement with Dbus
        if (Bus.exist (BusType.SESSION, "org.lxde.SessionManager" == true)
        {
            critical ("Lxsession is already running, exit.");
            return -1;
        }
*/
        /* 
           Export environnement variable
        */
         environment.export_env();

        /* Conf Files */
        string conffiles_conf = get_config_path ("conffiles.conf");
        if (FileUtils.test (conffiles_conf, FileTest.EXISTS))
        {
            /* Use the conffiles utility */
            var conffiles = new ConffilesObject(conffiles_conf);
            conffiles.apply();
        }

        /* Create the Xsettings manager */
        if (noxsettings == false)
        {
            if (global_xsettings_manager == null)
            {
                var xsettings = new XSettingsOption();
                global_xsettings_manager = xsettings;
                global_xsettings_manager.activate();
            }
            else
            {
                global_xsettings_manager.reload();
            }
        }

        /* Launching windows manager */
        if (global_settings.get_item_string("Session", "window_manager", null) != null)
        {
            // message("DEBUG1 : %s", global_settings.get_item_string("Session", "window_manager", null));
            var windowsmanager = new WindowsManagerApp();
            global_windows_manager = windowsmanager;
            global_windows_manager.launch();
        }
        else if (global_settings.get_item_string("Session", "windows_manager", "command") != null)
        {
            // message("DEBUG2 : %s", global_settings.get_item_string("Session", "windows_manager", "command"));
            var windowsmanager = new WindowsManagerApp();
            global_windows_manager = windowsmanager;
            global_windows_manager.launch();
        }

        /* Disable autostart if it's specified in the conf file. */
        if (global_settings.get_item_string("Session", "disable_autostart", null) == "all")
        {
            autostart = true;
        }

        /* Autostart if not disable by command line */
        if (autostart == false)
        {
            /* Launch other specific applications */
            if (global_settings.get_item_string("Session", "panel", "command") != null)
            {
                var panel = new PanelApp();
                global_panel = panel;
                global_panel.launch();
            }

            if (global_settings.get_item_string("Session", "dock", "command") != null)
            {
                var dock = new DockApp();
                global_dock = dock;
                global_dock.launch();
            }

            if (global_settings.get_item_string("Session", "screensaver", "command") != null)
            {
                var screensaver = new ScreensaverApp();
                global_screensaver = screensaver;
                global_screensaver.launch();
            }

            if (global_settings.get_item_string("Session", "power_manager", "command") != null)
            {
                if (global_settings.get_item_string("State", "laptop_mode", null) == "unknown")
                {
                    /*  Test if you are on laptop, but don't wait the update on Settings object to launch
                        the program */

                    bool state = detect_laptop();
                    string state_text = "no";
                    if (state == true)
                    {
                        state_text = "yes";
                    }
                    global_sig.generic_set_signal("State", "laptop_mode", null, "string", state_text);
                    var powermanager = new PowerManagerApp();
                    global_power_manager = powermanager;
                    global_power_manager.launch();
                }
                else
                {
                    var powermanager = new PowerManagerApp();
                    global_power_manager = powermanager;
                    global_power_manager.launch();
                }
            }

            if (global_settings.get_item_string("Session", "network_gui", "command") != null)
            {
                if (global_settings.get_item_string("State", "laptop_mode", null) == "unknown")
                {
                    /* test if you are on laptop, but don't wait the update on Settings object to launch the program */
                    bool state = detect_laptop();
                    string state_text = "no";
                    if (state == true)
                    {
                        state_text = "yes";
                    }
                    global_sig.generic_set_signal("State", "laptop_mode", null, "string", state_text);
                    var networkgui = new NetworkGuiApp();
                    global_network_gui = networkgui;
                    global_network_gui.launch();
                }
                else
                {
                    var networkgui = new NetworkGuiApp();
                    global_network_gui = networkgui;
                    global_network_gui.launch();
                }
            }

            if (global_settings.get_item_string("Session", "desktop_manager", "command") != null)
            {
                // message("DEBUG4 : %s", global_settings.get_item_string("Session", "desktop_manager", "command"));
                var desktopmanager = new DesktopApp();
                    global_desktop = desktopmanager;
                    global_desktop.launch();
            }

            if (global_settings.get_item_string("Session", "composite_manager", "autostart") == "true")
            {
                if (global_settings.get_item_string("Session", "composite_manager", "command") != null)
                {
                    var compositemanager = new GenericSimpleApp(global_settings.get_item_string("Session", "composite_manager", "command"));
                    global_composite_manager = compositemanager;
                    global_composite_manager.launch();
                }
            }

            if (global_settings.get_item_string("Session", "polkit", "command") != null)
            {
                var securitypolkit = new PolkitApp();
                global_polkit = securitypolkit;
                global_polkit.launch();
            }



            if (global_settings.get_item_string("Session", "launcher_manager", "autostart") == "true")
            {
                if (global_settings.get_item_string("Session", "launcher_manager", "command") != null)
                {
                    var launcher = new LauncherManagerApp();
                    global_launcher_manager = launcher;
                    global_launcher_manager.autostart_launch();
                }
            }

            if (global_settings.get_item_string("Session", "im1", "autostart") == "true")
            {
                if (global_settings.get_item_string("Session", "im1", "command") != null)
                {
                    var im1 = new GenericSimpleApp(global_settings.get_item_string("Session", "im1", "command"));
                    global_im1 = im1;
                    global_im1.launch();
                }
            }

            if (global_settings.get_item_string("Session", "im2", "autostart") == "true")
            {
                if (global_settings.get_item_string("Session", "im2", "command") != null)
                {
                    var im2 = new GenericSimpleApp(global_settings.get_item_string("Session", "im2", "command"));
                    global_im2 = im2;
                    global_im2.launch();
                }
            }

            if (global_settings.get_item_string("Session", "widget1", "autostart") == "true")
            {
                if (global_settings.get_item_string("Session", "widget1", "command") != null)
                {
                    var widget1 = new GenericSimpleApp(global_settings.get_item_string("Session", "widget1", "command"));
                    global_widget1 = widget1;
                    global_widget1.launch();
                }
            }

            if (global_settings.get_item_string("Session", "notification", "autostart") == "true")
            {
                if (global_settings.get_item_string("Session", "notification", "command") != null)
                {
                    var notification = new GenericSimpleApp(global_settings.get_item_string("Session", "notification", "command"));
                    global_notification = notification;
                    global_notification.launch();
                }
            }

            if (global_settings.get_item_string("Session", "keybindings", "autostart") == "true")
            {
                if (global_settings.get_item_string("Session", "keybindings", "command") != null)
                {
                    var keybindings = new GenericSimpleApp(global_settings.get_item_string("Session", "keybindings", "command"));
                    global_keybindings = keybindings;
                    global_keybindings.launch();
                }
            }

            if (global_settings.get_item_string("Session", "im_manager", "autostart") == "true")
            {
                if (global_settings.get_item_string("Session", "im_manager", "command") != null)
                {
                    var im_manager = new GenericSimpleApp(global_settings.get_item_string("Session", "im_manager", "command"));
                    global_im_manager = im_manager;
                    global_im_manager.launch();
                }
            }

            /* Autostart application define by the user */
            var auto = new LxsessionAutostartConfig();
            auto.start_applications();

            /* Autostart application define xdg directories */
            if (global_settings.get_item_string("Session", "disable_autostart", null) == "config-only")
            {
                /* Pass, we don't want autostarted applications */
            }
            else
            {
                /* Autostart applications in system-wide directories */
                string autostart_cmd = "lxsession-xdg-autostart -d " + desktop_environnement;
                lxsession_spawn_command_line_async(autostart_cmd);
            }
        }

        /* Options and Apps that need to be killed (build-in) */
        if (global_settings.get_item_string("Session", "clipboard", "command") != null)
        {
            var clipboard = new ClipboardOption(global_settings);
            global_clipboard = clipboard;
            global_clipboard.activate();
        }

        message ("Check keymap_mode %s", global_settings.get_item_string("Keymap", "mode", null));
        if (global_settings.get_item_string("Keymap", "mode", null) != null)
        {
            message("Create Option Keymap");
            var keymap = new KeymapOption(global_settings);
            global_keymap = keymap;
            global_keymap.activate();
        }

        if (global_settings.get_item_string("Session", "xrandr", "command") != null)
        {
            var xrandr = new XrandrApp();
            global_xrandr = xrandr;
            xrandr.launch();
        }

        if (global_settings.get_item_string("Session", "keyring", "command") != null)
        {
            var keyring = new KeyringApp();
            global_keyring = keyring;
            global_keyring.launch();
        }

        if (global_settings.get_item_string("Session", "a11y", "command") != null)
        {
            var a11y = new A11yApp();
            global_a11y = a11y;
            global_a11y.launch();
        }

        if (global_settings.get_item_string("Session", "proxy_manager", "command") != null)
        {
            var proxy = new ProxyManagerApp();
            global_proxy = proxy;
            global_proxy.launch();
        }

        if (global_settings.get_item_string("Session", "updates_manager", "command") != null)
        {
            var updates = new UpdatesManagerApp();
            global_updates = updates;
            //global_updates.launch();
        }

        if (global_settings.get_item_string("Session", "crash_manager", "command") != null)
        {
            var crash = new CrashManagerApp();
            global_crash = crash;
            //global_crash.launch();
        }

        if (global_settings.get_item_string("Session", "upstart_user_session", null) == "true")
        {
            var upstart_session = new UpstartUserSessionOption(global_settings);
            global_upstart_session = upstart_session;
            global_upstart_session.activate();
        }

        /* DBus Serveurs */
        if (global_settings.get_item_string("Dbus", "lxde", null) == "true")
        {
            Bus.own_name (BusType.SESSION, "org.lxde.SessionManager", BusNameOwnerFlags.NONE,
                          on_bus_aquired,
                          () => {},
                          () => warning ("Could not acquire name\n"));
        }

        if (global_settings.get_item_string("Dbus", "gnome", null) == "true") 
        {

            Bus.own_name (BusType.SESSION, "org.gnome.SessionManager", BusNameOwnerFlags.NONE,
                          on_gnome_bus_aquired,
                          () => {},
                          () => warning ("Could not acquire name\n"));

        }

        /* start main loop */
        new MainLoop().run();

        if (global_clipboard != null)
        {
            global_clipboard.desactivate();
        }

        if (global_settings.get_item_string("Session", "polkit", "command") != null)
        {
            global_polkit.deactivate();
            global_polkit.stop();
        }

        if (global_panel != null)
        {
            global_panel.stop();
        }

        if (global_dock != null)
        {
            global_dock.stop();
        }

        if (global_windows_manager != null)
        {
            global_windows_manager.stop();
        }

        if (global_desktop != null)
        {
            global_desktop.stop();
        }

        if (global_polkit != null)
        {
            global_polkit.stop();
        }

        if (global_screensaver != null)
        {
            global_screensaver.stop();
        }

        if (global_power_manager != null)
        {
            global_power_manager.stop();
        }

        if (global_network_gui != null)
        {
            global_network_gui.stop();
        }

        if (global_composite_manager != null)
        {
            global_composite_manager.stop();
        }

        return 0;
    }
}

}
