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
    WindowManagerApp global_window_manager;
    FilemanagerApp global_filemanager_program;
    PolkitApp global_security_polkit;
    ScreensaverApp global_screensaver_program;
    PowermanagerApp global_powermanager_program;
    NetworkGuiApp global_networkgui_program;
    CompositeManagerApp global_compositemanager_program;
    AudioManagerApp global_audio_manager;
    QuitManagerApp global_quit_manager;
    WorkspaceManagerApp global_workspace_manager;
    LauncherManagerApp global_launcher_manager;
    TerminalManagerApp global_terminal_manager;
    ScreenshotManagerApp global_screenshot_manager;
    UpgradesManagerApp global_upgrades_manager;

    public class Main: GLib.Object
    {
        static string session = "LXDE";
        static string desktop_environnement = "LXDE";
        static bool reload = false;
        static bool noxsettings = false;
        static bool autostart = false;

        const OptionEntry[] option_entries = {
        { "session", 's', 0, OptionArg.STRING, ref session, "specify name of the desktop session profile", "NAME" },
        { "de", 'e', 0, OptionArg.STRING, ref desktop_environnement, "specify name of DE, such as LXDE, GNOME, or XFCE.", "NAME" },
        { "reload", 'r', 0, OptionArg.NONE, ref reload, "reload configurations (for Xsettings daemon)", null },
        { "noxsettings", 'n', 0, OptionArg.NONE, ref noxsettings, "disable Xsettings daemon support", null },
        { "noautostart", 'a', 0, OptionArg.NONE, ref autostart, "autostart applications disable (window-manager mode only)", null },
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
        var config = new LxsessionConfigKeyFile(session, desktop_environnement, global_sig);
        global_settings = config;

        /* Sync desktop.conf and autostart setting files */
        global_settings.sync_setting_files ();

        /* Options and Apps that need to be killed (build-in) */
        var clipboard = new ClipboardOption(global_settings);

        /* Conf Files */
        string conffiles_conf = get_config_path ("conffiles.conf");
        if (FileUtils.test (conffiles_conf, FileTest.EXISTS))
        {
            /* Use the conffiles utility
            var conffiles = new ConffilesObject(conffiles_conf);
            */
        }

        /* Create the Xsettings manager */
        if (noxsettings == false) {
            settings_daemon_start(load_keyfile (get_config_path ("desktop.conf")));
        }

        /* Launching windows manager */
        if (global_settings.window_manager != null)
        {
            var windowmanager = new WindowManagerApp();
            global_window_manager = windowmanager;
            global_window_manager.launch();
        }
        else if (global_settings.window_manager_program != null)
        {
            var windowmanager = new WindowManagerApp();
            global_window_manager = windowmanager;
            global_window_manager.launch();
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
            if (global_settings.panel_program != null)
            {
                var panelprogram = new PanelApp();
                global_panel = panelprogram;
                global_panel.launch();
            }

            if (global_settings.screensaver_program != null)
            {
                var screensaverprogram = new ScreensaverApp();
                global_screensaver_program = screensaverprogram;
                global_screensaver_program.launch();
            }

            if (global_settings.power_manager_program != null)
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
                    global_sig.update_laptop_mode(state_text);
                    var powermanagerprogram = new PowermanagerApp();
                    global_powermanager_program = powermanagerprogram;
                    global_powermanager_program.launch();
                }
                else
                {
                    var powermanagerprogram = new PowermanagerApp();
                    global_powermanager_program = powermanagerprogram;
                    global_powermanager_program.launch();
                }
            }

            if (global_settings.network_gui != null)
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
                    global_sig.update_laptop_mode(state_text);
                    var networkguiprogram = new NetworkGuiApp();
                    global_networkgui_program = networkguiprogram;
                    global_networkgui_program.launch();
                }
                else
                {
                    var networkguiprogram = new NetworkGuiApp();
                    global_networkgui_program = networkguiprogram;
                    global_networkgui_program.launch();
                }
            }

            if (global_settings.file_manager_program != null)
            {
                var filemanagerprogram = new FilemanagerApp();
                    global_filemanager_program = filemanagerprogram;
                    global_filemanager_program.launch();
            }

            if (global_settings.composite_manager_autostart == "true")
            {
                if (global_settings.composite_manager_command != null)
                {
                    var compositemanagerprogram = new CompositeManagerApp();
                    global_compositemanager_program = compositemanagerprogram;
                    global_compositemanager_program.launch();
                }
            }

            if (global_settings.polkit != null)
            {
                var securitypolkit = new PolkitApp();
                global_security_polkit = securitypolkit;
                global_security_polkit.launch();
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

        /* Options */
        if (global_settings.clipboard_command != null)
        {
            clipboard.activate();
        }

        message ("Check keymap_mode %s", global_settings.keymap_mode);
        if (global_settings.keymap_mode != null)
        {
            message("Create Option Keymap");
            var keymap = new KeymapOption(global_settings);
            keymap.activate();
        }

        if (global_settings.xrandr_mode != null)
        {
            var xrandr = new XrandrOption(global_settings);
            xrandr.activate();
        }

        if (global_settings.security_keyring != null)
        {
            var keyring = new KeyringOption(global_settings);
            keyring.activate();
        }

        if (global_settings.a11y_type == "true")
        {
            var a11y = new A11yOption(global_settings);
            a11y.activate();
        }

        if (global_settings.updates_activate == "true")
        {
            var updates = new UpdatesOption(global_settings);
            updates.activate();
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

        if (global_settings.clipboard_command != null)
        {
            clipboard.deactivate();
        }

        if (global_settings.polkit != null)
        {
            global_security_polkit.deactivate();
            global_security_polkit.stop();
        }

        if (global_panel != null)
        {
            global_panel.stop();
        }

        if (global_window_manager != null)
        {
            global_window_manager.stop();
        }

        if (global_filemanager_program != null)
        {
            global_filemanager_program.stop();
        }

        if (global_security_polkit != null)
        {
            global_security_polkit.stop();
        }

        if (global_screensaver_program != null)
        {
            global_screensaver_program.stop();
        }

        if (global_powermanager_program != null)
        {
            global_powermanager_program.stop();
        }

        if (global_networkgui_program != null)
        {
            global_networkgui_program.stop();
        }

        if (global_compositemanager_program != null)
        {
            global_compositemanager_program.stop();
        }

        return 0;
    }
}

}
