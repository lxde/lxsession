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
            XsettingsManagerActivate();
        }

        public void SessionSupport (out string[] list)
        {
            string tmp_support;
            tmp_support = global_settings.get_support("Session");

            list = tmp_support.split_set(";",0);
            // TODO Remove the last item (empty)
        }

        public void SessionSupportDetail (string key1, out string[] list)
        {
            string tmp = null;

            Value tmp_value;
            string tmp_type = null;

            constructor_dbus ("support", "Session", key1, null, null, out tmp_value, out tmp_type);

            switch (tmp_type)
            {
                case "string":
                    tmp = (string) tmp_value;
                    break;
            }

            message ("tmp for support detail: %s", tmp);
            list = tmp.split_set(";",0);
            // TODO Remove the last item (empty)
        }

        private void constructor_dbus (string mode, string categorie, string key1, string? key2, string? default_value, out string command, out string type)
        {
            message("Enter constructor_dbus, for %s, %s, %s and %s", mode, categorie, key1, key2);

            type = null;
            command = null;

            switch (mode)
            {
                case "get":
                    message ("try to look at config_item_db");
                    global_settings.get_item(categorie, key1, key2, out command, out type);
                    break;
                case "launch":
                    global_settings.get_item(categorie, key1, key2, out command, out type);
                    break;
                case "support":
                    command = global_settings.get_support_key(categorie, key1);
                    type = "string";
                    break;
            }
        }

        public void SessionGet(string key1, string key2, out string command)
        {
            message ("Enter Get method");

            Value tmp_value;
            string tmp_type;

            constructor_dbus ("get", "Session", key1, key2, null, out tmp_value, out tmp_type);

            switch (tmp_type)
            {
                case "string":
                    command = (string) tmp_value;
                    if (command == null)
                    {
                        command = "";
                    }
                    break;
                default:
                    command = "";
                    break;
            }
            message ("Get %s %s: %s", key1, key2, command);
        }

        public void SessionSet(string key1, string key2, string command_to_set)
        {
            message ("Set %s %s", key1, key2);

            global_sig.generic_set_signal(command_to_set, "Session", key1, key2);
         }


        public void SessionLaunch(string name, string option)
        {
            string settings;
            string type;

            constructor_dbus("launch", "Session", name, "command", null, out settings, out type);

            if (settings == null)
            {
                message("Error, %s not set", name);
            }
            else
            {
                /* TODO Make it more generic by tweaking the app objects (adding a type ?) */
                switch (name)
                {
                    case "xsettings_manager":
                        XsettingsManagerActivate();
                        break;

                    case "audio_manager":
                        AudioManagerLaunch();
                        break;

                    case "quit_manager":
                        QuitManagerLaunch();
                        break;

                    case "workspace_manager":
                        WorkspaceManagerLaunch();
                        break;

                    case "launcher_manager":
                        LauncherManagerLaunch();
                        break;

                    case "terminal_manager":
                        TerminalManagerLaunch(option);
                        break;

                    case "screenshot_manager":
                        if (option == "window")
                        {
                            ScreenshotWindowManagerLaunch();
                        }
                        else
                        {
                            ScreenshotManagerLaunch();
                        }
                        break;

                    case "composite_manager":
                        CompositeManagerReload();
                        break;

                    case "im1":
                        IM1Reload();
                        break;

                    case "im2":
                        IM2Reload();
                        break;

                    case "widget1":
                        Widget1Reload();
                        break;

                    case "file_manager":
                        if (option == "launch")
                        {
                            FileManagerLaunch();
                        }
                        else
                        {
                            FileManagerReload();
                        }
                        break;

                    case "panel":
                        PanelReload();
                        break;

                    case "dock":
                        DockReload();
                        break;

                    case "windows_manager":
                        WindowsManagerReload();
                        break;

                    case "desktop_manager":
                        if (option == "settings")
                        {
                            DesktopLaunchSettings();
                        }
                        else
                        {
                            DesktopReload();
                        }
                        break;

                    case "screensaver":
                        ScreensaverReload();
                        break;

                    case "power_manager":
                        PowerManagerReload();
                        break;

                    case "polkit":
                        PolkitReload();
                        break;

                    case "network_gui":
                        NetworkGuiReload();
                        break;

                    case "message_manager":
                        MessageManagerLaunch();
                        break;

                    case "clipboard":
                        ClipboardActivate();
                        break;

                    default:
                        var application = new GenericSimpleApp(settings);
                        application.launch();
                        break;
                }
            }
        }

        /* Xsettings Manager */
        private void XsettingsManagerActivate()
        {
            message ("Activate xsettings manager");
            if (global_settings.get_item_string("Session", "xsettings_manager", "command") == null)
            {
                warning("Xsettings manager not set");
            }
            else if (global_xsettings_manager == null)
            {
                var xsettings = new XSettingsOption();
                global_xsettings_manager = xsettings;
                global_xsettings_manager.activate();
            }
            else
            {
                global_xsettings_manager.reload();
            }
        }

        /* Audio Manager */
        private void AudioManagerLaunch()
        {
            message ("Launch audio manager");
            if (global_settings.get_item_string("Session", "audio_manager", "command") == null)
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
        private void QuitManagerLaunch()
        {
            message("Start Quit Manager");
            if (global_settings.get_item_string("Session", "quit_manager", "command") == null)
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
        private void WorkspaceManagerLaunch()
        {
            message("Start Workspace Manager");
            if (global_settings.get_item_string("Session", "workspace_manager", "command") == null)
            {
                warning("Workspace manager command not set");
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
        private void LauncherManagerLaunch()
        {
            message("Start Launcher Manager");
            if (global_settings.get_item_string("Session", "launcher_manager", "command") == null)
            {
                warning("Launcher manager command not set");
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
        private void TerminalManagerLaunch(string? arg1)
        {
            message("Start Terminal Manager");
            if (global_settings.get_item_string("Session", "terminal_manager", "command") == null)
            {
                warning("Terminal manager command not set");
            }
            else if (global_terminal_manager == null)
            {
                var terminal = new TerminalManagerApp();
                global_terminal_manager = terminal;
                global_terminal_manager.launch(arg1);
            }
            else
            {
                global_terminal_manager.launch(arg1);
            }
        }

        /* Screenshot manager */
        private void ScreenshotManagerLaunch()
        {
            message("Start Screenshot Manager");
            if (global_settings.get_item_string("Session", "screenshot_manager", "command") == null)
            {
                warning("Screenshot manager command not set");
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

        private void ScreenshotWindowManagerLaunch()
        {
            message("Start Screenshot Window Manager");
            if (global_settings.get_item_string("Session", "screenshot_manager", "command") == null)
            {
                warning("Screenshot manager command not set");
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

        /* Composite manager */
        private void CompositeManagerReload()
        {
            message("Reload composite manager");
            if (global_settings.get_item_string("Session", "composite_manager", "command") == null)
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

        /* IM1 manager */
        private void IM1Reload()
        {
            message("Reload im1");
            if (global_settings.get_item_string("Session", "im1", "command") == null)
            {
                warning("im1 not set not set");
            }
            else if (global_im1 == null)
            {
                message("IM1 doesn't exist, creating it");
                var im1 = new IM1App();
                global_im1 = im1;
                global_im1.launch();
            }
            else
            {
                message("Reload existing im1");
                global_im1.reload();
            }
        }

        /* IM2 manager */

        private void IM2Reload()
        {
            message("Reload im2");
            if (global_settings.get_item_string("Session", "im2", "command") == null)
            {
                warning("im2 not set not set");
            }
            else if (global_im2 == null)
            {
                message("IM2 doesn't exist, creating it");
                var im2 = new IM2App();
                global_im2 = im2;
                global_im2.launch();
            }
            else
            {
                message("Reload existing im2");
                global_im2.reload();
            }
        }

        /* Widget manager */
        private void Widget1Reload()
        {
            message("Reload widget1");
            if (global_settings.get_item_string("Session", "widget1", "command") == null)
            {
                warning("widget1 not set not set");
            }
            else if (global_widget1 == null)
            {
                message("Widget1 doesn't exist, creating it");
                var widget1 = new WidgetApp();
                global_widget1 = widget1;
                global_widget1.launch();
            }
            else
            {
                message("Reload existing widget1");
                global_widget1.reload();
            }
        }

        /* FileManager control */
        private void FileManagerReload()
        {
            message("Reload Filemanager");
            if (global_settings.get_item_string("Session", "file_manager", "command") == null)
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

        private void FileManagerLaunch()
        {
            message("Launch another file manager");
            if (global_settings.get_item_string("Session", "file_manager", "command") == null)
            {
                warning("File manager not set");
            }
            else
            {
                var filemanager = new FileManagerApp();
                filemanager.launch();
            }
        }

        /* Panel control */
        private void PanelReload()
        {
            message("Reload panel");
            if (global_settings.get_item_string("Session", "panel", "command") == null)
            {
                warning("Panel not set");
            }
            else if (global_panel == null)
            {
                message("Panel doesn't exist, creating it");
                var panel = new PanelApp();
                global_panel = panel;
                global_panel.launch();
            }
            else
            {
                message("Reload existing panel");
                global_panel.reload();
            }
        }

        /* Dock control */
        private void DockReload()
        {
            message("Reload dock");
            if (global_settings.get_item_string("Session", "dock", "command") == null)
            {
                warning("Dock not set");
            }
            else if (global_dock == null)
            {
                message("Dock doesn't exist, creating it");
                var dock = new DockApp();
                global_dock = dock;
                global_dock.launch();
            }
            else
            {
                message("Reload existing dock");
                global_dock.reload();
            }
        }

        /* Windows Manager control */
        private void WindowsManagerReload()
        {
            message("Reload Windows Manager");
            if (global_settings.get_item_string("Session", "windows_manager", "command") == null)
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
        private void DesktopReload()
        {
            message("Reload desktop manager");
            if (global_settings.get_item_string("Session", "desktop", "command") == null)
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

        private void DesktopLaunchSettings()
        {
            message("Launch settings for desktop manager");
            if (global_settings.get_item_string("Session", "desktop", "command") == null)
            {
                warning("desktop manager not set");
            }
            else if (global_desktop == null)
            {
                message("Desktop manager doesn't exist, creating it");
                var desktop = new DesktopApp();
                global_desktop = desktop;
                global_desktop.launch_settings();
            }
            else
            {
                message("Reload existing desktop manager");
                global_desktop.launch_settings();
            }
        }

        /* Screensaver */
        private void ScreensaverReload()
        {
            message("Reload screensaver");
            if (global_settings.get_item_string("Session", "screensaver", "command") == null)
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
        private void PowerManagerReload()
        {
            message("Reload power manager");
            if (global_settings.get_item_string("Session", "power_manager", "command") == null)
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
        private void PolkitReload()
        {
            message("Reload polkit");
            if (global_settings.get_item_string("Session", "polkit", "command") == null)
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

        /* Network GUI */
        private void NetworkGuiReload()
        {
            message("Reload network gui");
            if (global_settings.get_item_string("Session", "network_gui", "command") == null)
            {
                warning("Network gui command not set");
            }
            else if (global_network_gui == null)
            {
                message("Network gui doesn't exist, creating it");
                var networkgui = new NetworkGuiApp();
                global_network_gui = networkgui;
                global_network_gui.launch();
            }
            else
            {
                message("Reload existing network gui");
                global_network_gui.reload();
            }
        }

        /* Message */
        public void MessageManagerLaunch()
        {
            message("Launch message manager");
            if (global_settings.get_item_string("Session", "message_manager", "command") == null)
            {
                warning("message manager command not set");
            }
            else if (global_message_manager == null)
            {
                message("Message_manager doesn't exist, creating it");
                var messagemanager = new GenericSimpleApp(global_settings.get_item_string("Session", "message_manager", "command"));
                global_message_manager = messagemanager;
                global_message_manager.launch();
            }
            else
            {
                message("Reload existing message_manager");
                global_message_manager.reload();
            }
        }

        /* Clipboard */
        public void ClipboardActivate()
        {
            message("Reload clipboard");
            if (global_settings.get_item_string("Session", "clipboard", "command") == null)
            {
                warning("Clipboard command not set");
            }
            else if (global_clipboard == null)
            {
                message("Clipboard doesn't exist, creating it");
                var clipboard = new ClipboardOption(global_settings);
                global_clipboard = clipboard;
                global_clipboard.activate();
            }
            else
            {
                message("Reload existing clipboard");
                global_clipboard.desactivate();
                global_clipboard.activate();
            }
        }

        /* Keymap */
        public void KeymapModeGet(out string command)
        {
            command = global_settings.keymap_mode;
            message ("Get keymap mode: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void KeymapModeSet(string command)
        {
            message ("Set keymap mode to :%s", command);
            global_sig.request_keymap_mode_set(command);
        }

        public void KeymapModelGet(out string command)
        {
            command = global_settings.keymap_model;
            message ("Get keymap model: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void KeymapModelSet(string command)
        {
            message ("Set keymap model to :%s", command);
            global_sig.request_keymap_model_set(command);
        }

        public void KeymapLayoutGet(out string command)
        {
            command = global_settings.keymap_layout;
            message ("Get keymap layout: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void KeymapLayoutSet(string command)
        {
            message ("Set keymap layout to :%s", command);
            global_sig.request_keymap_layout_set(command);
        }

        public void KeymapVariantGet(out string command)
        {
            command = global_settings.keymap_variant;
            message ("Get keymap variant: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void KeymapVariantSet(string command)
        {
            message ("Set keymap variant to :%s", command);
            global_sig.request_keymap_variant_set(command);
        }

        public void KeymapOptionsGet(out string command)
        {
            command = global_settings.keymap_options;
            message ("Get keymap options: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void KeymapOptionsSet(string command)
        {
            message ("Set keymap options to :%s", command);
            global_sig.request_keymap_options_set(command);
        }

        public void KeymapActivate()
        {
            message("Reload keymap");
            if (global_settings.keymap_mode == null)
            {
                warning("Keymap mode not set");
            }
            else if (global_keymap == null)
            {
                message("Keymap doesn't exist, creating it");
                var keymap = new KeymapOption(global_settings);
                global_keymap = keymap;
                global_keymap.activate();
            }
            else
            {
                message("Reload existing keymap");
                global_keymap.activate();
            }
        }

        public void XrandrModeGet(out string command)
        {
            command = global_settings.xrandr_mode;
            message ("Get xrandr mode: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void XrandrModeSet(string command)
        {
            message ("Set xrandr mode to :%s", command);
            global_sig.request_xrandr_mode_set(command);
        }

        public void XrandrCommandGet(out string command)
        {
            command = global_settings.xrandr_command;
            message ("Get xrandr command: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void XrandrCommandSet(string command)
        {
            message ("Set xrandr command to :%s", command);
            global_sig.request_xrandr_command_set(command);
        }

        public void XrandrActivate()
        {
            message("Reload xrandr");
            if (global_settings.xrandr_mode == null)
            {
                warning("Xrandr mode not set");
            }
            else if (global_xrandr == null)
            {
                message("Xrandr doesn't exist, creating it");
                var xrandr = new XrandrOption(global_settings);
                global_xrandr = xrandr;
                global_xrandr.activate();
            }
            else
            {
                message("Reload existing xrandr");
                global_xrandr.activate();
            }
        }

        public void SecurityKeyringGet(out string command)
        {
            command = global_settings.security_keyring;
            message ("Get security keyring: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void SecurityKeyringSet(string command)
        {
            message ("Set security keyring to :%s", command);
            global_sig.request_security_keyring_set(command);
        }

        public void SecurityActivate()
        {
            message("Reload security");
            if (global_settings.security_keyring == null)
            {
                warning("Security keyring not set");
            }
            else if (global_keyring == null)
            {
                message("Keyring doesn't exist, creating it");
                var keyring = new KeyringOption(global_settings);
                global_keyring = keyring;
                global_keyring.activate();
            }
            else
            {
                message("Reload existing keyring");
                global_keyring.activate();
            }
        }

        public void A11yTypeGet(out string command)
        {
            command = global_settings.a11y_type;
            message ("Get a11y type: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void A11yTypeSet(string command)
        {
            message ("Set a11y type to :%s", command);
            global_sig.request_a11y_type_set(command);
        }

        public void A11yActivate()
        {
            message("Reload a11y");
            if (global_settings.a11y_type == null)
            {
                warning("A11y type not set");
            }
            else if (global_a11y == null)
            {
                message("A11y doesn't exist, creating it");
                var a11y = new A11yOption(global_settings);
                global_a11y = a11y;
                global_a11y.activate();
            }
            else
            {
                message("Reload existing a11y");
                global_a11y.activate();
            }
        }

        public void ProxyHttpGet(out string command)
        {
            command = global_settings.proxy_http;
            message ("Get proxy_http: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void ProxyHttpSet(string command)
        {
            message ("Set proxy_http to :%s", command);
            global_sig.request_proxy_http_set(command);
        }

        public void ProxyActivate()
        {
            message("Reload proxy");
            if (global_settings.proxy_http == null)
            {
                warning("Proxy http not set");
            }
            else if (global_proxy == null)
            {
                message("Proxy doesn't exist, creating it");
                var proxy = new ProxyOption(global_settings);
                global_proxy = proxy;
                global_proxy.activate();
            }
            else
            {
                message("Reload existing proxy");
                global_proxy.activate();
            }
        }

        public void UpdatesTypeGet(out string command)
        {
            command = global_settings.updates_type;
            message ("Get updates type: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void UpdatesTypeSet(string command)
        {
            message ("Set updates type to :%s", command);
            global_sig.request_updates_type_set(command);
        }

        public void UpdatesActivate()
        {
            message("Reload updates");
            if (global_settings.updates_type == null)
            {
                warning("Updates type not set");
            }
            else if (global_updates == null)
            {
                message("Updates doesn't exist, creating it");
                var updates = new UpdatesOption(global_settings);
                global_updates = updates;
                global_updates.activate();
            }
            else
            {
                message("Reload existing updates");
                global_updates.activate();
            }
        }

        /* Laptop mode */
        public void LaptopModeGet(out string command)
        {
            command = global_settings.laptop_mode;
            message ("Get laptop mode type: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void LaptopModeSet(string command)
        {
            message ("Set laptop_mode to :%s", command);
            global_sig.request_laptop_mode_set(command);
        }

        /* Dbus */
        public void DbusLxdeGet(out string command)
        {
            command = global_settings.dbus_lxde;
            message ("Get dbus lxde: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void DbusLxdeSet(string command)
        {
            message ("Set dbus lxde session:%s", command);
            global_sig.request_dbus_lxde_set(command);
        }

        public void DbusGnomeGet(out string command)
        {
            command = global_settings.dbus_gnome;
            message ("Get dbus gnome: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void DbusGnomeSet(string command)
        {
            message ("Set dbus gnome session:%s", command);
            global_sig.request_dbus_gnome_set(command);
        }

        public void EnvTypeSet(string command)
        {
            message ("Set environment type :%s", command);
            global_sig.request_env_type_set(command);
        }

        public void EnvTypeGet(out string command)
        {
            command = global_settings.env_type;
            message ("Get environment type: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void EnvMenuPrefixSet(string command)
        {
            message ("Set environment menu prefix :%s", command);
            global_sig.request_env_menu_prefix_set(command);
        }

        public void EnvMenuPrefixGet(out string command)
        {
            command = global_settings.env_menu_prefix;
            message ("Get environment menu prefix: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void MimeDistroSet(string command)
        {
            message ("Set mime distro :%s", command);
            global_sig.request_mime_distro_set(command);
        }

        public void MimeDistroGet(out string command)
        {
            command = global_settings.mime_distro;
            message ("Get mime distro: %s", command);
            if (command == null)
            {
                command = "";
            }
        }

        public void MimeFoldersInstalledSet(string[] command)
        {
            message ("Set mime folders install");
            global_sig.request_mime_folders_installed_set(command);
        }

        public void MimeFoldersInstalledGet(out string[] command)
        {
            command = global_settings.mime_folders_installed;
            message ("Get mime folders install");
            if (command == null)
            {
                command = {""};
            }
        }

        public void MimeFoldersAvailableSet(string[] command)
        {
            message ("Set mime folders available");
            global_sig.request_mime_folders_available_set(command);
        }

        public void MimeFoldersAvailableGet(out string[] command)
        {
            command = global_settings.mime_folders_available;
            message ("Get mime folders available");
            if (command == null)
            {
                command = {""};
            }
        }

        public void MimeWebbrowserInstalledSet(string[] command)
        {
            message ("Set mime webbrowser install");
            global_sig.request_mime_webbrowser_installed_set(command);
        }

        public void MimeWebbrowserInstalledGet(out string[] command)
        {
            command = global_settings.mime_webbrowser_installed;
            message ("Get mime webbrowser install");
            if (command == null)
            {
                command = {""};
            }
        }

        public void MimeWebbrowserAvailableSet(string[] command)
        {
            message ("Set mime webbrowser available");
            global_sig.request_mime_webbrowser_available_set(command);
        }

        public void MimeWebbrowserAvailableGet(out string[] command)
        {
            command = global_settings.mime_webbrowser_available;
            message ("Get mime webbrowser available");
            if (command == null)
            {
                command = {""};
            }
        }

        public void MimeEmailInstalledSet(string[] command)
        {
            message ("Set mime email install");
            global_sig.request_mime_email_installed_set(command);
        }

        public void MimeEmailInstalledGet(out string[] command)
        {
            command = global_settings.mime_email_installed;
            message ("Get mime email install");
            if (command == null)
            {
                command = {""};
            }
        }

        public void MimeEmailAvailableSet(string[] command)
        {
            message ("Set mime email available");
            global_sig.request_mime_email_available_set(command);
        }

        public void MimeEmailAvailableGet(out string[] command)
        {
            command = global_settings.mime_email_available;
            message ("Get mime email available");
            if (command == null)
            {
                command = {""};
            }
        }

        /* XSettings update */
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

        /* Package manager running */
        public async void PackageManagerRunning (out bool is_running)
        {
            message ("Check if package manager is running");
            is_running = check_package_manager_running();
        }
    }

}
