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
            try
            {
                message ("Options - Launch command %s",command);
                Process.spawn_command_line_async(command);
            }
            catch (SpawnError err)
            {
                warning (err.message);
            }
        }
    }

    public class KeymapOption: Option
    {
        public KeymapOption (LxsessionConfig config)
        {
            base (config);
            if (config.keymap_mode == "user")
            {
                command = create_user_mode_command(config);
            }
        }
        public string create_user_mode_command(LxsessionConfig config)
        {
            var builder = new StringBuilder ();
            builder.append("setxkbmap ");
            if (config.keymap_model != null)
            {
                builder.append("-model ");
                builder.append(config.keymap_model);
                builder.append(" ");
            }
            if (config.keymap_layout != null)
            {
                builder.append("-layout ");
                builder.append(config.keymap_layout);
                builder.append(" ");
            }
            if (config.keymap_variant != null)
            {
                builder.append("-variant ");
                message ("Show keymap variant : %s", config.keymap_variant);
                builder.append(config.keymap_variant);
                builder.append(" ");
            }
            if (config.keymap_options != null)
            {
                builder.append("-options ");
                message ("Show keymap options : %s", config.keymap_options);
                builder.append(config.keymap_options);
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
            if (config.xrandr_mode == "command")
            {
                command = create_command_mode_command(config);
            }
        }
        public string create_command_mode_command(LxsessionConfig config)
        {
            command = config.xrandr_command;
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
            switch (config.security_keyring)
            {
                case "gnome-all":
                    command1 = "gnome-keyring-daemon --start --components=gpg";
                    command2 = "gnome-keyring-daemon --start --components=pkcs11";
                    command3 = "gnome-keyring-daemon --start --components=secrets";
                    command4 = "gnome-keyring-daemon --start --components=ssh";
                    break;
            }

        }
        public new void activate()
        {
            try
            {
                Process.spawn_command_line_async(command1);
                Process.spawn_command_line_async(command2);
                Process.spawn_command_line_async(command3);
                Process.spawn_command_line_async(command4);
            }
            catch (SpawnError err)
            {
                warning (err.message);
            }
        }
    }
    public class ClipboardOption: Option
    {
        public ClipboardOption (LxsessionConfig config)
        {
            base (config);
            switch (config.clipboard_command)
            {
                case "lxclipboard":
                    command = "lxclipboard";
                    break;
            }
        }
    }
}
