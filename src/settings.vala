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

namespace Lxsession {

public class LxsessionConfig: GLib.Object {

    /* Session identification */
    public string session_name { get; set; default = "LXDE";}
    public string desktop_env_name { get; set; default = "LXDE";}

    /* Applications */
    public string window_manager { get; set; default = null;}
    public string panel_program { get; set; default = null;}
    public string panel_session { get; set; default = null;}
    public string screensaver_program { get; set; default = null;}
    public string power_manager_program { get; set; default = null;}
    public string file_manager_program  { get; set; default = null;}
    public string file_manager_session { get; set; default = null;}
    public string file_manager_extras { get; set; default = null;}
    public string polkit { get; set; default = null;}

    /* Dbus */
    public string dbus_lxde { get; set; default = "true";}
    public string dbus_gnome { get; set; default = null;}

    /* Keymap */
    public string keymap_mode { get; set; default = null;}
    public string keymap_model { get; set; default = null;}
    public string keymap_layout { get; set; default = null;}
    public string keymap_variant { get; set; default = null;}
    public string keymap_options { get; set; default = null;}

    /* Xrandr */
    public string xrandr_mode { get; set; default = null;}
    public string xrandr_command { get; set; default = null;}

    /* Security */
    public string security_keyring { get; set; default = null;}

    /* Signals */
    public signal void update_window_manager (string wm_manager);

}

public class LxsessionConfigKeyFile: LxsessionConfig {


    public LxsessionConfigKeyFile(string session_arg, string desktop_env_name_arg) {

        KeyFile kf = new KeyFile();
        if (session_arg != "dummy")
        {
            this.session_name = session_arg;
            this.desktop_env_name = desktop_env_name_arg;
            kf = load_keyfile (get_config_path ("desktop.conf"));
        }
        else
        {
            message ("dummy mode");
            this.session_name = session_arg;
            this.desktop_env_name = desktop_env_name_arg;
            kf = load_keyfile (get_config_path (desktop_env_name_arg));
        }

	    try {
                window_manager = kf.get_value ("Session", "window_manager");
                panel_program = kf.get_value ("Session", "panel/program");
                panel_session = kf.get_value ("Session", "panel/session");
                screensaver_program = kf.get_value ("Session", "screensaver/program");
                power_manager_program = kf.get_value ("Session", "power-manager/program");
                file_manager_program = kf.get_value ("Session", "file-manager/program");
                file_manager_session = kf.get_value ("Session", "file-manager/session");
                polkit = kf.get_value("Session", "polkit");

                dbus_lxde = kf.get_value ("Dbus", "lxde");
                dbus_gnome = kf.get_value ("Dbus", "gnome");

                keymap_mode = kf.get_value ("Keymap", "mode");
                keymap_model = kf.get_value ("Keymap", "model");
                keymap_layout = kf.get_value ("Keymap", "layout");
                keymap_variant = kf.get_value ("Keymap", "variant");
                keymap_options = kf.get_value ("Keymap", "options");

                xrandr_mode = kf.get_value ("XRandr", "mode");
                xrandr_command = kf.get_value ("XRandr", "command");

                security_keyring = kf.get_value ("Security", "gnome-all");

	    } catch (KeyFileError err) {
		        warning (err.message);
	    }

        this.notify["window_manager"].connect((s, p) => {
            stdout.printf("Property '%s' has changed!\n", p.name);
            kf.set_value ("Session", "window_manager", window_manager);
            save_keyfile (kf, get_config_path("desktop.conf") );
        });

    }


    public void save_keyfile (KeyFile kf, string config_path) {

        var str = kf.to_data (null);
        try {
            FileUtils.set_contents (config_path, str, str.length);
        } catch (FileError err) {
            warning (err.message);
        }

    }

    public void on_update_window_manager (string wm_manager) {

        this.window_manager = wm_manager;

    }


}

}
