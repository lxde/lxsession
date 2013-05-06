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
    [DBus(name = "org.lxde.SessionManager")]
    public class LxdeSessionServer : Object
    {
        /* Systeme & Session */
        public void Shutdown()
        {
            var session = new SessionObject();
            session.lxsession_shutdown();
        }
        public async void CanShutdown(out bool is_available)
        {
            var session = new SessionObject();
            is_available = yield session.lxsession_can_shutdown();
        }

        public void RequestShutdown()
        {
            var session = new SessionObject();
            session.lxsession_shutdown();
        }

        public void RequestReboot()
        {
            var session = new SessionObject();
            session.lxsession_restart();
        }

        public void Logout()
        {
            var session = new SessionObject();
            session.lxsession_restart();
        }

        public void ReloadSettingsDaemon()
        {
            message ("Restart Xsettings Deamon");
            global_sig.reload_settings_daemon();
        }

        /* Audio Manager */
        public void AudioManagerGet(out string command)
        {
            command = global_settings.audio_manager;
            message ("Get audio manager: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void AudioManagerSet(string command)
        {
            message ("Set audio manager to :%s", command);
            global_sig.request_audio_manager_set(command);
        }

        public void AudioManagerLaunch()
        {
            message ("Launch audio manager");
            if (global_settings.audio_manager == null)
            {
                warning("Audio manager not set");
            }
            else if (global_audio_manager == null)
            {
                var audio = new AudioManagerApp();
                global_audio_manager = audio;
                global_audio_manager.launch();
            }
            else
            {
                global_audio_manager.launch();
            }
        }

        /* Quit Manager */
        public void QuitManagerCommandGet(out string command)
        {
            command = global_settings.quit_manager_command;
            message ("Get quit manager command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void QuitManagerCommandSet(string command)
        {
            message ("Set quit manager command to :%s", command);
            global_sig.request_quit_manager_command_set(command);
        }

        public void QuitManagerImageGet(out string command)
        {
            command = global_settings.quit_manager_image;
            message ("Get quit manager image: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void QuitManagerImageSet(string command)
        {
            message ("Set quit manager image to :%s", command);
            global_sig.request_quit_manager_image_set(command);
        }

        public void QuitManagerLayoutGet(out string command)
        {
            command = global_settings.quit_manager_layout;
            message ("Get quit manager layout: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void QuitManagerlayoutSet(string command)
        {
            message ("Set quit manager layout to :%s", command);
            global_sig.request_quit_manager_layout_set(command);
        }

        public void QuitManagerLaunch()
        {
            message("Start Quit Manager");
            if (global_settings.quit_manager_command == null)
            {
                warning("Quit manager command not set");
            }
            else if (global_quit_manager == null)
            {
                var quit = new QuitManagerApp();
                global_quit_manager = quit;
                global_quit_manager.launch();
            }
            else
            {
                global_quit_manager.launch();              
            }
        }

        /* Workspace Manager */
        public void WorkspaceManagerGet(out string command)
        {
            command = global_settings.workspace_manager;
            message ("Get workspace manager: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void WorkspaceManagerSet(string command)
        {
            message ("Set workspace manager to :%s", command);
            global_sig.request_workspace_manager_set(command);
        }
        public void WorkspaceManagerLaunch()
        {
            message("Start Workspace Manager");
            if (global_settings.workspace_manager == null)
            {
                warning("Workspace manager not set");
            }
            else if (global_workspace_manager == null)
            {
                var workspace = new WorkspaceManagerApp();
                global_workspace_manager = workspace;
                global_workspace_manager.launch();
            }
            else
            {
                global_workspace_manager.launch();                
            }
        }

        /* Launcher manager */
        public void LauncherManagerGet(out string command)
        {
            command = global_settings.launcher_manager;
            message ("Get launcher manager: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void LauncherManagerSet(string command)
        {
            message ("Set launcher manager to :%s", command);
            global_sig.request_launcher_manager_set(command);
        }
        public void LauncherManagerLaunch()
        {
            message("Start Launcher Manager");
            if (global_settings.launcher_manager == null)
            {
                warning("Launcher manager not set");
            }
            else if (global_launcher_manager == null)
            {
                var launcher = new LauncherManagerApp();
                global_launcher_manager = launcher;
                global_launcher_manager.launch();
            }
            else
            {
                global_launcher_manager.launch();
            }
        }

        /* Terminal Manager */
        public void TerminalManagerGet(out string command)
        {
            command = global_settings.terminal_manager;
            message ("Get terminal manager: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void TerminalManagerSet(string command)
        {
            message ("Set Terminal manager to :%s", command);
            global_sig.request_terminal_manager_set(command);
        }

        public void TerminalManagerLaunch()
        {
            message("Start Terminal Manager");
            if (global_settings.terminal_manager == null)
            {
                warning("Terminal manager not set");
            }
            else if (global_terminal_manager == null)
            {
                var terminal = new TerminalManagerApp();
                global_terminal_manager = terminal;
                global_terminal_manager.launch();
            }
            else
            {
                global_terminal_manager.launch();
            }
        }

        /* Screenshot manager */
        public void ScreenshotManagerGet(out string command)
        {
            command = global_settings.screenshot_manager;
            message ("Get screenshot manager: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void ScreenshotManagerSet(string command)
        {
            message ("Set screenshot manager to :%s", command);
            global_sig.request_screenshot_manager_set(command);
        }

        public void ScreenshotManagerLaunch()
        {
            message("Start Screenshot Manager");
            if (global_settings.screenshot_manager == null)
            {
                warning("Screenshot manager not set");
            }
            else if (global_screenshot_manager == null)
            {
                var screenshot = new ScreenshotManagerApp();
                global_screenshot_manager = screenshot;
                global_screenshot_manager.launch();
            }
            else
            {
                global_screenshot_manager.launch();
            }
        }

        public void ScreenshotWindowManagerLaunch()
        {
            message("Start Screenshot Window Manager");
            if (global_settings.screenshot_manager == null)
            {
                warning("Screenshot manager not set");
            }
            else if (global_screenshot_manager == null)
            {
                var screenshot = new ScreenshotManagerApp();
                global_screenshot_manager = screenshot;
                global_screenshot_manager.window_launch();
            }
            else
            {
                global_screenshot_manager.window_launch();
            }
        }

        /* Upgrades manager */
        public void UpgradesManagerGet(out string command)
        {
            command = global_settings.upgrades_manager;
            message ("Get upgrades manager: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void UpgradesManagerSet(string command)
        {
            message ("Set upgrades manager to :%s", command);
            global_sig.request_upgrades_manager_set(command);
        }

        public void UpgradesManagerLaunch()
        {
            message("Start Upgrades Manager");
            if (global_settings.upgrades_manager == null)
            {
                warning("Upgrades manager not set");
            }
            else if (global_upgrades_manager == null)
            {
                var upgrades = new UpgradesManagerApp();
                global_upgrades_manager = upgrades;
                global_upgrades_manager.launch();
            }
            else
            {
                global_upgrades_manager.launch();
            }
        }

        /* Composite manager */
        public void CompositeManagerCommandGet(out string command)
        {
            command = global_settings.composite_manager_command;
            message ("Get composite manager: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void CompositeManagerCommandSet(string command)
        {
            message ("Set composite manager to :%s", command);
            global_sig.request_composite_manager_command_set(command);
        }

        public void CompositeManagerAutostartGet(out string command)
        {
            command = global_settings.composite_manager_autostart;
            message ("Get composite manager: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void CompositeManagerAutostartSet(string command)
        {
            message ("Set composite manager to :%s", command);
            global_sig.request_composite_manager_autostart_set(command);
        }

        public void CompositeManagerReload()
        {
            message("Reload composite manager");
            if (global_settings.composite_manager_command == null)
            {
                warning("composite manager not set not set");
            }
            else if (global_composite_manager == null)
            {
                message("Composite manager doesn't exist, creating it");
                var composite = new CompositeManagerApp();
                global_composite_manager = composite;
                global_composite_manager.launch();
            }
            else
            {
                message("Reload existing composite manager");
                global_composite_manager.reload();
            }
        }

        /* Filemanager control */
        public void FilemanagerCommandGet(out string command)
        {
            command = global_settings.file_manager_command;
            message ("Get file manager command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void FilemanagerCommandSet(string command)
        {
            message ("Set file manager command to :%s", command);
            global_sig.request_file_manager_command_set(command);
        }

        public void FilemanagerSessionGet(out string command)
        {
            command = global_settings.file_manager_session;
            message ("Get file manager session: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void FilemanagerSessionSet(string command)
        {
            message ("Set file manager session to :%s", command);
            global_sig.request_file_manager_session_set(command);
        }

        public void FilemanagerExtrasGet(out string command)
        {
            command = global_settings.file_manager_extras;
            message ("Get file manager extras: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void FilemanagerExtrasSet(string command)
        {
            message ("Set file manager extras to :%s", command);
            global_sig.request_file_manager_extras_set(command);
        }

        public void FilemanagerReload()
        {
            message("Reload Filemanager");
            if (global_settings.file_manager_command == null)
            {
                warning("File manager not set");
            }
            else if (global_file_manager == null)
            {
                message("File manager doesn't exist, creating it");
                var filemanager = new FileManagerApp();
                global_file_manager = filemanager;
                global_file_manager.launch();
            }
            else
            {
                message("Reload existing file manager");
                global_file_manager.reload();
            }
        }

        /* Panel control */
        public void PanelCommandGet(out string command)
        {
            command = global_settings.panel_program;
            message ("Get panel command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void PanelCommandSet(string command)
        {
            message ("Set panel command to :%s", command);
            global_sig.request_panel_program_set(command);
        }

        public void PanelSessionGet(out string command)
        {
            command = global_settings.panel_session;
            message ("Get panel session: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void PanelSessionSet(string command)
        {
            message ("Set panel command to :%s", command);
            global_sig.request_panel_session_set(command);
        }

        public void PanelReload()
        {
            message("Reload panel");
            if (global_settings.panel_program == null)
            {
                warning("Panel not set");
            }
            else if (global_panel == null)
            {
                message("Panel doesn't exist, creating it");
                var panelprogram = new PanelApp();
                global_panel = panelprogram;
                global_panel.launch();
            }
            else
            {
                message("Reload existing panel");
                global_panel.reload();
            }
        }

        /* Dock control */
        public void DockCommandGet(out string command)
        {
            command = global_settings.dock_program;
            message ("Get dock command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void DockCommandSet(string command)
        {
            message ("Set dock command to :%s", command);
            global_sig.request_dock_program_set(command);
        }

        public void DockSessionGet(out string command)
        {
            command = global_settings.dock_session;
            message ("Get dock session: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void DockSessionSet(string command)
        {
            message ("Set dock command to :%s", command);
            global_sig.request_dock_session_set(command);
        }

        public void DockReload()
        {
            message("Reload dock");
            if (global_settings.dock_program == null)
            {
                warning("Dock not set");
            }
            else if (global_dock == null)
            {
                message("Dock doesn't exist, creating it");
                var dockprogram = new DockApp();
                global_dock = dockprogram;
                global_dock.launch();
            }
            else
            {
                message("Reload existing dock");
                global_dock.reload();
            }
        }

        /* Windows Manager control */
        public void WindowsManagerCommandGet(out string command)
        {
            command = global_settings.windows_manager_command;
            message ("Get windows manager command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void WindowsManagerCommandSet(string command)
        {
            message ("Set windows manager command to :%s", command);
            global_sig.request_windows_manager_command_set(command);
        }

        public void WindowsManagerSessionGet(out string command)
        {
            command = global_settings.windows_manager_session;
            message ("Get windows manager session: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void WindowsManagerSessionSet(string command)
        {
            message ("Set windows manager session to :%s", command);
            global_sig.request_windows_manager_session_set(command);
        }

        public void WindowsManagerExtrasGet(out string command)
        {
            command = global_settings.windows_manager_extras;
            message ("Get windows manager extras: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void WindowsManagerExtrasSet(string command)
        {
            message ("Set windows manager extras to :%s", command);
            global_sig.request_windows_manager_extras_set(command);
        }

        public void WindowsManagerReload()
        {
            message("Reload Windows Manager");
            if (global_settings.windows_manager_command == null)
            {
                warning("Windows manager not set");
            }
            else if (global_windows_manager == null)
            {
                message("Windows manager doesn't exist, creating it");
                var windowsmanager = new WindowsManagerApp();
                global_windows_manager = windowsmanager;
                global_windows_manager.launch();
            }
            else
            {
                message("Reload existing windows manager");
                global_windows_manager.reload();
            }
        }

        /* Desktop manager */
        public void DesktopCommandGet(out string command)
        {
            command = global_settings.desktop_command;
            message ("Get desktop command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void DesktopCommandSet(string command)
        {
            message ("Set desktop command to :%s", command);
            global_sig.request_desktop_command_set(command);
        }

        public void DesktopWallpaperGet(out string command)
        {
            command = global_settings.desktop_wallpaper;
            message ("Get desktop wallpaper: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void DesktopWallpaperSet(string command)
        {
            message ("Set desktop wallpaper to :%s", command);
            global_sig.request_desktop_wallpaper_set(command);
        }

        public void DesktopReload()
        {
            message("Reload desktop manager");
            if (global_settings.desktop_command == null)
            {
                warning("desktop manager not set");
            }
            else if (global_desktop == null)
            {
                message("Desktop manager doesn't exist, creating it");
                var desktop = new DesktopApp();
                global_desktop = desktop;
                global_desktop.launch();
            }
            else
            {
                message("Reload existing desktop manager");
                global_desktop.reload();
            }
        }

        /* Screensaver */
        public void ScreensaverCommandGet(out string command)
        {
            command = global_settings.screensaver_command;
            message ("Get screensavercommand: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void ScreensaverCommandSet(string command)
        {
            message ("Set screensaver command to :%s", command);
            global_sig.request_screensaver_command_set(command);
        }

        public void ScreensaverReload()
        {
            message("Reload screensaver");
            if (global_settings.screensaver_command == null)
            {
                warning("screensaver command not set");
            }
            else if (global_screensaver == null)
            {
                message("Screensaver doesn't exist, creating it");
                var screensaver = new ScreensaverApp();
                global_screensaver = screensaver;
                global_screensaver.launch();
            }
            else
            {
                message("Reload existing screensaver");
                global_screensaver.reload();
            }
        }

        /* Power Manager */
        public void PowerManagerCommandGet(out string command)
        {
            command = global_settings.power_manager_command;
            message ("Get power manager command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void PowerManagerCommandSet(string command)
        {
            message ("Set power manager command to :%s", command);
            global_sig.request_power_manager_command_set(command);
        }

        public void PowerManagerReload()
        {
            message("Reload power manager");
            if (global_settings.power_manager_command == null)
            {
                warning("Power manager command not set");
            }
            else if (global_power_manager == null)
            {
                message("Power Manager doesn't exist, creating it");
                var powermanager = new PowerManagerApp();
                global_power_manager = powermanager;
                global_power_manager.launch();
            }
            else
            {
                message("Reload existing power manager");
                global_power_manager.reload();
            }
        }

        /* Polkit */
        public void PolkitCommandGet(out string command)
        {
            command = global_settings.polkit_command;
            message ("Get polkit command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void PolkitCommandSet(string command)
        {
            message ("Set polkit command to :%s", command);
            global_sig.request_polkit_command_set(command);
        }

        public void PolkitReload()
        {
            message("Reload polkit");
            if (global_settings.polkit_command == null)
            {
                warning("Polkit command not set");
            }
            else if (global_polkit == null)
            {
                message("Polkit doesn't exist, creating it");
                var polkit = new PolkitApp();
                global_polkit = polkit;
                global_polkit.launch();
            }
            else
            {
                message("Reload existing polkit");
                global_polkit.reload();
            }
        }

        /* Upstart user session */
        public void UpstartUserSessionGet(out string command)
        {
            command = global_settings.upstart_user_session;
            message ("Get upstart user session: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void UpstartUserSessionSet(string command)
        {
            message ("Set upstart user session:%s", command);
            global_sig.request_upstart_user_session_set(command);
        }

        /* TODO Triage this mess */
        public void UpdatesActivate (string dbus_arg)
        {
            message ("Signal updates activate option: %s", dbus_arg);
            global_sig.update_updates_activate(dbus_arg);
        }

        public void DisableAutostart (string dbus_arg)
        {
            message ("Signal update disable autostart option: %s", dbus_arg);
            global_sig.update_disable_autostart(dbus_arg);
        }

        public void KeymapMode (string dbus_arg)
        {
            message ("Signal update keymap mode: %s", dbus_arg);
            global_sig.update_keymap_mode(dbus_arg);
        }

        public void KeymapModel (string dbus_arg)
        {
            message ("Signal update keymap model: %s", dbus_arg);
            global_sig.update_keymap_model(dbus_arg);
        }

        public void KeymapLayout (string dbus_arg)
        {
            message ("Signal update keymap layout: %s", dbus_arg);
            global_sig.update_keymap_layout(dbus_arg);
        }

        public void KeymapVariant (string dbus_arg)
        {
            message ("Signal update keymap variant: %s", dbus_arg);
            global_sig.update_keymap_variant(dbus_arg);
        }

        public void KeymapOptions (string dbus_arg)
        {
            message ("Signal update keymap options: %s", dbus_arg);
            global_sig.update_keymap_options(dbus_arg);
        }

        public void XrandrMode (string dbus_arg)
        {
            message ("Signal update xrandr mode: %s", dbus_arg);
            global_sig.update_xrandr_mode(dbus_arg);
        }

        public void XrandrCommand (string dbus_arg)
        {
            message ("Signal update xrandr command: %s", dbus_arg);
            global_sig.update_xrandr_command(dbus_arg);
        }

        public void GtkThemeName (string dbus_arg)
        {
            message ("Signal update gtk_theme_name: %s", dbus_arg);
            global_sig.update_gtk_theme_name(dbus_arg);
        }

        public void GtkIconThemeName (string dbus_arg)
        {
            message ("Signal update gtk_icon_theme_name: %s", dbus_arg);
            global_sig.update_gtk_icon_theme_name(dbus_arg);
        }

        public void GtkFontName (string dbus_arg)
        {
            message ("Signal update gtk_font_name: %s", dbus_arg);
            global_sig.update_gtk_font_name(dbus_arg);
        }

        public void GtkToolbarStyle (int dbus_arg)
        {
            message ("Signal update gtk_toolbar_style: %i", dbus_arg);
            global_sig.update_gtk_toolbar_style(dbus_arg);
        }

        public void GtkButtonImages (int dbus_arg)
        {
            message ("Signal update gtk_button_images: %i", dbus_arg);
            global_sig.update_gtk_button_images(dbus_arg);
        }

        public void GtkMenuImages (int dbus_arg)
        {
            message ("Signal update gtk_menu_images: %i", dbus_arg);
            global_sig.update_gtk_menu_images(dbus_arg);
        }

        public void GtkCursorThemeSize (int dbus_arg)
        {
            message ("Signal update gtk_cursor_theme_size: %i", dbus_arg);
            global_sig.update_gtk_cursor_theme_size(dbus_arg);
        }

        public void GtkAntialias (int dbus_arg)
        {
            message ("Signal update gtk_antialias: %i", dbus_arg);
            global_sig.update_gtk_antialias(dbus_arg);
        }

        public void GtkHinting (int dbus_arg)
        {
            message ("Signal update gtk_hinting: %i", dbus_arg);
            global_sig.update_gtk_hinting(dbus_arg);
        }

        public void GtkHintStyle (string dbus_arg)
        {
            message ("Signal update gtk_hint_style: %s", dbus_arg);
            global_sig.update_gtk_hint_style(dbus_arg);
        }

        public void GtkRgba (string dbus_arg)
        {
            message ("Signal update gtk_rgba: %s", dbus_arg);
            global_sig.update_gtk_rgba(dbus_arg);
        }

        public void GtkColorScheme (string dbus_arg)
        {
            message ("Signal update gtk_color_scheme: %s", dbus_arg);
            global_sig.update_gtk_color_scheme(dbus_arg);
        }

        public void GtkCursorThemeName (string dbus_arg)
        {
            message ("Signal update gtk_cursor_theme_name: %s", dbus_arg);
            global_sig.update_gtk_cursor_theme_name(dbus_arg);
        }


        public void GtkToolbarIconSize (int dbus_arg)
        {
            message ("Signal update gtk_toolbar_icon_size: %i", dbus_arg);
            global_sig.update_gtk_toolbar_icon_size(dbus_arg);
        }

        public void GtkEnableEventSounds (int dbus_arg)
        {
            message ("Signal update gtk_enable_event_sounds: %i", dbus_arg);
            global_sig.update_gtk_enable_event_sounds(dbus_arg);
        }

        public void GtkEnableInputFeedbackSounds (int dbus_arg)
        {
            message ("Signal update gtk_enable_input_feedback_sounds: %i", dbus_arg);
            global_sig.update_gtk_enable_input_feedback_sounds(dbus_arg);
        }

        public void MouseAccFactor (int dbus_arg)
        {
            message ("Signal update mouse_acc_factor: %i", dbus_arg);
            global_sig.update_mouse_acc_factor(dbus_arg);
        }

        public void MouseAccThreshold (int dbus_arg)
        {
            message ("Signal update mouse_acc_threshold: %i", dbus_arg);
            global_sig.update_mouse_acc_threshold(dbus_arg);
        }

        public void MouseLeftHanded (int dbus_arg)
        {
            message ("Signal update mouse_left_handed: %i", dbus_arg);
            global_sig.update_mouse_left_handed(dbus_arg);
        }

        public void KeyboardDelay (int dbus_arg)
        {
            message ("Signal update keyboard_delay: %i", dbus_arg);
            global_sig.update_keyboard_delay(dbus_arg);
        }

        public void KeyboardInterval (int dbus_arg)
        {
            message ("Signal update keyboard_interval: %i", dbus_arg);
            global_sig.update_keyboard_interval(dbus_arg);
        }

        public void KeyboardBeep (int dbus_arg)
        {
            message ("Signal update keyboard_beep: %i", dbus_arg);
            global_sig.update_keyboard_beep(dbus_arg);
        }

        public async void PackageManagerRunning (out bool is_running)
        {
            message ("Check if package manager is running");
            is_running = check_package_manager_running();
        }
    }

}
