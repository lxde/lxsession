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

namespace Lxsession {

public class LxsessionAutostartConfig: GLib.Object {

    private Array<AppType?> stock_list ;

    public LxsessionAutostartConfig() {

        /* Copy the Array, can't be modify inside constructor */
        stock_list = load_autostart_file();
/*
        foreach (AppType s in stock_list) {
            stdout.printf ("%s\n", s.command);
            stdout.printf ("%s\n", s.guard.to_string());
*/
    }

    public Array<AppType?> load_autostart_file() {

        var file = File.new_for_path (get_config_path ("autostart"));
        var app_list = new Array<AppType?> ();

        message ("Autostart path : %s", file.get_path());

        if (file.query_exists ()) {

            try {
                var dis = new DataInputStream (file.read ());
                string line;

                while ((line = dis.read_line (null)) != null)
                {
                    string first = line[0:1];

                    switch (first)
                    {
                        case ("@"):
                            var builder = new StringBuilder ();
                            builder.append(line);
                            builder.erase(0,1);
                            string[] command = builder.str.split_set(" ",0);
                            AppType app = { command[0], command, true, "" };
                            app_list.append_val (app);
                            break;
                        case ("#"):
                            /* Commented, skip */
                            break;
                        default:
                            string[] command = line.split_set(" ",0);
                            AppType app = { command[0], command, false, "" };
                            app_list.append_val (app);
                            break;
                    }
                 }
            } catch (Error e) {
                error ("%s", e.message);
            }

        }

    return app_list;

    }

    public void start_applications() {

        for (int i = 0; i < stock_list.length; ++i) {
            unowned AppType s = stock_list.index(i);
            var launch_app = new GenericAppObject(s);
            launch_app.launch();
        }

    }

    public void check_dupplicate() {

    /* TODO Check if the application is already autostarted before trying to autostart it
    if ("three" in my_set) {    // same as my_set.contains ("three")
    stdout.printf ("heureka\n");
    }
    */

    }
}

}
