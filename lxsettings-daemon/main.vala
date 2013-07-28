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
public class Main: GLib.Object
{
        static bool persistent = false;
        static string file = null;

        const OptionEntry[] option_entries = {
        { "file", 'f', 0, OptionArg.STRING, ref file, "path of the configuration file", "NAME" },
        { "persistent", 'p', 0, OptionArg.NONE, ref persistent, "reload configuration on file change", null },
        { null }
        };

    public static int main(string[] args)
    {
        if (file == null)
        {
            critical("Error, you need to specify a configuration file using -f argument. Exit");
            return -1;
        }
        else
        {
            KeyFile kf = new KeyFile();

            try
            {
                kf.load_from_file(file, KeyFileFlags.NONE);
            }
            catch (KeyFileError err)
            {
                warning (err.message);
                critical("Problem when loading the configuration file. Exit");
                return -1;
            }
            catch (FileError err)
            {
                warning (err.message);
                critical("Problem when loading the configuration file. Exit");
                return -1;
            }

            /* Start settings daemon */
            settings_daemon_start(kf);

            if (persistent == false)
            {
                /* Nothing to do, just exit */
                return 0;
            }
            else
            {
                /* TODO Monitor desktop file change and reload on modification change */
                return 0;
            }
        }
    }
}
