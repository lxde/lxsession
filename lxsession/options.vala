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

/* TODO Replace other utlity in the start script */

namespace Lxsession
{
    public class Option: GLib.Object
    {
        public string command;

        public Option (LxsessionConfig config)
        {

        }

        public void activate()
        {
            switch (command)
            {
                case null:
                    break;
                case "":
                    break;
                case " ":
                    break;
                default:
                    message ("Options - Launch command %s",command);
                    lxsession_spawn_command_line_async(command);
                    break;
            }
        }
    }

    public class KeymapOption: Option
    {
        public KeymapOption (LxsessionConfig config)
        {
            base (config);
            if (config.get_item_string("Keymap", "mode", null) == "user")
            {
                command = create_user_mode_command(config);
            }
        }
        public string create_user_mode_command(LxsessionConfig config)
        {
            var builder = new StringBuilder ();
            builder.append("setxkbmap ");
            if (config.get_item_string("Keymap", "model", null) != null)
            {
                builder.append("-model ");
                builder.append(config.get_item_string("Keymap", "model", null));
                builder.append(" ");
            }
            if (config.get_item_string("Keymap", "layout", null) != null)
            {
                builder.append("-layout ");
                builder.append(config.get_item_string("Keymap", "layout", null));
                builder.append(" ");
            }
            if (config.get_item_string("Keymap", "variant", null) != null)
            {
                builder.append("-variant ");
                message ("Show keymap variant : %s", config.get_item_string("Keymap", "variant", null));
                builder.append(config.get_item_string("Keymap", "variant", null));
                builder.append(" ");
            }
            if (config.get_item_string("Keymap", "options", null) != null)
            {
                builder.append("-options ");
                message ("Show keymap options : %s", config.get_item_string("Keymap", "options", null));
                builder.append(config.get_item_string("Keymap", "options", null));
                builder.append(" ");
            }

            command =  (builder.str);
            message ("Keymap options - return user command %s", command);
            return command;
        }
    }
    public class XrandrOption: Option
    {
        public XrandrOption (LxsessionConfig config)
        {
            base (config);
            if (config.get_item_string("XRandr", "mode", null) == "command")
            {
                command = create_command_mode_command(config);
            }
        }
        public string create_command_mode_command(LxsessionConfig config)
        {
            command = config.get_item_string("XRandr", "command", null);
            return command;
        }
    }
    public class KeyringOption: Option
    {
        private string command1;
        private string command2;
        private string command3;
        private string command4;

        public KeyringOption (LxsessionConfig config)
        {
            base (config);
            switch (config.get_item_string("Security", "keyring", null))
            {
                case "gnome-all":
                    command1 = "gnome-keyring-daemon --start --components=gpg";
                    command2 = "gnome-keyring-daemon --start --components=pkcs11";
                    command3 = "gnome-keyring-daemon --start --components=secrets";
                    command4 = "gnome-keyring-daemon --start --components=ssh";
                    break;
                case "ssh-agent":
                    command1 = "/usr/bin/ssh-agent -s";
                    break;
            }

        }
        public new void activate()
        {
            if (command1 != null)
            {
                lxsession_spawn_command_line_async(command1);
            }

            if (command2 != null)
            {
                lxsession_spawn_command_line_async(command2);
            }

            if (command3 != null)
            {
                lxsession_spawn_command_line_async(command3);
            }

            if (command4 != null)
            {
                lxsession_spawn_command_line_async(command4);
            }
        }
    }
    public class A11yOption: Option
    {
        private string command1;

        public A11yOption (LxsessionConfig config)
        {
            base (config);
            switch (config.get_item_string("a11y", "type", null))
            {
                case "gnome":
                    command1 = "/usr/lib/at-spi2-core/at-spi-bus-launcher --launch-immediately";
                    break;
            }

        }
        public new void activate()
        {
            lxsession_spawn_command_line_async(command1);
        }
    }
    public class ClipboardOption: Option
    {
        public ClipboardOption (LxsessionConfig config)
        {
            base (config);
            switch (config.get_item_string("Session", "clipboard", "command"))
            {
                case "lxclipboard":
#if BUILDIN_CLIPBOARD
                    message("Create build-in Clipboard");
                    clipboard_start ();
#else
                    message("Create Option Clipboard");
                    command = "lxclipboard";
#endif
                    break;
            }
        }
        public void desactivate()
        {
#if BUILDIN_CLIPBOARD
            clipboard_stop ();
#endif
        }
    }
    public class UpdatesOption: Option
    {
        private string command1;

        public UpdatesOption (LxsessionConfig config)
        {
            base (config);
            switch (config.get_item_string("Updates", "type", null))
            {
                case "update-notifier":
                    this.command1 = "update-notifier";
                    break;
                case "build-in":
                    this.command1 = "build-in";
                    break;
            }
        }

        public new void activate()
        {
            switch (this.command1)
            {
                case "build-in":
                    setup_apt_config ();
                    break;
                case "update-notifier":
                    lxsession_spawn_command_line_async(this.command1);
                    break;
            }
        }

        public void on_apt_update_file_change ()
        {
            /* Launch something that check if updates are available */
            /* For now, use apt-check from update-notifier */

            string command = "/usr/bin/nice" + " " + "/usr/bin/ionice" + " " + "-c3" + " " + "/usr/lib/update-notifier/apt-check";
            string[] create_command = command.split_set(" ",0);
            string standard_output = "";
            string standard_error = "";
            string[] updates_num;
            int exit_status;

            try {
                string[] spawn_env = Environ.get ();
                Process.spawn_sync (
                            null,
                            create_command,
                            spawn_env,
                            SpawnFlags.STDOUT_TO_DEV_NULL,
                            null, 
                            out standard_output,
                            out standard_error,
                            out exit_status);

                message ("Launching %s", command);
                message ("Update state: %s", standard_error);
                message ("Update exit status: %i", exit_status);

            }
            catch (SpawnError err)
            {
                warning (err.message);
            }

            if (standard_error != "")
            {
                updates_num = standard_error.split_set(";",2);
                message ("Number of upgrades: %s", updates_num[0]);
                message ("Number of security upgrades: %s", updates_num[1]);
            }
        }

        public void setup_apt_config ()
        {
            try
            {
                string apt_update_path = "/var/lib/apt/periodic/update-success-stamp";
                GLib.File apt_update_file ;
                GLib.FileMonitor apt_update_monitor ;

                apt_update_file = File.new_for_path(apt_update_path);
                apt_update_monitor = apt_update_file.monitor_file(GLib.FileMonitorFlags.NONE);
                apt_update_monitor.changed.connect(on_apt_update_file_change);
                message ("Monitoring apt changes");
            }
            catch (GLib.Error err)
            {
                message (err.message);
            }
        }
    }

    public class UpstartUserSessionOption: Option
    {
        private string command1;

        public UpstartUserSessionOption (LxsessionConfig config)
        {
            base (config);
            if (config.get_item_string("Session", "upstart_user_session", null) == "true")
            {
                command1 = "init --user";
            }
        }
        public new void activate()
        {
            lxsession_spawn_command_line_async(command1);
        }
    }

    public class ProxyOption: Option
    {
        private string http;

        public ProxyOption (LxsessionConfig config)
        {
            base (config);
        }
        public new void activate ()
        {
            http = global_settings.get_item_string("Proxy", "http", null);

            switch (http)
            {
                case null:
                    break;
                case "":
                    break;
                case " ":
                    break;
                default:
                    Environment.set_variable("HTTP_PROXY", http, true);
                    break;
            }
        }
    }


    public class XSettingsOption: GLib.Object
    {
        private string command;

        public XSettingsOption ()
        {

        }

        public new void activate ()
        {
            command = global_settings.get_item_string("Session", "xsettings_manager", "command");

            switch (command)
            {
                case null:
                    break;
                case "":
                    break;
                case " ":
                    break;
                case "build-in":
                    message("Activate xsettings_manager build-in"); 
                    settings_daemon_start(load_keyfile (get_config_path ("desktop.conf")));
                    break;
                case "gnome":
                    lxsession_spawn_command_line_async("gnome-settings-daemon");
                    break;
                case "xfce":
                    lxsession_spawn_command_line_async("xfsettingsd");
                    break;
                default:
                    lxsession_spawn_command_line_async(command);
                    break;
            }
        }

        public void reload ()
        {
            command = global_settings.get_item_string("Session", "xsettings_manager", "command");

            switch (command)
            {
                case "build-in":
                    message("Reload xsettings_manager build-in"); 
                    settings_daemon_reload(load_keyfile (get_config_path ("desktop.conf")));
                    break;
                default:
                    message("Reload xsettings_manager default"); 
                    this.activate();
                    break;
            }
        }
    }
}
