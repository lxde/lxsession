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

#if BUILDIN_POLKIT
using Gtk;
#endif

#if BUILDIN_CLIPBOARD
using Gtk;
#endif

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
    CompositeManagerApp global_composite_manager;
    AudioManagerApp global_audio_manager;
    QuitManagerApp global_quit_manager;
    WorkspaceManagerApp global_workspace_manager;
    LauncherManagerApp global_launcher_manager;
    TerminalManagerApp global_terminal_manager;
    ScreenshotManagerApp global_screenshot_manager;
    LockManagerApp global_lock_manager;
    UpgradeManagerApp global_upgrade_manager;
    GenericSimpleApp global_message_manager;
    ClipboardOption global_clipboard;
    KeymapOption global_keymap;
    XrandrOption global_xrandr;
    KeyringOption global_keyring;
    A11yOption global_a11y;
    UpdatesOption global_updates;
    IM1App global_im1;
    IM2App global_im2;
    WidgetApp global_widget1;
    ProxyOption global_proxy;
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

#if BUILDIN_POLKIT
        Gtk.init (ref args);
#endif
#if BUILDIN_CLIPBOARD
        Gtk.init (ref args);
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

        /* Create the Xsettings manager */
        if (noxsettings == false)
        {
            if (global_xsettings_manager == null)
            {
                var xsettings = new XSettingsOption(global_settings.xsettings_manager_command);
                global_xsettings_manager = xsettings;
            }
            global_xsettings_manager.activate();
        }

        var environment = new LxsessionEnv(session, desktop_environnement);

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

        /* Launching windows manager */
        if (global_settings.window_manager != null)
        {
            var windowsmanager = new WindowsManagerApp();
            global_windows_manager = windowsmanager;
            global_windows_manager.launch();
        }
        else if (global_settings.windows_manager_command != null)
        {
            var windowsmanager = new WindowsManagerApp();
            global_windows_manager = windowsmanager;
            global_windows_manager.launch();
        }

        /* Disable autostart if it's specified in the conf file. */
        if (global_settings.disable_autostart == "all")
        {
            autostart = true;
        }

        /* Autostart if not disable by command line */
        if (autostart == false)
        {
            /* Launch other specific applications */
            if (global_settings.panel_command != null)
            {
                var panel = new PanelApp();
                global_panel = panel;
                global_panel.launch();
            }

            if (global_settings.dock_command != null)
            {
                var dock = new DockApp();
                global_dock = dock;
                global_dock.launch();
            }

            if (global_settings.screensaver_command != null)
            {
                var screensaver = new ScreensaverApp();
                global_screensaver = screensaver;
                global_screensaver.launch();
            }

            if (global_settings.power_manager_command != null)
            {
                if (global_settings.laptop_mode == "unknown")
                {
                    /*  Test if you are on laptop, but don't wait the update on Settings object to launch
                        the program */

                    bool state = detect_laptop();
                    string state_text = "no";
                    if (state == true)
                    {
                        state_text = "yes";
                    }
                    global_sig.request_laptop_mode_set(state_text);
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

            if (global_settings.network_gui_command != null)
            {
                if (global_settings.laptop_mode == "unknown")
                {
                    /* test if you are on laptop, but don't wait the update on Settings object to launch the program */
                    bool state = detect_laptop();
                    string state_text = "no";
                    if (state == true)
                    {
                        state_text = "yes";
                    }
                    global_sig.request_laptop_mode_set(state_text);
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

            if (global_settings.desktop_command != null)
            {
                var desktopmanager = new DesktopApp();
                    global_desktop = desktopmanager;
                    global_desktop.launch();
            }

            if (global_settings.composite_manager_autostart == "true")
            {
                if (global_settings.composite_manager_command != null)
                {
                    var compositemanager = new CompositeManagerApp();
                    global_composite_manager = compositemanager;
                    global_composite_manager.launch();
                }
            }

            if (global_settings.polkit_command != null)
            {
                var securitypolkit = new PolkitApp();
                global_polkit = securitypolkit;
#if BUILDIN_POLKIT
                /* Do nothing, it's already initialize when creating the app */
#else
                global_polkit.launch();
#endif
            }



            if (global_settings.launcher_manager_autostart == "true")
            {
                if (global_settings.launcher_manager_command != null)
                {
                    var launcher = new LauncherManagerApp();
                    global_launcher_manager = launcher;
                    global_launcher_manager.autostart_launch();
                }
            }

            if (global_settings.im1_autostart == "true")
            {
                if (global_settings.im1_command != null)
                {
                    var im1 = new IM1App();
                    global_im1 = im1;
                    global_im1.launch();
                }
            }

            if (global_settings.im2_autostart == "true")
            {
                if (global_settings.im2_command != null)
                {
                    var im2 = new IM2App();
                    global_im2 = im2;
                    global_im2.launch();
                }
            }

            if (global_settings.widget1_autostart == "true")
            {
                if (global_settings.widget1_command != null)
                {
                    var widget1 = new WidgetApp();
                    global_widget1 = widget1;
                    global_widget1.launch();
                }
            }

            /* Autostart application define by the user */
            var auto = new LxsessionAutostartConfig();
            auto.start_applications();

            /* Autostart application define xdg directories */
            if (global_settings.disable_autostart == "config-only")
            {
                /* Pass, we don't want autostarted applications */
            }
            else
            {
                /* Autostart applications in system-wide directories */
                xdg_autostart(desktop_environnement);
            }
        }

        /* Options and Apps that need to be killed (build-in) */
        if (global_settings.clipboard_command != null)
        {
            var clipboard = new ClipboardOption(global_settings);
            global_clipboard = clipboard;
            global_clipboard.activate();
        }

        message ("Check keymap_mode %s", global_settings.keymap_mode);
        if (global_settings.keymap_mode != null)
        {
            message("Create Option Keymap");
            var keymap = new KeymapOption(global_settings);
            global_keymap = keymap;
            global_keymap.activate();
        }

        if (global_settings.xrandr_mode != null)
        {
            var xrandr = new XrandrOption(global_settings);
            global_xrandr = xrandr;
            xrandr.activate();
        }

        if (global_settings.security_keyring != null)
        {
            var keyring = new KeyringOption(global_settings);
            global_keyring = keyring;
            global_keyring.activate();
        }

        if (global_settings.a11y_type == "true")
        {
            var a11y = new A11yOption(global_settings);
            global_a11y = a11y;
            global_a11y.activate();
        }

        if (global_settings.proxy_http != null)
        {
            var proxy = new ProxyOption(global_settings);
            global_proxy = proxy;
            global_proxy.activate();
        }

        if (global_settings.updates_type != null)
        {
            var updates = new UpdatesOption(global_settings);
            global_updates = updates;
            global_updates.activate();
        }

        if (global_settings.upstart_user_session == "true")
        {
            var upstart_session = new UpstartUserSessionOption(global_settings);
            global_upstart_session = upstart_session;
            global_upstart_session.activate();
        }

        /* DBus Serveurs */
        if (global_settings.dbus_lxde == "true")
        {
            Bus.own_name (BusType.SESSION, "org.lxde.SessionManager", BusNameOwnerFlags.NONE,
                          on_bus_aquired,
                          () => {},
                          () => warning ("Could not aquire name\n"));
        }

        if (global_settings.dbus_gnome == "true") 
        {

            Bus.own_name (BusType.SESSION, "org.gnome.SessionManager", BusNameOwnerFlags.NONE,
                          on_gnome_bus_aquired,
                          () => {},
                          () => warning ("Could not aquire name\n"));

        }

        /* start main loop */
        new MainLoop().run();

        if (global_clipboard != null)
        {
            global_clipboard.desactivate();
        }

        if (global_settings.polkit_command != null)
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
