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

public class SessionObject: Object {

    public ConsoleKitObject dbus_interface;

    public SessionObject()
    {
        try
        {
            dbus_interface = GLib.Bus.get_proxy_sync(   BusType.SYSTEM,
                                                        "org.freedesktop.ConsoleKit",
                                                        "/org/freedesktop/ConsoleKit/Manager");
        }
        catch (IOError e)
        {
            message ("Could not register service\n");
        }
    }

    public async bool lxsession_can_shutdown() {
        bool can_shutdown_available = false;
        try {
            can_shutdown_available = yield dbus_interface.can_stop ();
        }
        catch (IOError err) {
            warning ("%s", err.message);
            can_shutdown_available = false;
        }
        return can_shutdown_available;

    }

    public void lxsession_shutdown() {
        try {
            dbus_interface.stop ();
        }
        catch (IOError err) {
            warning ("%s", err.message);
        }
    }

    public void lxsession_restart() {
        try {
            dbus_interface.restart ();
        }
        catch (IOError err) {
            warning ("%s", err.message);
        }
    }

}

[DBus (name = "org.freedesktop.ConsoleKit.Manager")]
public interface ConsoleKitObject: Object {
    public const string UNIQUE_NAME = "org.freedesktop.ConsoleKit";
    public const string OBJECT_PATH = "/org/freedesktop/ConsoleKit/Manager";
    public const string INTERFACE_NAME = "org.freedesktop.ConsoleKit.Manager";
    
    public abstract void restart () throws IOError;
    public abstract void stop () throws IOError;
    public abstract async bool can_restart () throws IOError;
    public abstract async bool can_stop () throws IOError;
}

void on_bus_aquired (DBusConnection conn) {
    try {
        conn.register_object ("/org/lxde/SessionManager", new LxdeSessionServer());
    } catch (IOError e) {
        stderr.printf ("Could not register service\n");
    }
}

void on_gnome_bus_aquired (DBusConnection conn) {
    try {
        conn.register_object ("/org/gnome/SessionManager", new GnomeSessionServer());
    } catch (IOError e) {
        stderr.printf ("Could not register service\n");
    }
}

}
