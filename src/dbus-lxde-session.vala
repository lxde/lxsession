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

    public void KeymapLayout (string layout)
    {
        message ("Signal update keymap: %s", layout);
        global_sig.update_keymap_layout(layout);
    }
}

}
