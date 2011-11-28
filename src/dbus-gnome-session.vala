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

[DBus(name = "org.gnome.SessionManager")]
public class GnomeSessionServer : Object {
    /* Private field, not exported via D-Bus */
    int counter;
    string not_implemented = "Error, lxsession doesn't implement this API";
    string fallback_method = " Warning, you are using a fallback method, please use methods provided by the org.lxde.SessionManager interface";

    /* Public field, not exported via D-Bus */
    public int status;

    /* Public property, exported via D-Bus */
    public int something { get; set; }

    /* Public signal, exported via D-Bus
     * Can be emitted on the server side and can be connected to on the client side.
     */
    public signal void sig1();
    public signal void SessionOver();
    public signal void SessionRunning();

    /* Public method, exported via D-Bus */
    public void some_method() {
        counter++;
        stdout.printf("heureka! counter = %d\n", counter);
        sig1();  // emit signal
    }
    /* Gnome Session Manager D-Bus API */

    /* Login, Shutdown, Reboot ... API */

    public void Shutdown() {
        var session = new SessionObject();
        session.lxsession_shutdown();
        stdout.printf(fallback_method);
    }
    public async void CanShutdown(out bool is_available) {
        var session = new SessionObject();
        is_available = yield session.lxsession_can_shutdown();
        stdout.printf(fallback_method);
    }

    public void SaveSession() {
       /* TODO To implement */
        stdout.printf(not_implemented);
    }

    public void Logout(uint mode) {
       /* TODO To implement */
       /* 
       0 Normal
       1 No confirmation inferface should be shown.
       2 Forcefully logout.  No confirmation will be shown and any inhibitors will be ignored.
       */
        stdout.printf(not_implemented);
    }

    public void RequestShutdown() {
        var session = new SessionObject();
        session.lxsession_shutdown();
        stdout.printf(fallback_method);
    }

    public void RequestReboot() {
        var session = new SessionObject();
        session.lxsession_restart();
        stdout.printf(fallback_method);
    }

    /* End D-bus API */

}

}
