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
        public abstract void KeymapSet (string key1, string? key2, string command_to_set) throws IOError;
        public abstract string KeymapGet (string key1, string? key2) throws IOError;

        public abstract void StateSet (string key1, string? key2, string command_to_set) throws IOError;
        public abstract string StateGet (string key1, string? key2) throws IOError;

        public abstract void DbusSet (string key1, string? key2, string command_to_set) throws IOError;
        public abstract string DbusGet (string key1, string? key2) throws IOError;

        public abstract void EnvironmentSet (string key1, string? key2, string command_to_set) throws IOError;
        public abstract string EnvironmentGet (string key1, string? key2) throws IOError;
    }

    public class DbusBackend : GLib.Object
    {
        DbusLxsession dbus_lxsession = null;
        string dbus_type = null;

        public DbusBackend (string type)
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

            if (type == null)
            {
                dbus_type = "session";
            }
            else
            {
                dbus_type = type;
            }
        }

        public string Get (string key1, string? key2)
        {
            string return_value = "";

            switch (dbus_type)
            {
                case "session":
                    return_value = SessionGet (key1, key2);
                    break;
            }

            return return_value;
        }

        public void Set (string key1, string? key2, string command_to_set)
        {
            switch (dbus_type)
            {
                case "session":
                    SessionSet (key1, key2, command_to_set);
                    break;
            }
        }

        public void Launch (string name, string option)
        {
            switch (dbus_type)
            {
                case "session":
                    SessionLaunch (name, option);
                    break;
            }
        }


        public string SessionGet (string key1, string? key2)
        {
            string return_value = null;
            if (key2 == null)
            {
                key2 = "";
            }
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
            if (key2 == null)
            {
                key2 = "";
            }
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

        public void KeymapSet(string key1, string? key2, string command_to_set)
        {
            if (key2 == null)
            {
                key2 = "";
            }
            try
            {
                dbus_lxsession.KeymapSet(key1, key2, command_to_set);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string KeymapGet(string key1, string? key2)
        {
            if (key2 == null)
            {
                key2 = "";
            }
            string return_value = null;
            try
            {
                return_value = dbus_lxsession.KeymapGet(key1, key2);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
            return return_value;
        }

        public void StateSet(string key1, string? key2, string command_to_set)
        {
            if (key2 == null)
            {
                key2 = "";
            }
            try
            {
                dbus_lxsession.StateSet(key1, key2, command_to_set);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string StateGet(string key1, string? key2)
        {
            string return_value = null;
            if (key2 == null)
            {
                key2 = "";
            }
            try
            {
                return_value = dbus_lxsession.StateGet(key1, key2);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
            return return_value;
        }

        public void DbusSet(string key1, string? key2, string command_to_set)
        {
            if (key2 == null)
            {
                key2 = "";
            }
            try
            {
                dbus_lxsession.DbusSet(key1, key2, command_to_set);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string DbusGet(string key1, string? key2)
        {
            string return_value = null;
            if (key2 == null)
            {
                key2 = "";
            }
            try
            {
                return_value = dbus_lxsession.DbusGet(key1, key2);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
            return return_value;
        }

        public void EnvironmentSet(string key1, string? key2, string command_to_set)
        {
            if (key2 == null)
            {
                key2 = "";
            }
            try
            {
                dbus_lxsession.EnvironmentSet(key1, key2, command_to_set);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
        }

        public string EnvironmentGet(string key1, string? key2)
        {
            string return_value = null;
            if (key2 == null)
            {
                key2 = "";
            }
            try
            {
                return_value = dbus_lxsession.EnvironmentGet(key1, key2);
            }
            catch (GLib.IOError err)
            {
                warning (err.message);
            }
            return return_value;
        }
    }
}
