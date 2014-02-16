/* 
 *      Copyright 2013 Julien Lavergne <gilir@ubuntu.com>
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
    DBDefaultApps global_db;

    public class Main: GLib.Object
    {
        //static string settings = "";
        static string mode = "";
        //static string backend = "";

        const OptionEntry[] option_entries = {
//        { "settings", 's', 0, OptionArg.STRING, ref mode, "specify the settings to read (default to lxsession)", "NAME" },
        { "mode", 'm', 0, OptionArg.STRING, ref mode, "specify the mode to launch (display or write)", "NAME" },
//        { "backend", 'b', 0, OptionArg.STRING, ref mode, "specify the backend to write (default to lxsession-default-apps)", "NAME" },
        { null }
        };

        public static int main(string[] args)
        {
            try
            {
                var options_args = new OptionContext("- Lxsession database utility");
                options_args.set_help_enabled(true);
                options_args.add_main_entries(option_entries, null);
                options_args.parse(ref args);
            }
            catch (OptionError e)
            {
                critical ("Option parsing failed: %s\n", e.message);
                return -1;
            }

            Gtk.init (ref args);

            /* Init */
            var db = new DBDefaultApps(mode);
            global_db = db;

            global_db.update();

            var loop = new MainLoop();

            global_db.exit_now.connect(loop.quit);

            /* start main loop */
            loop.run();

            return 0;
        }
    }
}
