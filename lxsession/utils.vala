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
    public signal void update_window_manager (string dbus_arg, string kf_categorie = "Session", string kf_key1 = "window_manager", string? kf_key2 = null);

    /* Xsettings */
    public signal void update_gtk_theme_name (string dbus_arg, string kf_categorie="GTK", string kf_key1="sNet", string? kf_key2="ThemeName");
    public signal void update_gtk_icon_theme_name (string dbus_arg, string kf_categorie="GTK", string kf_key1="sNet", string? kf_key2="IconThemeName");
    public signal void update_gtk_font_name (string dbus_arg, string kf_categorie="GTK", string kf_key1="sGtk", string? kf_key2="FontName");
    public signal void update_gtk_toolbar_style (int dbus_arg, string kf_categorie="GTK", string kf_key1="iGtk", string? kf_key2 = "ToolbarStyle");
    public signal void update_gtk_button_images (int dbus_arg, string kf_categorie="GTK", string kf_key1="iGtk", string? kf_key2="ButtonImages");
    public signal void update_gtk_menu_images (int dbus_arg, string kf_categorie="GTK", string kf_key1="iGtk", string? kf_key2="MenuImages");
    public signal void update_gtk_cursor_theme_size (int dbus_arg, string kf_categorie="GTK", string kf_key1="iGtk", string? kf_key2="CursorThemeSize");
    public signal void update_gtk_antialias (int dbus_arg, string kf_categorie="GTK", string kf_key1="iXft", string? kf_key2="Antialias");
    public signal void update_gtk_hinting (int dbus_arg, string kf_categorie="GTK", string kf_key1="iXft", string? kf_key2="Hinting");
    public signal void update_gtk_hint_style (string dbus_arg, string kf_categorie="GTK", string kf_key1="sXft", string? kf_key2="HintStyle");
    public signal void update_gtk_rgba (string dbus_arg, string kf_categorie="GTK", string kf_key1="sXft", string? kf_key2="RGBA");
    public signal void update_gtk_color_scheme (string dbus_arg, string kf_categorie="GTK", string kf_key1="sGtk", string? kf_key2="ColorScheme");
    public signal void update_gtk_cursor_theme_name (string dbus_arg, string kf_categorie="GTK", string kf_key1="sGtk", string? kf_key2="CursorThemeName");
    public signal void update_gtk_toolbar_icon_size (int dbus_arg, string kf_categorie="GTK", string kf_key1="iGtk", string? kf_key2="ToolbarIconSize");
    public signal void update_gtk_enable_event_sounds (int dbus_arg, string kf_categorie="GTK", string kf_key1="iNet", string? kf_key2="EnableEventSounds");
    public signal void update_gtk_enable_input_feedback_sounds (int dbus_arg, string kf_categorie="GTK", string kf_key1="iNet", string? kf_key2="EnableInputFeedbackSounds");

    public signal void update_mouse_acc_factor (int dbus_arg, string kf_categorie="Mouse", string kf_key1="AccFactor", string? kf_key2 = null);
    public signal void update_mouse_acc_threshold (int dbus_arg, string kf_categorie="Mouse", string kf_key1="AccThreshold", string? kf_key2=null);
    public signal void update_mouse_left_handed (int dbus_arg, string kf_categorie="Mouse", string kf_key1="LeftHanded", string? kf_key2=null);

    public signal void update_keyboard_delay (int dbus_arg, string kf_categorie="Keyboard", string kf_key1="Delay", string? kf_key2=null);
    public signal void update_keyboard_interval (int dbus_arg, string kf_categorie="Keyboard", string kf_key1="Interval", string? kf_key2=null);
    public signal void update_keyboard_beep (int dbus_arg, string kf_categorie="Keyboard", string kf_key1="Beep", string? kf_key2=null);

    public signal void reload_settings_daemon();

    /* Set for managers */
    public signal void request_audio_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="audio_manager", string? kf_key2="command");
    public signal void request_workspace_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="workspace_manager", string? kf_key2="command");
    public signal void request_terminal_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="terminal_manager", string? kf_key2="command");
    public signal void request_screenshot_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="screenshot_manager", string? kf_key2="command");
    public signal void request_upgrade_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="upgrade_manager", string? kf_key2="command");
    public signal void request_lock_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="lock_manager", string? kf_key2="command");
    public signal void request_message_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="message_manager", string? kf_key2="command");
    public signal void request_xsettings_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="xsettings_manager", string? kf_key2="command");

    /* Windows Manager */
    public signal void request_windows_manager_command_set (string dbus_arg, string kf_categorie="Session", string kf_key1="windows_manager", string? kf_key2="command");
    public signal void request_windows_manager_session_set (string dbus_arg, string kf_categorie="Session", string kf_key1="windows_manager", string? kf_key2="session");
    public signal void request_windows_manager_extras_set (string dbus_arg, string kf_categorie="Session", string kf_key1="windows_manager", string? kf_key2="extras");

    /* Panel control */
    public signal void request_panel_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="panel", string? kf_key2="command");
    public signal void request_panel_session_set(string dbus_arg, string kf_categorie="Session", string kf_key1="panel", string? kf_key2="session");

    /* Dock control */
    public signal void request_dock_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="dock", string? kf_key2="command");
    public signal void request_dock_session_set(string dbus_arg, string kf_categorie="Session", string kf_key1="dock", string? kf_key2="session");

    /* Filemanager control */
    public signal void request_file_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="file_manager", string? kf_key2="command");
    public signal void request_file_manager_session_set(string dbus_arg, string kf_categorie="Session", string kf_key1="file_manager", string? kf_key2="session");
    public signal void request_file_manager_extras_set(string dbus_arg, string kf_categorie="Session", string kf_key1="file_manager", string? kf_key2="extras");

    /* Desktop control */
    public signal void request_desktop_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="desktop_manager", string? kf_key2="command");
    public signal void request_desktop_wallpaper_set(string dbus_arg, string kf_categorie="Session", string kf_key1="desktop_manager", string? kf_key2="wallpaper");

    /* Screensaver control */
    public signal void request_screensaver_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="screensaver", string? kf_key2="command");

    /* Power Manager control */
    public signal void request_power_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="power_manager", string? kf_key2="command");

    /* Polkit control */
    public signal void request_polkit_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="polkit", string? kf_key2="command");

    /* Network gui control */
    public signal void request_network_gui_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="network_gui", string? kf_key2="command");

    /* Composite manager */
    public signal void request_composite_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="composite_manager", string? kf_key2="command");
    public signal void request_composite_manager_autostart_set (string dbus_arg, string kf_categorie="Session", string kf_key1="composite_manager", string? kf_key2="autostart");

    /* IM */
    public signal void request_im1_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="im1", string? kf_key2="command");
    public signal void request_im1_autostart_set (string dbus_arg, string kf_categorie="Session", string kf_key1="im1", string? kf_key2="autostart");
    public signal void request_im2_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="im2", string? kf_key2="command");
    public signal void request_im2_autostart_set (string dbus_arg, string kf_categorie="Session", string kf_key1="im2", string? kf_key2="autostart");

    /* Mime applications */
    public signal void request_webbrowser_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="webbrowser", string? kf_key2="command");
    public signal void request_email_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="email", string? kf_key2="command");
    public signal void request_pdf_reader_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="pdf_reader", string? kf_key2="command");
    public signal void request_video_player_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="video_player", string? kf_key2="command");
    public signal void request_audio_player_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="audio_player", string? kf_key2="command");
    public signal void request_images_display_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="images_display", string? kf_key2="command");
    public signal void request_text_editor_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="text_editor", string? kf_key2="command");
    public signal void request_archive_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="archive", string? kf_key2="command");
    public signal void request_charmap_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="charmap", string? kf_key2="command");
    public signal void request_calculator_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="calculator", string? kf_key2="command");
    public signal void request_spreadsheet_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="spreadsheet", string? kf_key2="command");
    public signal void request_bittorent_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="bittorent", string? kf_key2="command");
    public signal void request_document_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="document", string? kf_key2="command");
    public signal void request_webcam_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="webcam", string? kf_key2="command");
    public signal void request_burn_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="burn", string? kf_key2="command");
    public signal void request_notes_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="notes", string? kf_key2="command");
    public signal void request_disk_utility_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="disk_utility", string? kf_key2="command");
    public signal void request_tasks_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="tasks", string? kf_key2="command");

    /* Widget */
    public signal void request_widget1_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="widget1", string? kf_key2="command");
    public signal void request_widget1_autostart_set (string dbus_arg, string kf_categorie="Session", string kf_key1="widget1", string? kf_key2="autostart");

    /* Quit manager */
    public signal void request_quit_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="quit_manager", string? kf_key2="command");
    public signal void request_quit_manager_image_set(string dbus_arg, string kf_categorie="Session", string kf_key1="quit_manager", string? kf_key2="image");
    public signal void request_quit_manager_layout_set(string dbus_arg, string kf_categorie="Session", string kf_key1="quit_manager", string? kf_key2="layout");

    /* Launcher manager */
    public signal void request_launcher_manager_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="launcher_manager", string? kf_key2="command");
    public signal void request_launcher_manager_autostart_set(string dbus_arg, string kf_categorie="Session", string kf_key1="launcher_manager", string? kf_key2="autostart");

    /* clipboard control */
    public signal void request_clipboard_command_set(string dbus_arg, string kf_categorie="Session", string kf_key1="clipboard", string? kf_key2="command");

    /* Keymap control */
    public signal void request_keymap_mode_set (string dbus_arg, string kf_categorie="Keymap", string kf_key1="mode", string? kf_key2=null);
    public signal void request_keymap_model_set (string dbus_arg, string kf_categorie="Keymap", string kf_key1="model", string? kf_key2=null);
    public signal void request_keymap_layout_set (string dbus_arg, string kf_categorie="Keymap", string kf_key1="layout", string? kf_key2=null);
    public signal void request_keymap_variant_set (string dbus_arg, string kf_categorie="Keymap", string kf_key1="variant", string? kf_key2=null);
    public signal void request_keymap_options_set (string dbus_arg, string kf_categorie="Keymap", string kf_key1="options", string? kf_key2=null);

    /* XRandr */
    public signal void request_xrandr_mode_set (string dbus_arg, string kf_categorie="XRandr", string kf_key1="mode", string? kf_key2=null);
    public signal void request_xrandr_command_set (string dbus_arg, string kf_categorie="XRandr", string kf_key1="command", string? kf_key2=null);

    /* Security */
    public signal void request_security_keyring_set (string dbus_arg, string kf_categorie="Security", string kf_key1="keyring", string? kf_key2=null);

    /* a11y */
    public signal void request_a11y_type_set (string dbus_arg, string kf_categorie="a11y", string kf_key1="type", string? kf_key2=null);

    /* Proxy */
    public signal void request_proxy_http_set (string dbus_arg, string kf_categorie = "Proxy", string kf_key1="http", string? kf_key2=null);

    /* Updates */
    public signal void request_updates_type_set (string dbus_arg, string kf_categorie="Updates", string kf_key1="type", string? kf_key2=null);

    /* Autostart */
    public signal void request_disable_autostart_set (string dbus_arg, string kf_categorie="Session", string kf_key1="disable_autostart", string? kf_key2=null);

    /* State */
    public signal void request_laptop_mode_set(string dbus_arg, string kf_categorie = "State", string kf_key1 = "laptop_mode", string? kf_key2 = null);
    public signal void request_guess_default_state_set(string dbus_arg, string kf_categorie = "State", string kf_key1 = "guess_default", string? kf_key2 = null);


    /* Dbus */
    public signal void request_dbus_lxde_set(string dbus_arg, string kf_categorie="Dbus", string kf_key1="lxde", string? kf_key2=null);
    public signal void request_dbus_gnome_set(string dbus_arg, string kf_categorie="Dbus", string kf_key1="gnome", string? kf_key2=null);

    /* Upstart */
    public signal void request_upstart_user_session_set (string dbus_arg, string kf_categorie ="Session", string kf_key1 = "upstart_user_session", string? kf_key2=null);

    /* Environment */
    public signal void request_env_type_set(string dbus_arg, string kf_categorie = "Environment", string kf_key1 = "type", string? kf_key2=null);
    public signal void request_env_menu_prefix_set(string dbus_arg, string kf_categorie = "Environment", string kf_key1="menu_prefix", string? kf_key2=null);

    /* Mime */
    public signal void request_mime_distro_set(string dbus_arg, string kf_categorie = "Mime", string kf_key1 = "distro", string? kf_key2=null);
    public signal void request_mime_folders_installed_set(string[] dbus_arg, string kf_categorie = "Mime", string kf_key1 = "folders", string kf_key2="installed");
    public signal void request_mime_folders_available_set(string[] dbus_arg, string kf_categorie = "Mime", string kf_key1 = "folders", string kf_key2="available");
    public signal void request_mime_webbrowser_installed_set(string[] dbus_arg, string kf_categorie = "Mime", string kf_key1 = "webbrowser", string kf_key2="installed");
    public signal void request_mime_webbrowser_available_set(string[] dbus_arg, string kf_categorie = "Mime", string kf_key1 = "webbrowser", string kf_key2="available");
    public signal void request_mime_email_installed_set(string[] dbus_arg, string kf_categorie = "Mime", string kf_key1 = "email", string kf_key2="installed");
    public signal void request_mime_email_available_set(string[] dbus_arg, string kf_categorie = "Mime", string kf_key1 = "email", string kf_key2="available");

    public signal void generic_set_signal (string dbus_arg, string kf_categorie, string kf_key1, string? kf_key2);

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
