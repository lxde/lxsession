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

    LxSignals global_sig;

    public class Main: GLib.Object{

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

        /* Options and Apps that need to be killed (build-in) */
        var clipboard = new ClipboardOption(config);
        var securitypolkit = new PolkitApp(config.polkit);

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
        if (config.window_manager != null)
        {
            var windowmanager = new WindowManagerApp(config.window_manager, "simple", "", "");
            windowmanager.launch();
        }
        else
        {
            var windowmanager = new WindowManagerApp(   config.window_manager_program, 
                                                        "advanced",
                                                        config.window_manager_session,
                                                        config.window_manager_extras);
            windowmanager.launch();
        }

        /* Disable autostart if it's specified in the conf file. */
        if (config.disable_autostart == "all")
        {
            autostart = true;
        }

        /* Autostart if not disable by command line */
        if (autostart == false)
        {
            /* Launch other specific applications */
            if (config.panel_program != null)
            {
                var panelprogram = new PanelApp(config.panel_program, config.panel_session);
                panelprogram.launch();
            }

            if (config.screensaver_program != null)
            {
                var screensaverprogram = new ScreensaverApp(config.screensaver_program);
                screensaverprogram.launch();
            }

            if (config.power_manager_program != null)
            {
                if (config.laptop_mode == "unknown")
                {
                    /* test if you are on laptop, but don't wait the update on Settings object to launch the program */
                    bool state = detect_laptop();
                    string state_text = "no";
                    if (state == true)
                    {
                        state_text = "yes";
                    }
                    global_sig.update_laptop_mode(state_text);
                    var powermanagerprogram = new PowermanagerApp(config.power_manager_program, state_text);
                    powermanagerprogram.launch();
                }
                else
                {
                    var powermanagerprogram = new PowermanagerApp(config.power_manager_program, config.laptop_mode);
                    powermanagerprogram.launch();
                }
            }

            if (config.network_gui != null)
            {
                if (config.laptop_mode == "unknown")
                {
                    /* test if you are on laptop, but don't wait the update on Settings object to launch the program */
                    bool state = detect_laptop();
                    string state_text = "no";
                    if (state == true)
                    {
                        state_text = "yes";
                    }
                    global_sig.update_laptop_mode(state_text);
                    var networkguiprogram = new NetworkGuiApp(config.power_manager_program, state_text);
                    networkguiprogram.launch();
                }
                else
                {
                    var networkguiprogram = new NetworkGuiApp(config.power_manager_program, config.laptop_mode);
                    networkguiprogram.launch();
                }
            }

            if (config.file_manager_program != null)
            {
                var filemanagerprogram = new FilemanagerApp(config.file_manager_program,
                                                            config.file_manager_session,
                                                            "");
                filemanagerprogram.launch();
            }

            if (config.composite_manager_autostart == "true")
            {
                if (config.composite_manager_command != null)
                {
                    var compositemanagerprogram = new CompositeManagerApp(config.composite_manager_command);
                    compositemanagerprogram.launch();
                }
            }

            if (config.polkit != null)
            {
                securitypolkit.launch();
            }
            /* Autostart application define by the user */
            var auto = new LxsessionAutostartConfig();
            auto.start_applications();

            /* Autostart application define xdg directories */
            if (config.disable_autostart == "config-only")
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
        if (config.clipboard_command != null)
        {
            clipboard.activate();
        }

        message ("Check keymap_mode %s", config.keymap_mode);
        if (config.keymap_mode != null)
        {
            message("Create Option Keymap");
            var keymap = new KeymapOption(config);
            keymap.activate();
        }

        if (config.xrandr_mode != null)
        {
            var xrandr = new XrandrOption(config);
            xrandr.activate();
        }

        if (config.security_keyring != null)
        {
            var keyring = new KeyringOption(config);
            keyring.activate();
        }

        if (config.a11y_type == "true")
        {
            var a11y = new A11yOption(config);
            a11y.activate();
        }

        if (config.updates_activate == "true")
        {
            var updates = new UpdatesOption(config);
            updates.activate();
        }

        /* DBus Serveurs */
        if (config.dbus_lxde == "true")
        {
            Bus.own_name (BusType.SESSION, "org.lxde.SessionManager", BusNameOwnerFlags.NONE,
                          on_bus_aquired,
                          () => {},
                          () => warning ("Could not aquire name\n"));
        }

        if (config.dbus_gnome == "true") 
        {

            Bus.own_name (BusType.SESSION, "org.gnome.SessionManager", BusNameOwnerFlags.NONE,
                          on_gnome_bus_aquired,
                          () => {},
                          () => warning ("Could not aquire name\n"));

        }

        /* start main loop */
        new MainLoop().run();

        if (config.clipboard_command != null)
        {
            clipboard.deactivate();
        }

        if (config.polkit != null)
        {
            securitypolkit.deactivate();
        }

        return 0;
    }
}

}
