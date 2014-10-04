/* 
 *      Copyright 2012 Julien Lavergne <gilir@ubuntu.com>
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

/* TODO Implement multiple request by using the inhib_cookie in a array
        and to remove the cookie when the application request it
*/

namespace Lxsession
{
    public class ControlObject: GLib.Object
    {
        public void set_status_busy (uint toplevel_xid)
        /* Status : Busy doing something, disable idle behavior of application */
        {
            inhib_screensaver (toplevel_xid);
        }

        public void exit_status_busy ()
        {
            uninhibit_screensaver ();
        }

        public void inhib_screensaver (uint toplevel_xid)
        {
            string create_command = "xdg-screensaver suspend" + " " + toplevel_xid.to_string();
            lxsession_spawn_command_line_async(create_command);
            message("Inhib Screensaver");
        }

        public void uninhibit_screensaver ()
        {
            lxsession_spawn_command_line_async("xdg-screensaver reset");
            message("Disable Inhib Screensaver");
        }
    }
}
