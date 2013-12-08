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
