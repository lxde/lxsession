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
        public abstract string SessionGet (string key1, string? key2) throws IOError;
        public abstract void SessionSet (string key1, string? key2, string command_to_set) throws IOError;
        public abstract void SessionLaunch (string name, string option) throws IOError;
        public abstract string[] SessionSupport () throws IOError;
        public abstract string[] SessionSupportDetail (string key1) throws IOError;

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
        public abstract void LaptopModeSet (string arg) throws IOError;
        public abstract string LaptopModeGet () throws IOError;
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
            try
            {
                dbus_lxsession = GLib.Bus.get_proxy_sync(BusType.SESSION,
                                            "org.lxde.SessionManager",
                                            "/org/lxde/SessionManager");
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string SessionGet (string key1, string? key2)
        {
            string return_value = null;
            try
            {
                return_value = dbus_lxsession.SessionGet(key1, key2);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
            return return_value;
        }

        public void SessionLaunch (string name, string option)
        {
            try
            {
                dbus_lxsession.SessionLaunch(name, option);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public void SessionSet (string key1, string? key2, string command_to_set)
        {
            try
            {
                dbus_lxsession.SessionSet(key1, key2, command_to_set);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string[] SessionSupport ()
        {
            string[] return_value = null;
            try
            {
                return_value = dbus_lxsession.SessionSupport();
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
            return return_value;
        }

        public string[] SessionSupportDetail (string key1)
        {
            string[] return_value = null;
            try
            {
                return_value = dbus_lxsession.SessionSupportDetail(key1);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
            return return_value;
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
