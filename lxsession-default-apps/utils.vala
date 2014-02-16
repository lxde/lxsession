     /* 
    Copyright 2013 Julien Lavergne <gilir@ubuntu.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace LDefaultApps
{
    public class LDefaultAppsSignals : Object
    {
        public signal void update_ui();
    }

    KeyFile load_key_conf (string config_path_directory, string conf_name)
    {
        KeyFile kf = new KeyFile();
        var config_directory_file = File.new_for_path (config_path_directory);

        message("config_path_directory: %s", config_path_directory);

        string config_path = Path.build_filename(config_path_directory, conf_name);
        var config_file = File.new_for_path (config_path);

        if (!config_directory_file.query_exists ())
        {
            try
            {
                config_directory_file.make_directory_with_parents();
            }
            catch (GLib.Error e)
            {
                GLib.stderr.printf ("Could not write settings: %s\n", e.message);
            }
        }

        if (!config_file.query_exists ())
        {
            try
            {
                config_file.create (FileCreateFlags.PRIVATE);
            }
            catch (GLib.Error e)
            {
                GLib.stderr.printf ("Could not write settings: %s\n", e.message);
            }
        }

        try
        {  
            kf.load_from_file(config_path, KeyFileFlags.NONE);
        }
        catch (KeyFileError err)
        {
            warning (err.message);
        }
        catch (FileError err)
        {
            warning (err.message);
        }

        return kf;
    }
}
