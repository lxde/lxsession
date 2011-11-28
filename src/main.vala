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

namespace Lxsession {

    public class Main: Object{

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
        }

        session_global = session;


        var environment = new LxsessionEnv(session, desktop_environnement);

        /* 
           Check is lxsession is alone (TODO do it with something like GApplication ?)
        if (environment.check_alone() == false)
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
        string log_directory = Path.build_filename(Environment.get_user_cache_dir(), "lxsession");
        var file = File.new_for_path (log_directory);

        string log_path = Path.build_filename(log_directory, session,".log");

        message ("log directory: %s",log_directory);
        message ("log path: %s",log_path);

        if (!file.query_exists ())
        {
            file.make_directory_with_parents();
        }

        int fint;
        fint = open (log_path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
        dup2 (fint, STDOUT_FILENO);
        dup2 (fint, STDERR_FILENO);
        close(fint);


        /* Configuration */
        var config = new LxsessionConfigKeyFile(session, desktop_environnement);


        /* Create the Xsettings manager */
        if (noxsettings == false) {
            settings_daemon_start(load_keyfile (get_config_path ("desktop.conf")));
        }

        /* Launching windows manager */
        var windowmanager = new WindowManagerApp(config.window_manager);
        windowmanager.launch();


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
            var powermanagerprogram = new PowermanagerApp(config.power_manager_program);
            powermanagerprogram.launch();
        }

        if (config.file_manager_program != null)
        {
            var filemanagerprogram = new FilemanagerApp(config.file_manager_program, 
                                                        config.file_manager_session,
                                                        "");
            filemanagerprogram.launch();
        }

        if (config.polkit != null)
        {
            var securitypolkit = new PolkitApp(config.polkit);
            securitypolkit.launch();
        }


        /* Autostart if not disable by command line */
        if (autostart == false)
        {
            /* Autostart application define by the user */
            var auto = new LxsessionAutostartConfig();
            auto.start_applications();

            /* Autostart applications in system-wide directories */
            xdg_autostart(desktop_environnement);
        }

        /* Options */
        if (config.keymap_mode != null)
        {
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

        return 0;
    }
}

}
