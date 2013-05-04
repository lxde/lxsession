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
            dbus_lxsession.PanelReload();
        }

        public void PanelCommandSet(string arg)
        {
            dbus_lxsession.PanelCommandSet(arg);
        }

        public void PanelSessionSet(string arg)
        {
            dbus_lxsession.PanelSessionSet(arg);
        }

        public string PanelCommandGet()
        {
            return dbus_lxsession.PanelCommandGet();
        }

        public string PanelSessionGet()
        {
            return dbus_lxsession.PanelSessionGet();
        }
    }
}
