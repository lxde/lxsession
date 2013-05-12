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

/* TODO Split correctly the settings for enable differents backends (.ini, gsettings ...) */ 

namespace Lxsession {

public class LxsessionConfig: GLib.Object {

    /* Session identification */
    public string session_name { get; set; default = "LXDE";}
    public string desktop_env_name { get; set; default = "LXDE";}

    /* Applications */
    public string window_manager { get; set; default = null;}
    public string windows_manager_command { get; set; default = null;}
    public string windows_manager_session { get; set; default = null;}
    public string windows_manager_extras { get; set; default = null;}
    public string panel_command { get; set; default = null;}
    public string panel_session { get; set; default = null;}
    public string dock_command { get; set; default = null;}
    public string dock_session { get; set; default = null;}
    public string screensaver_command { get; set; default = null;}
    public string power_manager_command { get; set; default = null;}
    public string file_manager_command  { get; set; default = null;}
    public string file_manager_session { get; set; default = null;}
    public string file_manager_extras { get; set; default = null;}
    public string desktop_command { get; set; default = null;}
    public string desktop_wallpaper { get; set; default = null;}
    public string polkit_command { get; set; default = null;}
    public string network_gui_command { get; set; default = null;}
    public string audio_manager_command { get; set; default = null;}
    public string quit_manager_command { get; set; default = null;}
    public string quit_manager_image { get; set; default = null;}
    public string quit_manager_layout { get; set; default = null;}
    public string workspace_manager_command { get; set; default = null;}
    public string launcher_manager_command { get; set; default = null;}
    public string terminal_manager_command { get; set; default = null;}
    public string screenshot_manager_command { get; set; default = null;}
    public string upgrade_manager_command { get; set; default = null;}
    public string composite_manager_command { get; set; default = null;}
    public string composite_manager_autostart { get; set; default = null;}
    public string disable_autostart { get; set; default = null;}
    public string upstart_user_session { get; set; default = null;}

    /* State */
    public string laptop_mode { get; set; default = null;}

    /* Clipboard */
    public string clipboard_command { get; set; default = "lxclipboard";}

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

    /* a11y */
    public string a11y_type { get; set; default = "gnome";}

    /* Updates */
    public string updates_type { get; set; default = null;}

    /* Environnement */
    public string env_type { get; set; default = null;}
    public string env_menu_prefix { get; set; default = "lxde-";}

    /* GTK */
    public string gtk_theme_name { get; set; default = null;}
    public string gtk_icon_theme_name { get; set; default = null;}
    public string gtk_font_name { get; set; default = null;}
    public int gtk_toolbar_style { get; set; default = 3;}
    public int gtk_button_images { get; set; default = 0;}
    public int gtk_menu_images { get; set; default = 1;}
    public int gtk_cursor_theme_size { get; set; default = 18;}
    public int gtk_antialias { get; set; default = 1;}
    public int gtk_hinting { get; set; default = 1;}
    public string gtk_hint_style { get; set; default = "hintslight";}
    public string gtk_rgba { get; set; default = "rgb";}
    public string gtk_color_scheme { get; set; default = null;}
    public string gtk_cursor_theme_name { get; set; default = "DMZ-White";}
    public int gtk_toolbar_icon_size { get; set; default = 3;}
    public int gtk_enable_event_sounds { get; set; default = 1;}
    public int gtk_enable_input_feedback_sounds { get; set; default = 1;}

    /* Mouse */
    public int mouse_acc_factor { get; set; default = 20;}
    public int mouse_acc_threshold { get; set; default = 10;}
    public int mouse_left_handed { get; set; default = 0;}

    /* Keyboard */
    public int keyboard_delay { get; set; default = 500;}
    public int keyboard_interval { get; set; default = 30;}
    public int keyboard_beep { get; set; default = 1;}

}

public class LxsessionConfigKeyFile: LxsessionConfig {

    /* Settings locations */
    public KeyFile kf;
    public string desktop_config_path { get; set; default = null;}
    public GLib.File desktop_file ;
    public GLib.File home_desktop_file ;
    public GLib.FileMonitor monitor_desktop_file ;
    public GLib.FileMonitor monitor_home_desktop_file;
    public GLib.Cancellable monitor_cancel;

    public LxsessionConfigKeyFile(string session_arg, string desktop_env_name_arg, LxSignals sig) {

        kf = new KeyFile();

        desktop_config_path = get_config_path("desktop.conf");
        this.session_name = session_arg;
        this.desktop_env_name = desktop_env_name_arg;

        read_keyfile();

        /* Connect to signals changes */
        global_sig.update_window_manager.connect(on_update_window_manager);

        global_sig.update_disable_autostart.connect(on_update_disable_autostart);

        global_sig.request_upstart_user_session_set.connect(on_update_upstart_user_session);

        global_sig.update_env_type.connect(on_update_env_type);
        global_sig.update_env_menu_prefix.connect(on_update_env_menu_prefix);

        global_sig.update_gtk_theme_name.connect(on_update_gtk_theme_name);
        global_sig.update_gtk_icon_theme_name.connect(on_update_gtk_icon_theme_name);
        global_sig.update_gtk_font_name.connect(on_update_gtk_font_name);
        global_sig.update_gtk_toolbar_style.connect(on_update_gtk_toolbar_style);
        global_sig.update_gtk_button_images.connect(on_update_gtk_button_images);
        global_sig.update_gtk_menu_images.connect(on_update_gtk_menu_images);
        global_sig.update_gtk_cursor_theme_size.connect(on_update_gtk_cursor_theme_size);
        global_sig.update_gtk_antialias.connect(on_update_gtk_antialias);
        global_sig.update_gtk_hinting.connect(on_update_gtk_hinting);
        global_sig.update_gtk_hint_style.connect(on_update_gtk_hint_style);
        global_sig.update_gtk_rgba.connect(on_update_gtk_rgba);
        global_sig.update_gtk_color_scheme.connect(on_update_gtk_color_scheme);
        global_sig.update_gtk_cursor_theme_name.connect(on_update_gtk_cursor_theme_name);
        global_sig.update_gtk_toolbar_icon_size.connect(on_update_gtk_toolbar_icon_size);
        global_sig.update_gtk_enable_event_sounds.connect(on_update_gtk_enable_event_sounds);
        global_sig.update_gtk_enable_input_feedback_sounds.connect(on_update_gtk_enable_input_feedback_sounds);

        global_sig.update_mouse_acc_factor.connect(on_update_mouse_acc_factor);
        global_sig.update_mouse_acc_threshold.connect(on_update_mouse_acc_threshold);
        global_sig.update_mouse_left_handed.connect(on_update_mouse_left_handed);

        global_sig.update_keyboard_delay.connect(on_update_keyboard_delay);
        global_sig.update_keyboard_interval.connect(on_update_keyboard_interval);
        global_sig.update_keyboard_beep.connect(on_update_keyboard_beep);

        global_sig.update_laptop_mode.connect(on_update_laptop_mode);

        global_sig.reload_settings_daemon.connect(on_reload_settings_daemon);

        /* Set for managers */
        global_sig.request_audio_manager_command_set.connect(on_request_audio_manager_command_set);
        global_sig.request_workspace_manager_command_set.connect(on_request_workspace_manager_command_set);
        global_sig.request_launcher_manager_command_set.connect(on_request_launcher_manager_command_set);
        global_sig.request_terminal_manager_command_set.connect(on_request_terminal_manager_command_set);
        global_sig.request_screenshot_manager_command_set.connect(on_request_screenshot_manager_command_set);
        global_sig.request_upgrade_manager_command_set.connect(on_request_screenshot_manager_command_set);

        /* Windows Manager control */
        global_sig.request_windows_manager_command_set.connect(on_request_windows_manager_command_set);
        global_sig.request_windows_manager_session_set.connect(on_request_windows_manager_session_set);
        global_sig.request_windows_manager_extras_set.connect(on_request_windows_manager_extras_set);

        /* Panel control */
        global_sig.request_panel_command_set.connect(on_request_panel_command_set);
        global_sig.request_panel_session_set.connect(on_request_panel_session_set);

        /* Dock control */
        global_sig.request_dock_command_set.connect(on_request_dock_command_set);
        global_sig.request_dock_session_set.connect(on_request_dock_session_set);

        /* File manager control */
        global_sig.request_file_manager_command_set.connect(on_request_file_manager_command_set);
        global_sig.request_file_manager_session_set.connect(on_request_file_manager_session_set);
        global_sig.request_file_manager_extras_set.connect(on_request_file_manager_extras_set);

        /* Desktop control */
        global_sig.request_desktop_command_set.connect(on_request_desktop_command_set);
        global_sig.request_desktop_wallpaper_set.connect(on_request_desktop_wallpaper_set);

        /* Composite manager */
        global_sig.request_composite_manager_command_set.connect(on_request_composite_manager_command_set);
        global_sig.request_composite_manager_autostart_set.connect(on_request_composite_manager_autostart_set);

        /* Screensaver control */
        global_sig.request_screensaver_command_set.connect(on_request_screensaver_command_set);

        /* Power Manager control */
        global_sig.request_power_manager_command_set.connect(on_request_power_manager_command_set);

        /* Polkit agent control */
        global_sig.request_polkit_command_set.connect(on_request_polkit_command_set);

        /* Network gui control */
        global_sig.request_network_gui_command_set.connect(on_request_network_gui_command_set);

        /* Quit manager */
        global_sig.request_quit_manager_command_set.connect(on_request_quit_manager_command_set);
        global_sig.request_quit_manager_image_set.connect(on_request_quit_manager_image_set);
        global_sig.request_quit_manager_layout_set.connect(on_request_quit_manager_layout_set);

        /* Clipboard control */
        global_sig.request_clipboard_command_set.connect(on_request_clipboard_command_set);

        /* Keymap */
        global_sig.request_keymap_mode_set.connect(on_request_keymap_mode_set);
        global_sig.request_keymap_model_set.connect(on_request_keymap_model_set);
        global_sig.request_keymap_layout_set.connect(on_request_keymap_layout_set);
        global_sig.request_keymap_variant_set.connect(on_request_keymap_variant_set);
        global_sig.request_keymap_options_set.connect(on_request_keymap_options_set);

        /* Xrandr */
        global_sig.request_xrandr_mode_set.connect(on_request_xrandr_mode_set);
        global_sig.request_xrandr_command_set.connect(on_request_xrandr_command_set);

        /* Security */
        global_sig.request_security_keyring_set.connect(on_request_security_keyring_set);

        /* a11y */
        global_sig.request_a11y_type_set.connect(on_request_a11y_type_set);

        /* Updates */
        global_sig.request_updates_type_set.connect(on_request_updates_type_set);

        /* Monitor desktop file */
        setup_monitor_desktop_file();
    }

    public void setup_monitor_desktop_file()
    {
        try {
            desktop_file = File.new_for_path(desktop_config_path);
            monitor_desktop_file = desktop_file.monitor_file(GLib.FileMonitorFlags.NONE, monitor_cancel);
            monitor_desktop_file.changed.connect(on_desktop_file_change);
            message ("Monitoring: %s",desktop_config_path);

            if ( desktop_file.get_path() == get_config_home_path("desktop.conf"))
            {
                 message ("Desktop file is already in config home, do nothing");
            }
            else
            {
                message ("Desktop file is not in config home, monitoring creation of it");
                setup_creation_desktop_file();
            }

        } catch (GLib.Error err) {
            message (err.message);
        }
    }

    public void setup_creation_desktop_file()
    {
        try {
            home_desktop_file = File.new_for_path(get_config_home_path("desktop.conf"));
            monitor_home_desktop_file = home_desktop_file.monitor_file(GLib.FileMonitorFlags.NONE);
            monitor_home_desktop_file.changed.connect(on_desktop_file_creation);
            message ("Monitoring home path: %s", home_desktop_file.get_path());
        } catch (GLib.Error err) {
            message (err.message);
        }
    }

    public void on_desktop_file_change ()
    {
        read_keyfile();
        message("Desktop file change, reloading XSettings daemon");
        settings_daemon_reload(kf);
    }

    public void on_desktop_file_creation ()
    {
        message("Desktop file created in home directory, switch configuration to it");
        desktop_config_path = get_config_home_path("desktop.conf");
        monitor_cancel.cancel();

        read_keyfile();
        settings_daemon_reload(kf);
        setup_monitor_desktop_file();
    }

    public void read_keyfile()
    {
        kf = load_keyfile (get_config_path ("desktop.conf"));

        // Windows manager
        try
        {
            this.window_manager = kf.get_value ("Session", "window_manager");
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        try
        {
            this.windows_manager_command = kf.get_value ("Session", "windows_manager/command");
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        try
        {
            this.windows_manager_session = kf.get_value ("Session", "windows_manager/session");
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        try
        {
            this.windows_manager_extras = kf.get_value ("Session", "windows_manager/extras");
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Panel
        try
        {
            this.panel_command = kf.get_value ("Session", "panel/command");
            if (this.panel_command != null)
            {
                try
                {
                    this.panel_session = kf.get_value ("Session", "panel/session");
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

        // Dock
        try
        {
            this.dock_command = kf.get_value ("Session", "dock/command");
            if (this.dock_command != null)
            {
                try
                {
                    this.dock_session = kf.get_value ("Session", "dock/session");
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
            this.screensaver_command = kf.get_value ("Session", "screensaver/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Power manager
        try
        {
            this.power_manager_command = kf.get_value ("Session", "power_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Filemanager
        try
        {
            this.file_manager_command = kf.get_value ("Session", "file_manager/command");
            if (this.file_manager_command != null)
            {
                try
                {
                    this.file_manager_session = kf.get_value ("Session", "file_manager/session");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }

                try
                {
                    this.file_manager_extras = kf.get_value ("Session", "file_manager/extras");
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

        // Desktop handler
        try
        {
            this.desktop_command = kf.get_value ("Session", "desktop_manager/command");
            if (this.desktop_command != null)
            {
                try
                {
                    this.desktop_wallpaper = kf.get_value ("Session", "desktop_manager/wallpaper");
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
            this.polkit_command = kf.get_value("Session", "polkit/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Network GUI
        try
        {
            this.network_gui_command = kf.get_value("Session", "network_gui/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Audio Manager
        try
        {
            this.audio_manager_command = kf.get_value("Session", "audio_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Quit Manager
        try
        {
            this.quit_manager_command = kf.get_value("Session", "quit_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        try
        {
            this.quit_manager_image = kf.get_value("Session", "quit_manager/image");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        try
        {
            this.quit_manager_layout = kf.get_value("Session", "quit_manager/layout");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Workspace Manager
        try
        {
            this.workspace_manager_command = kf.get_value("Session", "workspace_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Launcher Manager
        try
        {
            this.launcher_manager_command = kf.get_value("Session", "launcher_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Terminal Manager
        try
        {
            this.terminal_manager_command = kf.get_value("Session", "terminal_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Screenshot Manager
        try
        {
            this.screenshot_manager_command = kf.get_value("Session", "screenshot_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Upgrade Manager
        try
        {
            this.upgrade_manager_command = kf.get_value("Session", "upgrade_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Composite Manager
        try
        {
            this.composite_manager_command = kf.get_value("Session", "composite_manager/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        try
        {
            this.composite_manager_autostart = kf.get_value("Session", "composite_manager/autostart");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Clipboard
        try
        {
            this.clipboard_command = kf.get_value("Session", "clipboard/command");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Disable autostart
        try
        {
            this.disable_autostart = kf.get_value("Session", "disable_autostart");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Upstart user session
        try
        {
            this.upstart_user_session = kf.get_value("Session", "upstart_user_session");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Laptop-mode
        try
        {
            this.laptop_mode = kf.get_value("State", "laptop_mode");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Dbus
        try
        {
            this.dbus_lxde = kf.get_value ("Dbus", "lxde");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        try
        {
            this.dbus_gnome = kf.get_value ("Dbus", "gnome");
        }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        // Keymap options
        try
        {
            this.keymap_mode = kf.get_value ("Keymap", "mode");
            if (this.keymap_mode != null)
            {
                try
                {
                    this.keymap_model = kf.get_value ("Keymap", "model");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }
                try
                {
                    this.keymap_layout = kf.get_value ("Keymap", "layout");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }
                try
                {
                    this.keymap_variant = kf.get_value ("Keymap", "variant");
                }
                catch (KeyFileError err)
                {
		            message (err.message);
                }
                try
                {
                    this.keymap_options = kf.get_value ("Keymap", "options");
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
            this.xrandr_mode = kf.get_value ("XRandr", "mode");
            if (this.xrandr_mode != null)
            {
                try
                {
                    this.xrandr_command = kf.get_value ("XRandr", "command");
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
            this.security_keyring = kf.get_value ("Security", "keyring");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }

        // a11y
	    try
        {
            this.a11y_type = kf.get_value ("a11y", "type");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }

        // Updates
	    try
        {
            this.updates_type = kf.get_value ("Updates", "type");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }

        // Environment
	    try
        {
            this.env_type = kf.get_value ("Environment", "type");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }

        // Environment
	    try
        {
            this.env_menu_prefix = kf.get_value ("Environment", "menu_prefix");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }

        // GTK
	    try
        {
            this.gtk_theme_name = kf.get_value ("GTK", "sNet/ThemeName");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_icon_theme_name = kf.get_value ("GTK", "sNet/IconThemeName");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_font_name = kf.get_value ("GTK", "sGtk/FontName");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_toolbar_style = kf.get_integer ("GTK", "iGtk/ToolbarStyle");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_button_images = kf.get_integer ("GTK", "iGtk/ButtonImages");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_menu_images = kf.get_integer ("GTK", "iGtk/MenuImages");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_cursor_theme_size = kf.get_integer ("GTK", "iGtk/CursorThemeSize");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_antialias = kf.get_integer ("GTK", "iXft/Antialias");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_hinting = kf.get_integer ("GTK", "iXft/Hinting");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_hint_style = kf.get_value ("GTK", "sXft/HintStyle");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_rgba = kf.get_value ("GTK", "sXft/RGBA");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_color_scheme = kf.get_value ("GTK", "sGtk/ColorScheme");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_cursor_theme_name = kf.get_value ("GTK", "sGtk/CursorThemeName");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_toolbar_icon_size = kf.get_integer ("GTK", "iGtk/ToolbarIconSize");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_enable_event_sounds = kf.get_integer ("GTK", "iNet/EnableEventSounds");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.gtk_enable_input_feedback_sounds = kf.get_integer ("GTK", "iNet/EnableInputFeedbackSounds");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }

        // Mouse
	    try
        {
            this.mouse_acc_factor = kf.get_integer ("Mouse", "AccFactor");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.mouse_acc_threshold = kf.get_integer ("Mouse", "AccThreshold");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.mouse_left_handed = kf.get_integer ("Mouse", "LeftHanded");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }

        // Keyboard
	    try
        {
            this.keyboard_delay = kf.get_integer ("Keyboard", "Delay");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.keyboard_interval = kf.get_integer ("Keyboard", "Interval");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
	    try
        {
            this.keyboard_beep = kf.get_integer ("Keyboard", "Beep");
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
    }

    public void sync_setting_files ()
    {
        string desktop_file = get_config_home_path("desktop.conf");
        if (FileUtils.test (desktop_file, FileTest.EXISTS))
        {
            string autostart_file = get_config_home_path("autostart");
            if (FileUtils.test (autostart_file, FileTest.EXISTS))
            {
                /* File in sync, nothing to do */
            }
            else
            {
                var file = File.new_for_path (get_config_path("autostart"));
                var destination = File.new_for_path (get_config_home_path("autostart"));
                try
                {
                    file.copy (destination, FileCopyFlags.NONE);
                }
                catch (GLib.Error err)
                {
		            message (err.message);
                }
            }
        }
    }

    public void save_keyfile ()
    {
        message ("Saving desktop file");
        var str = kf.to_data (null);
        try
        {
            FileUtils.set_contents (desktop_config_path, str, str.length);
        }
        catch (FileError err)
        {
            warning (err.message);
            try
            {
                /* Try to save on user config directory */
                string user_config_dir = get_config_home_path("desktop.conf");

                File file_parent;
                var file = File.new_for_path(user_config_dir);
                file_parent = file.get_parent();
                if (!file_parent.query_exists())
                {
                    try
                    {
                        file_parent.make_directory_with_parents();
                    }
                    catch (GLib.Error err)
                    {
                        warning (err.message);
                    }
                }

                FileUtils.set_contents (user_config_dir, str, str.length);
                desktop_config_path = user_config_dir;
                setup_monitor_desktop_file();
                sync_setting_files ();
            }
            catch (FileError err)
            {
                warning (err.message);
            }
        }

    }

    /* Compatibility for windows manager settings */
    public void on_update_window_manager (string dbus_arg)
    {
        message("Changing window manager: %s", dbus_arg);
        this.window_manager = dbus_arg;
        kf.set_value ("Session", "window_manager", this.window_manager);
        save_keyfile();
    }

    public void on_update_composite_manager_command (string dbus_arg)
    {
        message("Changing composite manager command: %s", dbus_arg);
        this.composite_manager_command = dbus_arg;
        kf.set_value ("Session", "composite_manager/command", this.composite_manager_command);
        save_keyfile();
    }

    public void on_update_composite_manager_autostart (string dbus_arg)
    {
        message("Changing composite manager autostart: %s", dbus_arg);
        this.composite_manager_autostart = dbus_arg;
        kf.set_value ("Session", "composite_manager/autostart", this.composite_manager_autostart);
        save_keyfile();
    }

    public void on_update_disable_autostart (string dbus_arg)
    {
        message("Changing disable autostart option: %s", dbus_arg);
        this.disable_autostart = dbus_arg;
        kf.set_value ("Session", "disable_autostart", this.disable_autostart);
        save_keyfile();
    }

    public void on_update_upstart_user_session (string dbus_arg)
    {
        message("Changing upstart user session option: %s", dbus_arg);
        this.upstart_user_session = dbus_arg;
        kf.set_value ("Session", "upstart_user_session", this.upstart_user_session);
        save_keyfile();
    }

    public void on_update_env_type (string dbus_arg)
    {
        message("Changing envrionment type: %s", dbus_arg);
        this.env_type = dbus_arg;
        kf.set_value ("Environment", "type", this.env_type);
        save_keyfile();
    }

    public void on_update_env_menu_prefix (string dbus_arg)
    {
        message("Changing envrionment menu prefix: %s", dbus_arg);
        this.env_menu_prefix = dbus_arg;
        kf.set_value ("Environment", "menu_prefix", this.env_menu_prefix);
        save_keyfile();
    }

    public void on_update_gtk_theme_name (string dbus_arg)
    {
        message("Changing gtk_theme_name: %s", dbus_arg);
        this.gtk_theme_name = dbus_arg;
        kf.set_value ("GTK", "sNet/ThemeName", this.gtk_theme_name);
        save_keyfile();
    }


    public void on_update_gtk_icon_theme_name (string dbus_arg)
    {
        message("Changing gtk_icon_theme_name: %s", dbus_arg);
        this.gtk_icon_theme_name = dbus_arg;
        kf.set_value ("GTK", "sNet/IconThemeName", this.gtk_icon_theme_name);
        save_keyfile();
    }

    public void on_update_gtk_font_name (string dbus_arg)
    {
        message("Changing gtk_font_name: %s", dbus_arg);
        this.gtk_font_name = dbus_arg;
        kf.set_value ("GTK", "sGtk/FontName", this.gtk_font_name);
        save_keyfile();
    }

    public void on_update_gtk_toolbar_style (int dbus_arg)
    {
        message("Changing gtk_font_name: %i", dbus_arg);
        this.gtk_toolbar_style = dbus_arg;
        kf.set_integer ("GTK", "iGtk/ToolbarStyle", this.gtk_toolbar_style);
        save_keyfile();
    }

    public void on_update_gtk_button_images (int dbus_arg)
    {
        message("Changing gtk_button_images: %i", dbus_arg);
        this.gtk_button_images = dbus_arg;
        kf.set_integer ("GTK", "iGtk/ButtonImages", this.gtk_button_images);
        save_keyfile();
    }

    public void on_update_gtk_menu_images (int dbus_arg)
    {
        message("Changing gtk_menu_images: %i", dbus_arg);
        this.gtk_menu_images = dbus_arg;
        kf.set_integer ("GTK", "iGtk/MenuImages", this.gtk_menu_images);
        save_keyfile();
    }

    public void on_update_gtk_cursor_theme_size (int dbus_arg)
    {
        message("Changing gtk_cursor_theme_size: %i", dbus_arg);
        this.gtk_cursor_theme_size = dbus_arg;
        kf.set_integer ("GTK", "iGtk/CursorThemeSize", this.gtk_cursor_theme_size);
        save_keyfile();
    }

    public void on_update_gtk_antialias (int dbus_arg)
    {
        message("Changing gtk_antialias: %i", dbus_arg);
        this.gtk_antialias = dbus_arg;
        kf.set_integer ("GTK", "iXft/Antialias", this.gtk_antialias);
        save_keyfile();
    }

    public void on_update_gtk_hinting (int dbus_arg)
    {
        message("Changing gtk_hinting: %i", dbus_arg);
        this.gtk_hinting = dbus_arg;
        kf.set_integer ("GTK", "iXft/Hinting", this.gtk_hinting);
        save_keyfile();
    }

    public void on_update_gtk_hint_style (string dbus_arg)
    {
        message("Changing gtk_hint_style: %s", dbus_arg);
        this.gtk_hint_style = dbus_arg;
        kf.set_value ("GTK", "sXft/HintStyle", this.gtk_hint_style);
        save_keyfile();
    }

    public void on_update_gtk_rgba (string dbus_arg)
    {
        message("Changing gtk_rgba: %s", dbus_arg);
        this.gtk_rgba = dbus_arg;
        kf.set_value ("GTK", "sXft/RGBA", this.gtk_rgba);
        save_keyfile();
    }

    public void on_update_gtk_color_scheme (string dbus_arg)
    {
        message("Changing gtk_color_scheme: %s", dbus_arg);
        this.gtk_color_scheme = dbus_arg;
        kf.set_value ("GTK", "sGtk/ColorScheme", this.gtk_color_scheme);
        save_keyfile();
    }

    public void on_update_gtk_cursor_theme_name (string dbus_arg)
    {
        message("Changing gtk_cursor_theme_name: %s", dbus_arg);
        this.gtk_cursor_theme_name = dbus_arg;
        kf.set_value ("GTK", "sGtk/CursorThemeName", this.gtk_cursor_theme_name);
        save_keyfile();
    }

    public void on_update_gtk_toolbar_icon_size (int dbus_arg)
    {
        message("Changing gtk_cursor_theme_name: %i", dbus_arg);
        this.gtk_toolbar_icon_size = dbus_arg;
        kf.set_integer ("GTK", "iGtk/ToolbarIconSize", this.gtk_toolbar_icon_size);
        save_keyfile();
    }

    public void on_update_gtk_enable_event_sounds (int dbus_arg)
    {
        message("Changing gtk_enable_event_sounds: %i", dbus_arg);
        this.gtk_enable_event_sounds = dbus_arg;
        kf.set_integer ("GTK", "iNet/EnableEventSounds", this.gtk_enable_event_sounds);
        save_keyfile();
    }

    public void on_update_gtk_enable_input_feedback_sounds (int dbus_arg)
    {
        message("Changing gtk_enable_input_feedback_sounds: %i", dbus_arg);
        this.gtk_enable_input_feedback_sounds = dbus_arg;
        kf.set_integer ("GTK", "iNet/EnableInputFeedbackSounds", this.gtk_enable_input_feedback_sounds);
        save_keyfile();
    }

    public void on_update_mouse_acc_factor (int dbus_arg)
    {
        message("Changing mouse_acc_factor: %i", dbus_arg);
        this.mouse_acc_factor = dbus_arg;
        kf.set_integer ("Mouse", "AccFactor", this.mouse_acc_factor);
        save_keyfile();
    }

    public void on_update_mouse_acc_threshold (int dbus_arg)
    {
        message("Changing mouse_acc_threshold: %i", dbus_arg);
        this.mouse_acc_threshold = dbus_arg;
        kf.set_integer ("Mouse", "AccThreshold", this.mouse_acc_threshold);
        save_keyfile();
    }

    public void on_update_mouse_left_handed (int dbus_arg)
    {
        message("Changing mouse_left_handed: %i", dbus_arg);
        this.mouse_left_handed = dbus_arg;
        kf.set_integer ("Mouse", "LeftHanded", this.mouse_left_handed);
        save_keyfile();
    }

    public void on_update_keyboard_delay (int dbus_arg)
    {
        message("Changing keyboard_delay: %i", dbus_arg);
        this.keyboard_delay = dbus_arg;
        kf.set_integer ("Keyboard", "Delay", this.keyboard_delay);
        save_keyfile();
    }

    public void on_update_keyboard_interval (int dbus_arg)
    {
        message("Changing keyboard_interval: %i", dbus_arg);
        this.keyboard_interval = dbus_arg;
        kf.set_integer ("Keyboard", "Interval", this.keyboard_interval);
        save_keyfile();
    }

    public void on_update_keyboard_beep (int dbus_arg)
    {
        message("Changing keyboard_beep: %i", dbus_arg);
        this.keyboard_beep = dbus_arg;
        kf.set_integer ("Keyboard", "Beep", this.keyboard_beep);
        save_keyfile();
    }

    public void on_update_laptop_mode (string mode)
    {
        message("Changing laptop mode");
        this.laptop_mode = mode;
        kf.set_value ("State", "laptop_mode", this.laptop_mode);
        save_keyfile();
    }

    public void on_reload_settings_daemon ()
    {
        message("Reloading XSettings daemon");
        settings_daemon_reload(kf);
    }

    public void on_request_audio_manager_command_set (string manager)
    {
        message("Changing Audio Manager command");
        this.audio_manager_command = manager;
        kf.set_value ("Session", "audio_manager/command", this.audio_manager_command);
        save_keyfile();
    }

    public void on_request_quit_manager_command_set (string manager)
    {
        message("Changing Quit Manager command");
        this.quit_manager_command = manager;
        kf.set_value ("Session", "quit_manager/command", this.quit_manager_command);
        save_keyfile();
    }

    public void on_request_quit_manager_image_set (string manager)
    {
        message("Changing Quit Manager image");
        this.quit_manager_image = manager;
        kf.set_value ("Session", "quit_manager/image", this.quit_manager_image);
        save_keyfile();
    }

    public void on_request_quit_manager_layout_set (string manager)
    {
        message("Changing Quit Manager layout");
        this.quit_manager_layout = manager;
        kf.set_value ("Session", "quit_manager/layout", this.quit_manager_layout);
        save_keyfile();
    }

    public void on_request_workspace_manager_command_set (string manager)
    {
        message("Changing Workspace Manager command");
        this.workspace_manager_command = manager;
        kf.set_value ("Session", "workspace_manager/command", this.workspace_manager_command);
        save_keyfile();
    }

    public void on_request_launcher_manager_command_set (string manager)
    {
        message("Changing Launcher Manager command");
        this.launcher_manager_command = manager;
        kf.set_value ("Session", "launcher_manager/command", this.launcher_manager_command);
        save_keyfile();
    }

    public void on_request_terminal_manager_command_set (string manager)
    {
        message("Changing Terminal Manager command");
        this.terminal_manager_command = manager;
        kf.set_value ("Session", "terminal_manager/command", this.terminal_manager_command);
        save_keyfile();
    }

    public void on_request_screenshot_manager_command_set (string manager)
    {
        message("Changing Screenshot Manager command");
        this.screenshot_manager_command = manager;
        kf.set_value ("Session", "screenshot_manager/command", this.screenshot_manager_command);
        save_keyfile();
    }

    public void on_request_upgrade_manager_command_set (string manager)
    {
        message("Changing Upgrade Manager command");
        this.upgrade_manager_command = manager;
        kf.set_value ("Session", "upgrade_manager/command", this.upgrade_manager_command);
        save_keyfile();
    }

    /* Windows manager control */
    public void on_request_windows_manager_command_set (string manager)
    {
        message("Changing windows manager command");
        this.windows_manager_command = manager;
        kf.set_value ("Session", "windows_manager/command", this.windows_manager_command);
        save_keyfile();
    }

    public void on_request_windows_manager_session_set (string manager)
    {
        message("Changing windows manager session");
        this.windows_manager_session = manager;
        kf.set_value ("Session", "windows_manager/session", this.windows_manager_session);
        save_keyfile();
    }

    public void on_request_windows_manager_extras_set (string manager)
    {
        message("Changing windows manager extras");
        this.windows_manager_extras = manager;
        kf.set_value ("Session", "windows_manager/extras", this.windows_manager_extras);
        save_keyfile();
    }

    /* Panel control */
    public void on_request_panel_command_set (string manager)
    {
        message("Changing panel command");
        this.panel_command = manager;
        kf.set_value ("Session", "panel/command", this.panel_command);
        save_keyfile();
    }

    public void on_request_panel_session_set (string manager)
    {
        message("Changing panel session");
        this.panel_session = manager;
        kf.set_value ("Session", "panel/session", this.panel_session);
        save_keyfile();
    }

    /* Dock control */
    public void on_request_dock_command_set (string manager)
    {
        message("Changing dock command");
        this.dock_command = manager;
        kf.set_value ("Session", "dock/command", this.dock_command);
        save_keyfile();
    }

    public void on_request_dock_session_set (string manager)
    {
        message("Changing dock session");
        this.dock_session = manager;
        kf.set_value ("Session", "dock/session", this.dock_session);
        save_keyfile();
    }

    /* File manager control */
    public void on_request_file_manager_command_set (string manager)
    {
        message("Changing file manager command");
        this.file_manager_command = manager;
        kf.set_value ("Session", "file_manager/command", this.file_manager_command);
        save_keyfile();
    }

    public void on_request_file_manager_session_set (string manager)
    {
        message("Changing file manager session");
        this.file_manager_session = manager;
        kf.set_value ("Session", "file_manager/session", this.file_manager_session);
        save_keyfile();
    }

    public void on_request_file_manager_extras_set (string manager)
    {
        message("Changing file manager extras");
        this.file_manager_extras = manager;
        kf.set_value ("Session", "file_manager/extras", this.file_manager_extras);
        save_keyfile();
    }

    /* Desktop control */
    public void on_request_desktop_command_set (string manager)
    {
        message("Changing desktop command");
        this.desktop_command = manager;
        kf.set_value ("Session", "desktop_manager/command", this.desktop_command);
        save_keyfile();
    }

    public void on_request_desktop_wallpaper_set (string manager)
    {
        message("Changing desktop command");
        this.desktop_wallpaper = manager;
        kf.set_value ("Session", "desktop_manager/wallpaper", this.desktop_wallpaper);
        save_keyfile();
    }

    /* Composite manager */
    public void on_request_composite_manager_command_set (string manager)
    {
        message("Changing Composite Manager command");
        this.composite_manager_command = manager;
        kf.set_value ("Session", "composite_manager/command", this.composite_manager_command);
        save_keyfile();
    }

    public void on_request_composite_manager_autostart_set (string manager)
    {
        message("Changing Composite Manager autostart");
        this.composite_manager_autostart = manager;
        kf.set_value ("Session", "composite_manager/autostart", this.composite_manager_autostart);
        save_keyfile();
    }

    /* Screensaver manager */
    public void on_request_screensaver_command_set (string manager)
    {
        message("Changing Screensaver command");
        this.screensaver_command = manager;
        kf.set_value ("Session", "screensaver/command", this.screensaver_command);
        save_keyfile();
    }

    /* Power Manager */
    public void on_request_power_manager_command_set (string manager)
    {
        message("Changing power manager command");
        this.power_manager_command = manager;
        kf.set_value ("Session", "power_manager/command", this.power_manager_command);
        save_keyfile();
    }

    /* Polkit agent */
    public void on_request_polkit_command_set (string manager)
    {
        message("Changing polkit command");
        this.polkit_command = manager;
        kf.set_value ("Session", "polkit/command", this.polkit_command);
        save_keyfile();
    }

    /* Network gui */
    public void on_request_network_gui_command_set (string manager)
    {
        message("Changing network gui command");
        this.network_gui_command = manager;
        kf.set_value ("Session", "network_gui/command", this.network_gui_command);
        save_keyfile();
    }

    /* Clipboard */
    public void on_request_clipboard_command_set (string manager)
    {
        message("Changing clipboard command");
        this.clipboard_command = manager;
        kf.set_value ("Session", "clipboard/command", this.clipboard_command);
        save_keyfile();
    }

    /* Keymap */
    public void on_request_keymap_mode_set (string manager)
    {
        message("Changing keymap mode");
        this.keymap_mode = manager;
        kf.set_value ("Keymap", "mode", this.keymap_mode);
        save_keyfile();
    }

    public void on_request_keymap_model_set (string manager)
    {
        message("Changing keymap model");
        this.keymap_model = manager;
        kf.set_value ("Keymap", "model", this.keymap_model);
        save_keyfile();
    }

    public void on_request_keymap_layout_set (string manager)
    {
        message("Changing keymap layout");
        this.keymap_layout = manager;
        kf.set_value ("Keymap", "layout", this.keymap_layout);
        save_keyfile();
    }

    public void on_request_keymap_variant_set (string manager)
    {
        message("Changing keymap variant");
        this.keymap_variant = manager;
        kf.set_value ("Keymap", "variant", this.keymap_variant);
        save_keyfile();
    }

    public void on_request_keymap_options_set (string manager)
    {
        message("Changing keymap options");
        this.keymap_options = manager;
        kf.set_value ("Keymap", "options", this.keymap_options);
        save_keyfile();
    }

    /* Xrandr */
    public void on_request_xrandr_mode_set (string manager)
    {
        message("Changing xrandr mode");
        this.xrandr_mode = manager;
        kf.set_value ("XRandr", "mode", this.xrandr_mode);
        save_keyfile();
    }

    public void on_request_xrandr_command_set (string manager)
    {
        message("Changing xrandr command");
        this.xrandr_command = manager;
        kf.set_value ("XRandr", "command", this.xrandr_command);
        save_keyfile();
    }

    /* Keyring */
    public void on_request_security_keyring_set (string manager)
    {
        message("Changing security keyring");
        this.security_keyring = manager;
        kf.set_value ("Security", "keyring", this.security_keyring);
        save_keyfile();
    }

    /* a11y */
    public void on_request_a11y_type_set (string manager)
    {
        message("Changing a11y type");
        this.a11y_type = manager;
        kf.set_value ("a11y", "type", this.a11y_type);
        save_keyfile();
    }

    /* Updates */
    public void on_request_updates_type_set (string manager)
    {
        message("Changing updates type");
        this.updates_type = manager;
        kf.set_value ("Updates", "type", this.updates_type);
        save_keyfile();
    }

}

}
