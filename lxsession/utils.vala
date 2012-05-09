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

namespace Lxsession{

public string session_global;

public struct AppType {
    public string name;
    public string[] command;
    public bool guard;
    public string application_type;
}

public KeyFile load_keyfile (string config_path) {

    KeyFile kf = new KeyFile();

    try {
        kf.load_from_file(config_path, KeyFileFlags.NONE);
    } catch (KeyFileError err) {
        warning (err.message);
    } catch (FileError err) {
        warning (err.message);
    }

    return kf;
}

public string get_config_path (string conf_file) {

    string final_config_file;

    string user_config_dir = Path.build_filename(
                             Environment.get_user_config_dir (),
                             "lxsession",
                             session_global,
                             conf_file);

    if (FileUtils.test (user_config_dir, FileTest.EXISTS))
    {
        message ("User config used : %s", user_config_dir);
        final_config_file = user_config_dir;
    }
    else
    {
        string[] system_config_dirs = Environment.get_system_config_dirs ();
        string config_system_location = null;
        string path_system_config_file = null;

        foreach (string config in (system_config_dirs)) {
            config_system_location = Path.build_filename (config, "lxsession", session_global);
            message ("Config system location : %s", config_system_location);
            if (FileUtils.test (config_system_location, FileTest.EXISTS)) {
                path_system_config_file = Path.build_filename (config_system_location, conf_file);
                break;
            }
        }
      message ("System system path location : %s", path_system_config_file);
      final_config_file =  path_system_config_file;

     }
     message ("Final file used : %s", final_config_file);
     return final_config_file;

}

public class LxSignals : Object
{
    public signal void update_window_manager (string dbus_arg);
    public signal void update_keymap_mode (string dbus_arg);
    public signal void update_keymap_model (string dbus_arg);
    public signal void update_keymap_layout (string dbus_arg);
    public signal void update_keymap_variant (string dbus_arg);
    public signal void update_keymap_options (string dbus_arg);
    public signal void update_xrandr_mode (string dbus_arg);
    public signal void update_xrandr_command (string dbus_arg);

    public signal void update_gtk_theme_name (string dbus_arg);
    public signal void update_gtk_icon_theme_name (string dbus_arg);
    public signal void update_gtk_font_name (string dbus_arg);
    public signal void update_gtk_toolbar_style (int dbus_arg);
    public signal void update_gtk_button_images (int dbus_arg);
    public signal void update_gtk_menu_images (int dbus_arg);
    public signal void update_gtk_cursor_theme_size (int dbus_arg);
    public signal void update_gtk_antialias (int dbus_arg);
    public signal void update_gtk_hinting (int dbus_arg);
    public signal void update_gtk_hint_style (string dbus_arg);
    public signal void update_gtk_rgba (string dbus_arg);
    public signal void update_gtk_color_scheme (string dbus_arg);
    public signal void update_gtk_cursor_theme_name (string dbus_arg);
    public signal void update_gtk_toolbar_icon_size (int dbus_arg);
    public signal void update_gtk_enable_event_sounds (int dbus_arg);
    public signal void update_gtk_enable_input_feedback_sounds (int dbus_arg);

    public signal void update_mouse_acc_factor (int dbus_arg);
    public signal void update_mouse_acc_threshold (int dbus_arg);
    public signal void update_mouse_left_handed (int dbus_arg);

    public signal void update_keyboard_delay (int dbus_arg);
    public signal void update_keyboard_interval (int dbus_arg);
    public signal void update_keyboard_beep (int dbus_arg);

    public signal void reload_settings_daemon();

}

public bool detect_laptop()
{
    /* TODO check upower to find bateries, and use laptop-detect */
    return false;
}

}
