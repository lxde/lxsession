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

const string GETTEXT_PACKAGE = "lxsession";

namespace Lxsession
{
    public class Main: GLib.Object
    {
        public static int main(string[] args)
        {
            Intl.textdomain(GETTEXT_PACKAGE);
            Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");

            Gtk.init (ref args);
            GLib.Application app = new GLib.Application (
                "org.lxde.lxpolkit",
                GLib.ApplicationFlags.FLAGS_NONE);
            app.register ();

            if(app.is_remote)
            {
                message(_("lxpolkit is already running. Existing"));
                return 0;
            }

            policykit_agent_init();

            /* start main loop */
            new MainLoop().run();

            /* Stop polkit agent */
            policykit_agent_finalize();

            return 0;
        }
    }
}
