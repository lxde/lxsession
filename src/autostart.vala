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

using Gee;

namespace Lxsession {

public class LxsessionAutostartConfig: GLib.Object {

    private ArrayList<AppType?> stock_list ;

    public LxsessionAutostartConfig() {

        /* Copy the ArrayList, can't be modify inside constructor */
        stock_list = load_autostart_file();
/*
        foreach (AppType s in stock_list) {
            stdout.printf ("%s\n", s.command);
            stdout.printf ("%s\n", s.guard.to_string());
*/
    }

    public ArrayList<AppType?> load_autostart_file() {

        var file = File.new_for_path (get_config_path ("autostart"));
        var app_list = new ArrayList<AppType?> ();

        stdout.printf ("%s\n", file.get_path());

        if (file.query_exists ()) {

            try {
                var dis = new DataInputStream (file.read ());
                string line;

                while ((line = dis.read_line (null)) != null) {
                if (line[0:1] != "@") {
                        string[] command = line.split_set(" ",0);
                        AppType app = { command[0], command, false, "" };
                        app_list.add (app);

                    }
                    else {
                        var builder = new StringBuilder ();
                        builder.append(line);
                        builder.erase(0,1);
                        string[] command = builder.str.split_set(" ",0);
                        AppType app = { command[0], command, true, "" };
                        app_list.add (app);
                    }
                 }
            } catch (Error e) {
                error ("%s", e.message);
            }

        }

    return app_list;

    }

    public void start_applications() {

        foreach (AppType s in stock_list) {
            var launch_app = new GenericAppObject(s);
            launch_app.launch();
        }

    }

    public void check_dupplicate() {

    /* TODO
    if ("three" in my_set) {    // same as my_set.contains ("three")
    stdout.printf ("heureka\n");
    }
    */

    }
}

}
