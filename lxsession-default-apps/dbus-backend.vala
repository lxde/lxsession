/* 
    Copyright 2012 Julien Lavergne <gilir@ubuntu.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace LDefaultApps
{
    [DBus(name = "org.lxde.SessionManager")]
    public interface DbusLxsession : GLib.Object
    {
        public abstract void PanelReload () throws IOError;
        public abstract void PanelCommandSet (string arg) throws IOError;
        public abstract void PanelSessionSet (string arg) throws IOError;
        public abstract string PanelCommandGet () throws IOError;
        public abstract string PanelSessionGet () throws IOError;
        public abstract void DockReload () throws IOError;
        public abstract void DockCommandSet (string arg) throws IOError;
        public abstract void DockSessionSet (string arg) throws IOError;
        public abstract string DockCommandGet () throws IOError;
        public abstract string DockSessionGet () throws IOError;
        public abstract void WindowsManagerReload () throws IOError;
        public abstract void WindowsManagerCommandSet (string arg) throws IOError;
        public abstract void WindowsManagerSessionSet (string arg) throws IOError;
        public abstract void WindowsManagerExtrasSet (string arg) throws IOError;
        public abstract string WindowsManagerCommandGet () throws IOError;
        public abstract string WindowsManagerSessionGet () throws IOError;
        public abstract string WindowsManagerExtrasGet () throws IOError;
        public abstract void ScreensaverReload () throws IOError;
        public abstract void ScreensaverCommandSet (string arg) throws IOError;
        public abstract string ScreensaverCommandGet () throws IOError;
        public abstract void PowerManagerReload () throws IOError;
        public abstract void PowerManagerCommandSet (string arg) throws IOError;
        public abstract string PowerManagerCommandGet () throws IOError;
        public abstract void FileManagerReload () throws IOError;
        public abstract void FileManagerCommandSet (string arg) throws IOError;
        public abstract void FileManagerSessionSet (string arg) throws IOError;
        public abstract void FileManagerExtrasSet (string arg) throws IOError;
        public abstract string FileManagerCommandGet () throws IOError;
        public abstract string FileManagerSessionGet () throws IOError;
        public abstract string FileManagerExtrasGet () throws IOError;
        public abstract void DesktopReload () throws IOError;
        public abstract void DesktopCommandSet (string arg) throws IOError;
        public abstract void DesktopWallpaperSet (string arg) throws IOError;
        public abstract string DesktopCommandGet () throws IOError;
        public abstract string DesktopWallpaperGet () throws IOError;
        public abstract void CompositeManagerReload () throws IOError;
        public abstract void CompositeManagerCommandSet (string arg) throws IOError;
        public abstract void CompositeManagerAutostartSet (string arg) throws IOError;
        public abstract string CompositeManagerCommandGet () throws IOError;
        public abstract string CompositeManagerAutostartGet () throws IOError;
        public abstract void PolkitReload () throws IOError;
        public abstract void PolkitCommandSet (string arg) throws IOError;
        public abstract string PolkitCommandGet () throws IOError;
        public abstract void NetworkGuiReload () throws IOError;
        public abstract void NetworkGuiCommandSet (string arg) throws IOError;
        public abstract string NetworkGuiCommandGet () throws IOError;
        public abstract void IM1Reload () throws IOError;
        public abstract void IM1CommandSet (string arg) throws IOError;
        public abstract void IM1AutostartSet (string arg) throws IOError;
        public abstract string IM1CommandGet () throws IOError;
        public abstract string IM1AutostartGet () throws IOError;
        public abstract void IM2Reload () throws IOError;
        public abstract void IM2CommandSet (string arg) throws IOError;
        public abstract void IM2AutostartSet (string arg) throws IOError;
        public abstract string IM2CommandGet () throws IOError;
        public abstract string IM2AutostartGet () throws IOError;
        public abstract void Widget1Reload () throws IOError;
        public abstract void Widget1CommandSet (string arg) throws IOError;
        public abstract void Widget1AutostartSet (string arg) throws IOError;
        public abstract string Widget1CommandGet () throws IOError;
        public abstract string Widget1AutostartGet () throws IOError;
        public abstract void AudioManagerLaunch () throws IOError;
        public abstract void AudioManagerCommandSet (string arg) throws IOError;
        public abstract string AudioManagerCommandGet () throws IOError;
        public abstract void QuitManagerLaunch () throws IOError;
        public abstract void QuitManagerCommandSet (string arg) throws IOError;
        public abstract void QuitManagerImageSet (string arg) throws IOError;
        public abstract void QuitManagerLayoutSet (string arg) throws IOError;
        public abstract string QuitManagerCommandGet () throws IOError;
        public abstract string QuitManagerImageGet () throws IOError;
        public abstract string QuitManagerLayoutGet () throws IOError;
        public abstract void WorkspaceManagerLaunch () throws IOError;
        public abstract void WorkspaceManagerCommandSet (string arg) throws IOError;
        public abstract string WorkspaceManagerCommandGet () throws IOError;
        public abstract void LauncherManagerLaunch () throws IOError;
        public abstract void LauncherManagerCommandSet (string arg) throws IOError;
        public abstract string LauncherManagerCommandGet () throws IOError;
        public abstract void LauncherManagerAutostartSet (string arg) throws IOError;
        public abstract string LauncherManagerAutostartGet () throws IOError;
        public abstract void TerminalManagerLaunch () throws IOError;
        public abstract void TerminalManagerCommandSet (string arg) throws IOError;
        public abstract string TerminalManagerCommandGet () throws IOError;
        public abstract void ScreenshotManagerLaunch () throws IOError;
        public abstract void ScreenshotManagerCommandSet (string arg) throws IOError;
        public abstract string ScreenshotManagerCommandGet () throws IOError;
        public abstract void UpgradeManagerLaunch () throws IOError;
        public abstract void UpgradeManagerCommandSet (string arg) throws IOError;
        public abstract string UpgradeManagerCommandGet () throws IOError;
        public abstract void ClipboardActivate () throws IOError;
        public abstract void ClipboardCommandSet (string arg) throws IOError;
        public abstract string ClipboardCommandGet () throws IOError;
        public abstract void KeymapActivate () throws IOError;
        public abstract void KeymapModeSet (string arg) throws IOError;
        public abstract string KeymapModeGet () throws IOError;
        public abstract void KeymapModelSet (string arg) throws IOError;
        public abstract string KeymapModelGet () throws IOError;
        public abstract void KeymapLayoutSet (string arg) throws IOError;
        public abstract string KeymapLayoutGet () throws IOError;
        public abstract void KeymapVariantSet (string arg) throws IOError;
        public abstract string KeymapVariantGet () throws IOError;
        public abstract void KeymapOptionsSet (string arg) throws IOError;
        public abstract string KeymapOptionsGet () throws IOError;
        public abstract void XrandrActivate () throws IOError;
        public abstract void XrandrModeSet (string arg) throws IOError;
        public abstract string XrandrModeGet () throws IOError;
        public abstract void XrandrCommandSet (string arg) throws IOError;
        public abstract string XrandrCommandGet () throws IOError;
        public abstract void SecurityActivate () throws IOError;
        public abstract void SecurityKeyringSet (string arg) throws IOError;
        public abstract string SecurityKeyringGet () throws IOError;
        public abstract void A11yActivate () throws IOError;
        public abstract void A11yTypeSet (string arg) throws IOError;
        public abstract string A11yTypeGet () throws IOError;
        public abstract void ProxyActivate () throws IOError;
        public abstract void ProxyHttpSet (string arg) throws IOError;
        public abstract string ProxyHttpGet () throws IOError;
        public abstract void UpdatesActivate () throws IOError;
        public abstract void UpdatesTypeSet (string arg) throws IOError;
        public abstract string UpdatesTypeGet () throws IOError;
        public abstract void DisableAutostartSet (string arg) throws IOError;
        public abstract string DisableAutostartGet () throws IOError;
        public abstract void LaptopModeSet (string arg) throws IOError;
        public abstract string LaptopModeGet () throws IOError;
        public abstract void UpstartUserSessionSet (string arg) throws IOError;
        public abstract string UpstartUserSessionGet () throws IOError;
        public abstract void DbusLxdeSet (string arg) throws IOError;
        public abstract string DbusLxdeGet () throws IOError;
        public abstract void DbusGnomeSet (string arg) throws IOError;
        public abstract string DbusGnomeGet () throws IOError;
        public abstract void EnvTypeSet (string arg) throws IOError;
        public abstract string EnvTypeGet () throws IOError;
        public abstract void EnvMenuPrefixSet (string arg) throws IOError;
        public abstract string EnvMenuPrefixGet () throws IOError;
    }

    public class DbusBackend : GLib.Object
    {
        DbusLxsession dbus_lxsession = null;

        public DbusBackend ()
        {
            dbus_lxsession = GLib.Bus.get_proxy_sync(BusType.SESSION,
                                            "org.lxde.SessionManager",
                                            "/org/lxde/SessionManager");
        }

        public void PanelReload()
        {
            try
            {
                dbus_lxsession.PanelReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void PanelCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.PanelCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void PanelSessionSet(string arg)
        {
            try
            {
                dbus_lxsession.PanelSessionSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string PanelCommandGet()
        {
            try
            {
                return dbus_lxsession.PanelCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string PanelSessionGet()
        {
            try
            {
                return dbus_lxsession.PanelSessionGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void DockReload()
        {
            try
            {
                dbus_lxsession.DockReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void DockCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.DockCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void DockSessionSet(string arg)
        {
            try
            {
                dbus_lxsession.DockSessionSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string DockCommandGet()
        {
            try
            {
                return dbus_lxsession.DockCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string DockSessionGet()
        {
            try
            {
                return dbus_lxsession.DockSessionGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void WindowsManagerReload()
        {
            try
            {
                dbus_lxsession.WindowsManagerReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void WindowsManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.WindowsManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void WindowsManagerSessionSet(string arg)
        {
            try
            {
                dbus_lxsession.WindowsManagerSessionSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void WindowsManagerExtrasSet(string arg)
        {
            try
            {
                dbus_lxsession.WindowsManagerExtrasSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string WindowsManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.WindowsManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string WindowsManagerSessionGet()
        {
            try
            {
                return dbus_lxsession.WindowsManagerSessionGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string WindowsManagerExtrasGet()
        {
            try
            {
                return dbus_lxsession.WindowsManagerExtrasGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void ScreensaverReload()
        {
            try
            {
                dbus_lxsession.ScreensaverReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void ScreensaverCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.ScreensaverCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string ScreensaverCommandGet()
        {
            try
            {
                return dbus_lxsession.ScreensaverCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void PowerManagerReload()
        {
            try
            {
                dbus_lxsession.PowerManagerReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void PowerManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.PowerManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string PowerManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.PowerManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void FileManagerReload()
        {
            try
            {
                dbus_lxsession.FileManagerReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void FileManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.FileManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void FileManagerSessionSet(string arg)
        {
            try
            {
                dbus_lxsession.FileManagerSessionSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void FileManagerExtrasSet(string arg)
        {
            try
            {
                dbus_lxsession.FileManagerExtrasSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string FileManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.FileManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string FileManagerSessionGet()
        {
            try
            {
                return dbus_lxsession.FileManagerSessionGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string FileManagerExtrasGet()
        {
            try
            {
                return dbus_lxsession.FileManagerExtrasGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void DesktopReload()
        {
            try
            {
                dbus_lxsession.DesktopReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void DesktopCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.DesktopCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void DesktopWallpaperSet(string arg)
        {
            try
            {
                dbus_lxsession.DesktopWallpaperSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string DesktopCommandGet()
        {
            try
            {
                return dbus_lxsession.DesktopCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string DesktopWallpaperGet()
        {
            try
            {
                return dbus_lxsession.DesktopWallpaperGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void CompositeManagerReload()
        {
            try
            {
                dbus_lxsession.CompositeManagerReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void CompositeManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.CompositeManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void CompositeManagerAutostartSet(string arg)
        {
            try
            {
                dbus_lxsession.CompositeManagerAutostartSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string CompositeManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.CompositeManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string CompositeManagerAutostartGet()
        {
            try
            {
                return dbus_lxsession.CompositeManagerAutostartGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void IM1Reload()
        {
            try
            {
                dbus_lxsession.IM1Reload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void IM1CommandSet(string arg)
        {
            try
            {
                dbus_lxsession.IM1CommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void IM1AutostartSet(string arg)
        {
            try
            {
                dbus_lxsession.IM1AutostartSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string IM1CommandGet()
        {
            try
            {
                return dbus_lxsession.IM1CommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string IM1AutostartGet()
        {
            try
            {
                return dbus_lxsession.IM1AutostartGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void IM2Reload()
        {
            try
            {
                dbus_lxsession.IM2Reload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void IM2CommandSet(string arg)
        {
            try
            {
                dbus_lxsession.IM2CommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void IM2AutostartSet(string arg)
        {
            try
            {
                dbus_lxsession.IM2AutostartSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string IM2CommandGet()
        {
            try
            {
                return dbus_lxsession.IM2CommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string IM2AutostartGet()
        {
            try
            {
                return dbus_lxsession.IM2AutostartGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void Widget1Reload()
        {
            try
            {
                dbus_lxsession.Widget1Reload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void Widget1CommandSet(string arg)
        {
            try
            {
                dbus_lxsession.Widget1CommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void Widget1AutostartSet(string arg)
        {
            try
            {
                dbus_lxsession.Widget1AutostartSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string Widget1CommandGet()
        {
            try
            {
                return dbus_lxsession.Widget1CommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string Widget1AutostartGet()
        {
            try
            {
                return dbus_lxsession.Widget1AutostartGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void PolkitReload()
        {
            try
            {
                dbus_lxsession.PolkitReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void PolkitCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.PolkitCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string PolkitCommandGet()
        {
            try
            {
                return dbus_lxsession.PolkitCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void NetworkGuiReload()
        {
            try
            {
                dbus_lxsession.NetworkGuiReload();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void NetworkGuiCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.NetworkGuiCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string NetworkGuiCommandGet()
        {
            try
            {
                return dbus_lxsession.NetworkGuiCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }
        public void AudioManagerLaunch()
        {
            try
            {
                dbus_lxsession.AudioManagerLaunch();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void AudioManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.AudioManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string AudioManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.AudioManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }
        public void QuitManagerLaunch()
        {
            try
            {
                dbus_lxsession.QuitManagerLaunch();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void QuitManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.QuitManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void QuitManagerImageSet(string arg)
        {
            try
            {
                dbus_lxsession.QuitManagerImageSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void QuitManagerLayoutSet(string arg)
        {
            try
            {
                dbus_lxsession.QuitManagerLayoutSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string QuitManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.QuitManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string QuitManagerImageGet()
        {
            try
            {
                return dbus_lxsession.QuitManagerImageGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public string QuitManagerLayoutGet()
        {
            try
            {
                return dbus_lxsession.QuitManagerLayoutGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void WorkspaceManagerLaunch()
        {
            try
            {
                dbus_lxsession.WorkspaceManagerLaunch();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void WorkspaceManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.WorkspaceManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string WorkspaceManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.WorkspaceManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }
        public void LauncherManagerLaunch()
        {
            try
            {
                dbus_lxsession.LauncherManagerLaunch();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void LauncherManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.LauncherManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string LauncherManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.LauncherManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void LauncherManagerAutostartSet(string arg)
        {
            try
            {
                dbus_lxsession.LauncherManagerAutostartSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string LauncherManagerAutostartGet()
        {
            try
            {
                return dbus_lxsession.LauncherManagerAutostartGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void TerminalManagerLaunch()
        {
            try
            {
                dbus_lxsession.TerminalManagerLaunch();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void TerminalManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.TerminalManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string TerminalManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.TerminalManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }
        public void ScreenshotManagerLaunch()
        {
            try
            {
                dbus_lxsession.ScreenshotManagerLaunch();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void ScreenshotManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.ScreenshotManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string ScreenshotManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.ScreenshotManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void UpgradeManagerLaunch()
        {
            try
            {
                dbus_lxsession.UpgradeManagerLaunch();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void UpgradeManagerCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.UpgradeManagerCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string UpgradeManagerCommandGet()
        {
            try
            {
                return dbus_lxsession.UpgradeManagerCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void ClipboardActivate()
        {
            try
            {
                dbus_lxsession.ClipboardActivate();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void ClipboardCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.ClipboardCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string ClipboardCommandGet()
        {
            try
            {
                return dbus_lxsession.ClipboardCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void KeymapActivate()
        {
            try
            {
                dbus_lxsession.KeymapActivate();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void KeymapModeSet(string arg)
        {
            try
            {
                dbus_lxsession.KeymapModeSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string KeymapModeGet()
        {
            try
            {
                return dbus_lxsession.KeymapModeGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void KeymapModelSet(string arg)
        {
            try
            {
                dbus_lxsession.KeymapModelSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string KeymapModelGet()
        {
            try
            {
                return dbus_lxsession.KeymapModelGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void KeymapLayoutSet(string arg)
        {
            try
            {
                dbus_lxsession.KeymapLayoutSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string KeymapLayoutGet()
        {
            try
            {
                return dbus_lxsession.KeymapLayoutGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void KeymapVariantSet(string arg)
        {
            try
            {
                dbus_lxsession.KeymapVariantSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string KeymapVariantGet()
        {
            try
            {
                return dbus_lxsession.KeymapVariantGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void KeymapOptionsSet(string arg)
        {
            try
            {
                dbus_lxsession.KeymapOptionsSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string KeymapOptionsGet()
        {
            try
            {
                return dbus_lxsession.KeymapOptionsGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void XrandrActivate()
        {
            try
            {
                dbus_lxsession.XrandrActivate();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void XrandrModeSet(string arg)
        {
            try
            {
                dbus_lxsession.XrandrModeSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string XrandrModeGet()
        {
            try
            {
                return dbus_lxsession.XrandrModeGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void XrandrCommandSet(string arg)
        {
            try
            {
                dbus_lxsession.XrandrCommandSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string XrandrCommandGet()
        {
            try
            {
                return dbus_lxsession.XrandrCommandGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void SecurityActivate()
        {
            try
            {
                dbus_lxsession.SecurityActivate();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void SecurityKeyringSet(string arg)
        {
            try
            {
                dbus_lxsession.SecurityKeyringSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string SecurityKeyringGet()
        {
            try
            {
                return dbus_lxsession.SecurityKeyringGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void A11yActivate()
        {
            try
            {
                dbus_lxsession.A11yActivate();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void A11yTypeSet(string arg)
        {
            try
            {
                dbus_lxsession.A11yTypeSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string A11yTypeGet()
        {
            try
            {
                return dbus_lxsession.A11yTypeGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void ProxyActivate()
        {
            try
            {
                dbus_lxsession.ProxyActivate();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void ProxyHttpSet(string arg)
        {
            try
            {
                dbus_lxsession.ProxyHttpSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string ProxyHttpGet()
        {
            try
            {
                return dbus_lxsession.ProxyHttpGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void UpdatesActivate()
        {
            try
            {
                dbus_lxsession.UpdatesActivate();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void UpdatesTypeSet(string arg)
        {
            try
            {
                dbus_lxsession.UpdatesTypeSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string UpdatesTypeGet()
        {
            try
            {
                return dbus_lxsession.UpdatesTypeGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void DisableAutostartSet(string arg)
        {
            try
            {
                dbus_lxsession.DisableAutostartSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string DisableAutostartGet()
        {
            try
            {
                return dbus_lxsession.DisableAutostartGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void LaptopModeSet(string arg)
        {
            try
            {
                dbus_lxsession.LaptopModeSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string LaptopModeGet()
        {
            try
            {
                return dbus_lxsession.LaptopModeGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void UpstartUserSessionSet(string arg)
        {
            try
            {
                dbus_lxsession.UpstartUserSessionSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string UpstartUserSessionGet()
        {
            try
            {
                return dbus_lxsession.UpstartUserSessionGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void DbusLxdeSet(string arg)
        {
            try
            {
                dbus_lxsession.DbusLxdeSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string DbusLxdeGet()
        {
            try
            {
                return dbus_lxsession.DbusLxdeGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void DbusGnomeSet(string arg)
        {
            try
            {
                dbus_lxsession.DbusGnomeSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string DbusGnomeGet()
        {
            try
            {
                return dbus_lxsession.DbusGnomeGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void EnvTypeSet(string arg)
        {
            try
            {
                dbus_lxsession.EnvTypeSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string EnvTypeGet()
        {
            try
            {
                return dbus_lxsession.EnvTypeGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }

        public void EnvMenuPrefixSet(string arg)
        {
            try
            {
                dbus_lxsession.EnvMenuPrefixSet(arg);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string EnvMenuPrefixGet()
        {
            try
            {
                return dbus_lxsession.EnvMenuPrefixGet();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
                return "";
            }
        }
    }
}
