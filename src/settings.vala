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

    /* Settings locations */
    public KeyFile kf;
    public string desktop_config_path { get; set; default = null;}

    public LxsessionConfigKeyFile(string session_arg, string desktop_env_name_arg, LxSignals sig) {

        kf = new KeyFile();

        desktop_config_path = get_config_path("desktop.conf");

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

        // Windows manager
        try
        {
            window_manager = kf.get_value ("Session", "window_manager");
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Panel
        try
        {
            panel_program = kf.get_value ("Session", "panel/program");
            if (panel_program != null)
            {
                try
                {
                    panel_session = kf.get_value ("Session", "panel/session");
                }
                catch (KeyFileError err)
                {
	                message (err.message);
                }
            }
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Screensaver
        try
        {
            screensaver_program = kf.get_value ("Session", "screensaver/program");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Power manager
        try
        {
            power_manager_program = kf.get_value ("Session", "power-manager/program");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Filemanager
        try
        {
            file_manager_program = kf.get_value ("Session", "file-manager/program");
            if (file_manager_program != null)
            {
                try
                {
                    file_manager_session = kf.get_value ("Session", "file-manager/session");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }

                try
                {
                    file_manager_extras = kf.get_value ("Session", "file-manager/extras");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }
            }
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Polkit Agent
        try
        {
            polkit = kf.get_value("Session", "polkit");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Dbus
        try
        {
            dbus_lxde = kf.get_value ("Dbus", "lxde");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        try
        {
            dbus_gnome = kf.get_value ("Dbus", "gnome");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Keymap options
        try
        {
            keymap_mode = kf.get_value ("Keymap", "mode");
            if (keymap_mode != null)
            {
                try
                {
                    keymap_model = kf.get_value ("Keymap", "model");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }
                try
                {
                    keymap_layout = kf.get_value ("Keymap", "layout");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }
                try
                {
                    keymap_variant = kf.get_value ("Keymap", "variant");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }
                try
                {
                    keymap_options = kf.get_value ("Keymap", "options");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }

            }
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // XRandr options
        try
        {
            xrandr_mode = kf.get_value ("XRandr", "mode");
            if (xrandr_mode != null)
            {
                try
                {
                    xrandr_command = kf.get_value ("XRandr", "command");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }
            }
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Security (keyring)
	    try
        {
            security_keyring = kf.get_value ("Security", "keyring");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }

        /* Connect to siganls changes */
        global_sig.update_keymap_layout.connect(on_update_keymap_layout);

    }


    public void save_keyfile () {
        message ("Saving desktop file");
        var str = kf.to_data (null);
        try {
            FileUtils.set_contents (desktop_config_path, str, str.length);
        } catch (FileError err) {
            warning (err.message);
        }

    }

    public void on_update_window_manager (string wm_manager) {

        this.window_manager = wm_manager;

    }

    public void on_update_keymap_layout (string option)
    {
        message("Changing keymap layout: %s", option);
        this.keymap_layout = option;
        kf.set_value ("Keymap", "layout", this.keymap_layout);
        save_keyfile();
    }

}

}
