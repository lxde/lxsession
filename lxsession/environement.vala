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
            home_path = Environment.get_variable("HOME");
            config_home = Environment.get_variable("XDG_CONFIG_HOME");

        }

        /* Export environment that doesn't need settings, should be export before reading settings */
        public void export_primary_env ()
        {
            message("Exporting primary_variable");
            message("desktop_environnement %s", desktop_environment_env);
            pid_str = "%d".printf (Posix.getpid());
            Environment.set_variable(session_env, session, true);
            Environment.set_variable(desktop_environment_env, desktop_environment, true);
            Environment.set_variable(pid_env, pid_str, true);
            Environment.set_variable(display_env, display_name, true);

            Environment.set_application_name ("lxsession");

            if (config_home == null)
            {
                config_home = home_path + "/.config";
                Environment.set_variable("XDG_CONFIG_HOME", config_home, true);
            }

            set_xdg_dirs (null);
        }

        public void export_env()
        {
            message("Exporting variable");
            message("desktop_environnement %s", desktop_environment_env);

            Environment.set_variable("XDG_MENU_PREFIX", global_settings.get_item_string("Environment", "menu_prefix", null), true);

            set_xdg_dirs ("all");
            set_export();
            set_misc ();

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

        public void set_xdg_dirs (string? mode)
        {
            /* TODO Allow several value, like Lubuntu;Xubuntu; */
            string custom_config;
            string custom_data;
            string return_config;
            string return_data;

            config_dirs = Environment.get_variable("XDG_CONFIG_DIRS");
            data_dirs = Environment.get_variable("XDG_DATA_DIRS");

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

            if (mode == "all")
            {
                switch (global_settings.get_item_string("Environment", "type", null))
                {
                    case "lubuntu":
                        custom_config = "/etc/xdg/lubuntu:/etc/xdg" ;
                        custom_data = "/etc/xdg/lubuntu:/usr/local/share:/usr/share:/usr/share/gdm:/var/lib/menu-xdg";
                        break;
                    default:
                        break;
                }
            }

            if (config_dirs == null)
            {
                return_config = custom_config;
                message ("confir_dirs is null, export : %s", return_config);
            }
            else
            {
                string[] custom_config_array = custom_config.split_set(":",0);
                string[] config_dirs_array = config_dirs.split_set(":",0);

                string custom_config_check = "";

                foreach (string custom_str in custom_config_array)
                {
                    bool delete_str = false;
                    foreach (string config_str in config_dirs_array)
                    {
                        if (custom_str == config_str)
                        {
                            delete_str = true;
                        }
                    }

                    if (delete_str == false)
                    {
                        custom_config_check = custom_config_check + custom_str +":";
                    }
                }

                return_config = custom_config_check + config_dirs;
                message ("custom_config :%s", custom_config_check);
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
                string[] custom_data_array = custom_data.split_set(":",0);
                string[] data_dirs_array = data_dirs.split_set(":",0);

                string custom_data_check = "";

                foreach (string custom_data_str in custom_data_array)
                {
                    bool delete_data_str = false;
                    foreach (string data_str in data_dirs_array)
                    {
                        if (custom_data_str == data_str)
                        {
                            delete_data_str = true;
                        }
                    }

                    if (delete_data_str == false)
                    {
                        custom_data_check = custom_data_check + custom_data_str +":";
                    }
                }

                return_data = custom_data_check + data_dirs;
                message ("custom_data :%s", custom_data_check);
                message ("data_dirs :%s", data_dirs);
                message ("data_dirs not null, export : %s", return_data);
            }

            if (return_data != null)
            {
                message ("Exporting XDG_DATA_DIRS");
                Environment.set_variable("XDG_DATA_DIRS", return_data, true);
            }
        }

        public void set_export ()
        {

            KeyFile env_kf;

            env_kf = load_keyfile (get_config_path ("desktop.conf"));

            try
            {
                if (env_kf.get_keys("Environment_variable") != null)
                {
                    string[] env_list = env_kf.get_keys("Environment_variable");
                    foreach (string entry in env_list)
                    {
                        if (entry != null)
                        {
                            debug("set_export, entry: %s", entry);
                            Environment.set_variable(entry, env_kf.get_value("Environment_variable",entry), true);
                        }
	                }
                }
            }
            catch (GLib.KeyFileError e)
            {
                message ("No entry in [Environment_variable]. %s", e.message);
            }
        }

        public void set_misc ()
        {
            /* Clean up number of desktop set by GDM */
            lxsession_spawn_command_line_async("xprop -root -remove _NET_NUMBER_OF_DESKTOPS -remove _NET_DESKTOP_NAMES -remove _NET_CURRENT_DESKTOP");

            /* Start Dbus */
/* It actually never worked so let it be commented out
            string dbus_path;
            string dbus_env;

            dbus_path = Environment.find_program_in_path("dbus-launch");
            dbus_env = Environment.get_variable("XDG_RUNTIME_DIR");

            if (dbus_path != null)
            {
                if (dbus_env != null)
                {
                    string dbus_socket = dbus_env + "/bus";
                    if (!FileUtils.test (dbus_socket, FileTest.EXISTS))
                    {
                        lxsession_spawn_command_line_async("dbus-launch --sh-syntax --exit-with-session");
                    }
                }
            }
*/

            if (global_settings.get_item_string("Environment", "toolkit_integration", null) == "true")
            {
            /* Enable toolkit integration for OpenOffice.org / LibreOffice, if available. */
            string toolkit_variable = global_settings.get_item_string("Environment", "toolkit_integration", null);

                switch (toolkit_variable)
                {
                    case "gtk2":
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "gtk", true);
                        break;
                    case "gtk3":
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "gtk3", true);
                        break;
                    case "gtk":
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "gtk", true);
                        break;
                    case "gen":
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "gen", true);
                        break;
                    case "kde4":
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "kde4", true);
                        break;
                    case "kde":
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "kde4", true);
                        break;
                    case "qt":
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "kde4", true);
                        break;
                    case "qt4":
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "kde4", true);
                        break;
                    default:
                        Environment.set_variable("SAL_USE_VCLPLUGIN", "gtk", true);
                        break;
                }
            }

            /* Disable GTK+ 3 overlay scrollbar */
            if (global_settings.get_item_string("Environment", "gtk", "overlay_scrollbar_disable") == "true")
            {
                Environment.set_variable("GTK_OVERLAY_SCROLLING", "0", true);
            }

            /* Force theme for QT apps */
            if (global_settings.get_item_string("Environment", "qt", "force_theme") != null)
            {
                Environment.set_variable("QT_STYLE_OVERRIDE", global_settings.get_item_string("Environment", "qt", "force_theme"), true);
            }

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

            /* Add support for App menu */
            if (global_settings.get_item_string("Environment", "ubuntu_menuproxy", null) == "true")
            {
                Environment.set_variable("UBUNTU_MENUPROXY", "libappmenu.so", true);
            }

            /* Export variable for im manager */
            if (global_settings.get_item_string("Session", "im_manager", "command") != null)
            {
                Environment.set_variable("GTK_IM_MODULE", global_settings.get_item_string("Session", "im_manager", "command") , true);
                Environment.set_variable("QT_IM_MODULE", global_settings.get_item_string("Session", "im_manager", "command") , true);
                Environment.set_variable("XMODIFIERS=@im", global_settings.get_item_string("Session", "im_manager", "command") , true);
            }

            /* Add some needed variables for LXQt / Qt */
            if (global_settings.get_item_string("Environment", "qt", "platform") != null)
            {
                Environment.set_variable("QT_PLATFORM_PLUGIN", global_settings.get_item_string("Environment", "qt", "platform"), true);
                Environment.set_variable("QT_QPA_PLATFORMTHEME", global_settings.get_item_string("Environment", "qt", "platform"), true);
            }
        }
    }

}
