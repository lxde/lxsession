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

namespace Lxsession
{

    public class LxsessionEnv: GLib.Object
    {

        private string display_env = "DISPLAY";
        private string pid_env = "_LXSESSION_PID";
        private string session_env = "DESKTOP_SESSION";
        private string desktop_environment_env = "XDG_CURRENT_DESKTOP";

        private string display_name;
        private string pid_str;
        private string session;
        private string desktop_environment;

        private string config_home;
        private string config_dirs;
        private string data_dirs;
        private string home_path;

        public LxsessionEnv(string session_arg, string desktop_environment_arg)
        {

            /* Constructor */
            session = session_arg;
            desktop_environment = desktop_environment_arg;
            display_name = Environment.get_variable(display_env);

        }

        public void export_env()
        {

            message("Exporting variable");
            message("desktop_environnement %s", desktop_environment_env);
            pid_str = "%d".printf (Posix.getpid());
            Environment.set_variable(session_env, session, true);
            Environment.set_variable(desktop_environment_env, desktop_environment, true);
            Environment.set_variable(pid_env, pid_str, true);
            Environment.set_variable(display_env, display_name, true);

            Environment.set_application_name ("lxsession");

            home_path = Environment.get_variable("HOME");
            config_home = Environment.get_variable("XDG_CONFIG_HOME");

            Environment.set_variable("XDG_MENU_PREFIX", global_settings.get_item_string("Environment", "menu_prefix", null), true);

            set_xdg_dirs ();
            set_misc ();

            if (config_home == null)
            {
                config_home = home_path + "/.config";
                Environment.set_variable("XDG_CONFIG_HOME", config_home, true);
            }

        }

        public bool check_alone()
        {
            string lxsession_pid;

            message ("Getting lxsession pid");
            lxsession_pid = Environment.get_variable(pid_env);

            message ("Checking pid : %s", lxsession_pid);

            if (lxsession_pid == null)
            {
                message ("Lxsession not detected");
                return true;
            }
            else
            {
                message ("Lxsession detected");
                return false;
            }
        }

        public void set_xdg_dirs ()
        {
            /* TODO Allow several value, like Lubuntu;Xubuntu; */
            string custom_config;
            string custom_data;
            string return_config;
            string return_data;

            config_dirs = Environment.get_variable("XDG_CONFIG_DIRS");
            data_dirs = Environment.get_variable("XDG_CONFIG_DIRS");

            if (session == "Lubuntu")
            {
                /* Assuming env_type is unset du to migration from old lxsession */
                custom_config = "/etc/xdg/lubuntu:/etc/xdg" ;
                custom_data = "/etc/xdg/lubuntu:/usr/local/share:/usr/share:/usr/share/gdm:/var/lib/menu-xdg";
            }
            else
            {
                custom_config = "/etc/xdg";
                custom_data ="/usr/local/share:/usr/share:/usr/share/gdm:/var/lib/menu-xdg";
            }

            switch (global_settings.get_item_string("Environment", "type", null))
            {
                case "lubuntu":
                    custom_config = "/etc/xdg/lubuntu:/etc/xdg" ;
                    custom_data = "/etc/xdg/lubuntu:/usr/local/share:/usr/share:/usr/share/gdm:/var/lib/menu-xdg";
                    break;
                default:
                    break;
            }

            if (config_dirs == null)
            {
                return_config = custom_config;
                message ("confir_dirs is null, export : %s", return_config);
            }
            else
            {
                return_config = custom_config + ":" + config_dirs;
                message ("custom_config :%s", custom_config);
                message ("config_dirs :%s", config_dirs);
                message ("confir_dirs not null, export : %s", return_config);
            }

            if (return_config != null)
            {
                message ("Exporting XDG_CONFIG_DIRS");
                Environment.set_variable("XDG_CONFIG_DIRS", return_config, true);
            }

            if (data_dirs == null)
            {
                return_data = custom_data;
                message ("data_dirs is null, export : %s", return_data);
            }
            else
            {
                return_data = custom_data + ":" + data_dirs;
                message ("custom_data :%s", custom_data);
                message ("data_dirs :%s", data_dirs);
                message ("data_dirs not null, export : %s", return_data);
            }

            if (return_data != null)
            {
                message ("Exporting XDG_DATA_DIRS");
                Environment.set_variable("XDG_DATA_DIRS", return_data, true);
            }
        }

        public void set_misc ()
        {
            /* Clean up number of desktop set by GDM */
            try
            {
                Process.spawn_command_line_async("xprop -root -remove _NET_NUMBER_OF_DESKTOPS -remove _NET_DESKTOP_NAMES -remove _NET_CURRENT_DESKTOP");
            }
            catch (GLib.SpawnError err)
            {
                message (err.message);
            }

            /* Start Dbus */
            string dbus_path;
            string dbus_env;

            dbus_path = Environment.find_program_in_path("dbus-launch");
            dbus_env = Environment.get_variable("DBUS_SESSION_BUS_ADDRESS");

            if (dbus_path == null)
            {
                if (dbus_env ==null)
                {
                    try
                    {
                        Process.spawn_command_line_async("dbus-launch --sh-syntax --exit-with-session");
                    }
                    catch (GLib.SpawnError err)
                    {
                        message (err.message);
                    }
                }
            }

            /* Enable GTK+2 integration for OpenOffice.org, if available. */
            Environment.set_variable("SAL_USE_VCLPLUGIN", "gtk", true);

            /* Add path for Qt plugins (usefull for razor session */
            string qt_plugin;
            qt_plugin = Environment.get_variable("QT_PLUGIN_PATH");
            if (qt_plugin != null)
            {
                if (qt_plugin != "")
                {
                    Environment.set_variable("QT_PLUGIN_PATH" , qt_plugin + ":/usr/lib64/kde4/plugins:/usr/lib/kde4/plugins", true);
                }
            }
        }
    }

}
