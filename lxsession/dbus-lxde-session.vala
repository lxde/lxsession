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
            message ("Restart Xsettings Daemon");
            XsettingsManagerActivate();
        }

        /* Session API */
        public void SessionSupport (out string[] list)
        {
            list = GenericSupport ("Session");
        }

        public void SessionSupportDetail (string key1, out string[] list)
        {
            list = GenericSupportDetail ("Session", key1);
        }

        public void SessionGet(string key1, string key2, out string command)
        {
            command = GenericGet("Session", key1, key2);
        }

        public void SessionSet(string key1, string key2, string command_to_set)
        {
            GenericSet("Session", key1, key2, command_to_set);
        }

        /* Xsettings API */
        public void XsettingsSupport (out string[] list)
        {
            list = GenericSupport ("Xsettings");
        }

        public void XsettingsSupportDetail (string key1, out string[] list)
        {
            list = GenericSupportDetail ("Xsettings", key1);
        }

        public void XsettingsGet(string key1, string key2, out string command)
        {
            command = GenericGet("Xsettings", key1, key2);
        }

        public void XsettingsSet(string key1, string key2, string command_to_set)
        {
            GenericSet("Xsettings", key1, key2, command_to_set);
        }

        /* State API */
        public void StateSupport (out string[] list)
        {
            list = GenericSupport ("State");
        }

        public void StateSupportDetail (string key1, out string[] list)
        {
            list = GenericSupportDetail ("State", key1);
        }

        public void StateGet(string key1, string key2, out string command)
        {
            command = GenericGet("State", key1, key2);
        }

        public void StateSet(string key1, string key2, string command_to_set)
        {
            GenericSet("State", key1, key2, command_to_set);
        }

        /* Dbus API */
        public void DbusSupport (out string[] list)
        {
            list = GenericSupport ("Dbus");
        }

        public void DbusSupportDetail (string key1, out string[] list)
        {
            list = GenericSupportDetail ("Dbus", key1);
        }

        public void DbusGet(string key1, string key2, out string command)
        {
            command = GenericGet("Dbus", key1, key2);
        }

        public void DbusSet(string key1, string key2, string command_to_set)
        {
            GenericSet("Dbus", key1, key2, command_to_set);
        }

        /* Keymap API */
        public void KeymapSupport (out string[] list)
        {
            list = GenericSupport ("Keymap");
        }

        public void KeymapSupportDetail (string key1, out string[] list)
        {
            list = GenericSupportDetail ("Keymap", key1);
        }

        public void KeymapGet(string key1, string key2, out string command)
        {
            command = GenericGet("Keymap", key1, key2);
        }

        public void KeymapSet(string key1, string key2, string command_to_set)
        {
            GenericSet("Keymap", key1, key2, command_to_set);
        }

        public void KeymapActivate()
        {
            message("Reload keymap");
            if (global_settings.get_item_string("Keymap", "mode", null) == null)
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

        /* Environment API */
        public void EnvironmentSupport (out string[] list)
        {
            list = GenericSupport ("Environment");
        }

        public void EnvironmentSupportDetail (string key1, out string[] list)
        {
            list = GenericSupportDetail ("Environment", key1);
        }

        public void EnvironmentGet(string key1, string key2, out string command)
        {
            command = GenericGet("Environment", key1, key2);
        }

        public void EnvironmentSet(string key1, string key2, string command_to_set)
        {
            GenericSet("Environment", key1, key2, command_to_set);
        }

        private string[] GenericSupport (string categorie)
        {
            string tmp_support;
            string[] list;
            tmp_support = global_settings.get_support(categorie);

            list = tmp_support.split_set(";",0);
            // TODO Remove the last item (empty)

            return list;
        }

        private string[] GenericSupportDetail (string categorie, string key1)
        {
            string tmp = null;
            string[] list;

            Value tmp_value;
            string tmp_type = null;

            constructor_dbus ("support", categorie, key1, null, null, out tmp_value, out tmp_type);

            switch (tmp_type)
            {
                case "string":
                    tmp = (string) tmp_value;
                    break;
            }

            message ("tmp for support detail: %s", tmp);
            list = tmp.split_set(";",0);
            // TODO Remove the last item (empty)

            return list;
        }

        private void constructor_dbus (string mode, string categorie, string key1, string? key2, string? default_value, out string command, out string type)
        {
            // message("Enter constructor_dbus, for %s, %s, %s and %s", mode, categorie, key1, key2);

            type = null;
            command = null;

            switch (mode)
            {
                case "get":
                    // message ("try to look at config_item_db");
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

        private string GenericGet(string categorie, string key1, string key2)
        {
            // message ("Enter Get method");

            string command;
            Value tmp_value;
            string tmp_type;

            constructor_dbus ("get", categorie, key1, key2, null, out tmp_value, out tmp_type);

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
            // message ("Get %s %s: %s", key1, key2, command);

            return command;
        }

        private void GenericSet(string categorie, string key1, string key2, string command_to_set)
        {
            // message ("Set %s %s", key1, key2);

            global_sig.generic_set_signal(categorie, key1, key2, "string", command_to_set);
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

                    case "a11y":
                        A11yActivate();
                        break;

                    case "proxy_manager":
                        ProxyActivate();
                        break;

                    case "xrandr":
                        XrandrActivate();
                        break;

                    case "keyring":
                        KeyringActivate();
                        break;

                    case "updates_manager":
                        if (option == "check")
                        {
                            UpdatesCheck();
                        }
                        else if (option == "activate")
                            {
                                UpdatesAct();
                            }
                            else if (option == "inactivate")
                                {
                                    UpdatesInactivate();
                                }
                        break;

                    case "crash_manager":
                        if (option == "activate")
                        {
                            CrashManagerActivate();
                        }
                        else if (option == "inactivate")
                            {
                                CrashManagerInactivate();
                            }
                        break;

                    default:
                        var application = new GenericSimpleApp(settings);
                        application.launch();
                        break;
                }
            }
        }

        private void UpdatesActivate()
        {
            message("Reload updates_manager");
            if (global_settings.get_item_string("Session", "updates_manager", "command") == null)
            {
                warning("Updates_manager not set");
            }
            else if (global_updates == null)
            {
                message("Updates_manager doesn't exist, creating it");
                var updates = new UpdatesManagerApp();
                global_updates = updates;
                global_updates.launch();
            }
            else
            {
                message("Reload existing Updates_manager");
                global_updates.reload();
            }
        }

        private void UpdatesCheck()
        {
            message("Reload updates_manager");
            if (global_settings.get_item_string("Session", "updates_manager", "command") == null)
            {
                warning("Updates_manager not set");
            }
            else if (global_updates == null)
            {
                message("Updates_manager doesn't exist, creating it");
                var updates = new UpdatesManagerApp();
                global_updates = updates;
                global_updates.launch();
                global_updates.run_check();
            }
            else
            {
                message("Check Updates");
                global_updates.run_check();
            }
        }

        private void UpdatesAct()
        {
            message("Reload updates_manager");
            if (global_settings.get_item_string("Session", "updates_manager", "command") == null)
            {
                warning("Updates_manager not set");
            }
            else if (global_updates == null)
            {
                message("Updates_manager doesn't exist, creating it");
                var updates = new UpdatesManagerApp();
                global_updates = updates;
                global_updates.test_activate();
            }
            else
            {
                message("Check Updates");
                global_updates.test_activate();
            }
        }

        private void UpdatesInactivate()
        {
            message("Reload updates_manager");
            if (global_settings.get_item_string("Session", "updates_manager", "command") == null)
            {
                warning("Updates_manager not set");
            }
            else if (global_updates == null)
            {
                message("Updates_manager doesn't exist, creating it");
                var updates = new UpdatesManagerApp();
                global_updates = updates;
                global_updates.test_inactivate();
            }
            else
            {
                message("Check Updates");
                global_updates.test_inactivate();
            }
        }

        public void CrashManagerLaunch()
        {
            message("Launch crash manager");
            if (global_settings.get_item_string("Session", "crash_manager", "command") == null)
            {
                warning("Crash manager not set");
            }
            else if (global_crash == null)
            {
                message("Crash manager doesn't exist, creating it");
                var crash = new CrashManagerApp();
                global_crash = crash;
                global_crash.launch();
            }
            else
            {
                message("Reload existing crash manager");
                global_crash.reload();
            }
        }

        public void CrashManagerActivate()
        {
            message("Launch crash manager reporter");
            if (global_settings.get_item_string("Session", "crash_manager", "command") == null)
            {
                warning("Crash manager not set");
            }
            else if (global_crash == null)
            {
                message("Crash manager doesn't exist, creating it and activate");
                var crash = new CrashManagerApp();
                global_crash = crash;
                global_crash.test_activate();
            }
            else
            {
                message("Launching crash manager activate");
                global_crash.test_activate();
            }
        }

        public void CrashManagerInactivate()
        {
            message("Launch crash manager reporter");
            if (global_settings.get_item_string("Session", "crash_manager", "command") == null)
            {
                warning("Crash manager not set");
            }
            else if (global_crash == null)
            {
                message("Crash manager doesn't exist, creating it and inactivate");
                var crash = new CrashManagerApp();
                global_crash = crash;
                global_crash.test_inactivate();
            }
            else
            {
                message("Launching crash manager inactivate");
                global_crash.test_inactivate();
            }
        }

        public void KeyringActivate()
        {
            message("Reload security");
            if (global_settings.get_item_string("Session", "xrandr", "command") == null)
            {
                warning("Security keyring not set");
            }
            else if (global_keyring == null)
            {
                message("Keyring doesn't exist, creating it");
                var keyring = new KeyringApp();
                global_keyring = keyring;
                global_keyring.launch();
            }
            else
            {
                message("Reload existing keyring");
                global_keyring.reload();
            }
        }

        public void XrandrActivate()
        {
            message("Reload xrandr");
            if (global_settings.get_item_string("Session", "xrandr", "command") == null)
            {
                warning("Xrandr mode not set");
            }
            else if (global_xrandr == null)
            {
                message("Xrandr doesn't exist, creating it");
                var xrandr = new XrandrApp();
                global_xrandr = xrandr;
                global_xrandr.launch();
            }
            else
            {
                message("Reload existing xrandr");
                global_xrandr.reload();
            }
        }

        public void ProxyActivate()
        {
            message("Reload proxy");
            if (global_settings.get_item_string("Session", "proxy_manager", "command") == null)
            {
                warning("Proxy http not set");
            }
            else if (global_proxy == null)
            {
                message("Proxy doesn't exist, creating it");
                var proxy = new ProxyManagerApp();
                global_proxy = proxy;
                global_proxy.launch();
            }
            else
            {
                message("Reload existing proxy");
                global_proxy.reload();
            }
        }

        public void A11yActivate()
        {
            message("Reload a11y");
            if (global_settings.get_item_string("Session", "a11y", "command") == null)
            {
                warning("A11y type not set");
            }
            else if (global_a11y == null)
            {
                message("A11y doesn't exist, creating it");
                var a11y = new A11yApp();
                global_a11y = a11y;
                global_a11y.launch();
            }
            else
            {
                message("Reload existing a11y");
                global_a11y.reload();
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
            if (global_settings.get_item_string("Session", "desktop_manager", "command") == null)
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
            message("Launch settings for desktop_manager");
            if (global_settings.get_item_string("Session", "desktop_manager", "command") == null)
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
        private void MessageManagerLaunch()
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
        private void ClipboardActivate()
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

        /* Package manager running */
        public async void PackageManagerRunning (out bool is_running)
        {
            message ("Check if package manager is running");
            is_running = check_package_manager_running();
        }

        /* Test interface */
        public void TestIconNotification()
        {
            message("Test icon notification default");
            var icon_test = new IconObject("gtk-info", "Info", null, null);
            icon_test.init();
        }
    }

}
