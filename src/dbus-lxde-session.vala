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
public class LxdeSessionServer : Object {

    public void Shutdown() {
        var session = new SessionObject();
        session.lxsession_shutdown();
    }
    public async void CanShutdown(out bool is_available) {
        var session = new SessionObject();
        is_available = yield session.lxsession_can_shutdown();
    }

    public void RequestShutdown() {
        var session = new SessionObject();
        session.lxsession_shutdown();
    }

    public void RequestReboot() {
        var session = new SessionObject();
        session.lxsession_restart();
    }

    public void Logout() {
        var session = new SessionObject();
        session.lxsession_restart();
    }

    public void ReloadSettingsDaemon()
    {
        message ("Restart Xsettings Deamon");
        settings_daemon_reload();
    }

    public void WindowManager (string dbus_arg)
    {
        message ("Signal update window manager: %s", dbus_arg);
        global_sig.update_window_manager(dbus_arg);
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
}

}
