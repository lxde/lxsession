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
            command = "";
            command = global_settings.audio_manager;
            message ("Get audio manager: %s", command);
        }

        public void AudioManagerSet(string command)
        {
            message ("Set audio manager to :%s", command);
            global_sig.request_audio_manager_set(command);
        }

        public void AudioManagerLaunch()
        {
            message ("Launch audio manager");
            global_sig.request_audio_manager_launch();
        }

        public void QuitManagerLaunch()
        {
            message ("Launch quit manager");
            global_sig.request_quit_manager_launch();
        }

        public void WorkspaceManagerLaunch()
        {
            message ("Launch workspace manager");
            global_sig.request_workspace_manager_launch();
        }

        public void LauncherManagerLaunch()
        {
            message ("Launch launcher manager");
            global_sig.request_launcher_manager_launch();
        }

        public void TerminalManagerLaunch()
        {
            message ("Launch terminal manager");
            global_sig.request_terminal_manager_launch();
        }

        public void CompositeManagerLaunch()
        {
            message ("Launch composite manager");
            global_sig.request_composite_manager_launch();
        }

        public void ScreenshotManagerLaunch()
        {
            message ("Launch screenshot manager");
            global_sig.request_screenshot_manager_launch();
        }

        public void ScreenshotWindowManagerLaunch()
        {
            message ("Launch screenshot window manager");
            global_sig.request_screenshot_window_manager_launch();
        }

        public void UpgradesManagerLaunch()
        {
            message ("Launch upgrades manager");
            global_sig.request_upgrades_manager_launch();
        }

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

        public void WindowManager (string dbus_arg)
        {
            message ("Signal update window manager: %s", dbus_arg);
            global_sig.update_window_manager(dbus_arg);
        }

        public void WindowManagerProgram (string dbus_arg)
        {
            message ("Signal update window manager program: %s", dbus_arg);
            global_sig.update_window_manager_program(dbus_arg);
        }

        public void WindowManagerSession (string dbus_arg)
        {
            message ("Signal update window manager session: %s", dbus_arg);
            global_sig.update_window_manager_session(dbus_arg);
        }

        public void WindowManagerExtras (string dbus_arg)
        {
            message ("Signal update window manager extras: %s", dbus_arg);
            global_sig.update_window_manager_extras(dbus_arg);
        }

        public void CompositeManagerCommand (string dbus_arg)
        {
            message ("Signal update composite manager command: %s", dbus_arg);
            global_sig.update_composite_manager_command(dbus_arg);
        }

        public void CompositeManagerAutostart (string dbus_arg)
        {
            message ("Signal update composite manager autostart: %s", dbus_arg);
            global_sig.update_composite_manager_autostart(dbus_arg);
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
