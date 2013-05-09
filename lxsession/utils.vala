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

public string get_config_home_path (string conf_file)
{

    string user_config_dir = Path.build_filename(
                             Environment.get_user_config_dir (),
                             "lxsession",
                             session_global,
                             conf_file);

    return user_config_dir;

}


public string get_config_path (string conf_file) {

    string final_config_file;

    string user_config_dir = get_config_home_path(conf_file);

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

    public signal void update_disable_autostart (string dbus_arg);
    public signal void update_keymap_mode (string dbus_arg);
    public signal void update_keymap_model (string dbus_arg);
    public signal void update_keymap_layout (string dbus_arg);
    public signal void update_keymap_variant (string dbus_arg);
    public signal void update_keymap_options (string dbus_arg);
    public signal void update_xrandr_mode (string dbus_arg);
    public signal void update_xrandr_command (string dbus_arg);

    public signal void update_env_type (string dbus_arg);
    public signal void update_env_menu_prefix (string dbus_arg);

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

    public signal void update_laptop_mode(string mode);

    public signal void update_updates_activate (string dbus_arg);

    public signal void request_upstart_user_session_set (string dbus_arg);

    public signal void reload_settings_daemon();

    /* Set for managers */
    public signal void request_audio_manager_command_set(string manager);
    public signal void request_workspace_manager_command_set(string manager);
    public signal void request_launcher_manager_command_set(string manager);
    public signal void request_terminal_manager_command_set(string manager);
    public signal void request_screenshot_manager_command_set(string manager);
    public signal void request_upgrades_manager_command_set(string manager);

    /* Windows Manager */
    public signal void request_windows_manager_command_set (string dbus_arg);
    public signal void request_windows_manager_session_set (string dbus_arg);
    public signal void request_windows_manager_extras_set (string dbus_arg);

    /* Panel control */
    public signal void request_panel_command_set(string dbus_arg);
    public signal void request_panel_session_set(string dbus_arg);

    /* Dock control */
    public signal void request_dock_command_set(string dbus_arg);
    public signal void request_dock_session_set(string dbus_arg);

    /* Filemanager control */
    public signal void request_file_manager_command_set(string dbus_arg);
    public signal void request_file_manager_session_set(string dbus_arg);
    public signal void request_file_manager_extras_set(string dbus_arg);

    /* Desktop control */
    public signal void request_desktop_command_set(string dbus_arg);
    public signal void request_desktop_wallpaper_set(string dbus_arg);

    /* Screensaver control */
    public signal void request_screensaver_command_set(string dbus_arg);

    /* Power Manager control */
    public signal void request_power_manager_command_set(string dbus_arg);

    /* Polkit control */
    public signal void request_polkit_command_set(string dbus_arg);

    /* Network gui control */
    public signal void request_network_gui_command_set(string dbus_arg);

    /* Composite manager */
    public signal void request_composite_manager_command_set(string manager);
    public signal void request_composite_manager_autostart_set (string dbus_arg);

    /* Quit manager */
    public signal void request_quit_manager_command_set(string manager);
    public signal void request_quit_manager_image_set(string manager);
    public signal void request_quit_manager_layout_set(string manager);

}

public bool detect_laptop()
{
    string test_laptop_detect = Environment.find_program_in_path("laptop-detect");
    if (test_laptop_detect != null)
    {
        int exit_status;
        string standard_output, standard_error;
        try
        {
            Process.spawn_command_line_sync ("laptop-detect", out standard_output,
                                                              out standard_error,
                                                              out exit_status);
            if (exit_status == 0)
            {
                message ("Laptop detect return true");
                return true;
            }
            else
            {
                message ("Laptop detect return false");
                return false;
            }
        }
        catch (SpawnError err)
        {
            warning (err.message);
            return false;
        }
    }
    else
    {
        message ("Laptop detect not find");
        /* TODO check upower, and /proc files like laptop-detect to find bateries */
        return false;
    }
}

public bool check_package_manager_running ()
{
    GLib.File dpkg, apt_archives, apt_lists, unattended_upgrades;
    bool return_value = false;

    dpkg = File.new_for_path("/var/lib/dpkg/lock");
    apt_archives = File.new_for_path("/var/cache/apt/archives/lock");
    apt_lists = File.new_for_path("/var/lib/apt/lists/lock");
    unattended_upgrades = File.new_for_path("/var/run/unattended-upgrades.lock");

    if (dpkg.query_exists ())
    {
        return_value = true;
    }

    if (apt_archives.query_exists ())
    {
        return_value = true;
    }

    if (apt_lists.query_exists ())
    {
        return_value = true;
    }

    if (unattended_upgrades.query_exists ())
    {
        return_value = true;
    }

    return return_value;
}

}
