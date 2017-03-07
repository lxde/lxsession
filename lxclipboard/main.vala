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
using Gtk;
#if USE_GTK2
using Unique;
#endif

namespace Lxsession
{
    public class Main: GLib.Object
    {
        public static int main(string[] args)
        {
            Gtk.init (ref args);
#if USE_GTK2
            Unique.App app = new Unique.App("org.lxde.lxclipboard", null);

            if(app.is_running)
            {
                message("lxclipboard is already running. Existing");
                return 0;
            }
#endif
# if USE_GTK3
            Gtk.Application app = new Gtk.Application (
                "org.lxde.lxclipboard",
                GLib.ApplicationFlags.FLAGS_NONE);
            app.register ();

            if(app.is_remote)
            {
                message("lxclipboard is already running. Existing");
                return 0;
            }
#endif

            clipboard_start ();

            /* start main loop */
            new MainLoop().run();

            /* Stop clipboard */
            clipboard_stop ();

            return 0;
        }
    }
}
