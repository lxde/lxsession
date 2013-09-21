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

namespace Lxsession
{
    public class ConffilesObject: GLib.Object
    {

        public KeyFile kf;

        public string Openbox_dest;
        public string Qt_dest = Path.build_filename(Environment.get_user_config_dir(),"Trolltech.conf");
        public string Leafpad_dest = Path.build_filename(Environment.get_user_config_dir(),"leafpad","leafpadrc");
        public string Lxterminal_dest = Path.build_filename(Environment.get_user_config_dir(),"lxterminal","lxterminal.conf");
        public string XScreensaver_dest = Path.build_filename(Environment.get_home_dir(),".xscreensaver");
        public string libfm_dest = Path.build_filename(Environment.get_user_config_dir(),"libfm","libfm.conf");
        public string cairo_dock_dest = Path.build_filename(Environment.get_user_config_dir(),"cairo-dock","cairo-dock.conf");


        public ConffilesObject(string conffiles_conf)
        {
            /* Constructor */
            kf = load_keyfile (conffiles_conf);
            if (global_settings.get_item_string("Session", "windows_manager", "command") == "openbox")
            {
                if (global_settings.get_item_string("Session", "windows_manager", "session") == "LXDE")
                {
                    Openbox_dest = Path.build_filename(Environment.get_user_config_dir(),"openbox", "lxde-rc.xml");
                }
                else if (global_settings.get_item_string("Session", "windows_manager", "session") == "Lubuntu")
                    {
                        Openbox_dest = Path.build_filename(Environment.get_user_config_dir(),"openbox", "lubuntu-rc.xml");
                    }
            }
            else
            {
                    Openbox_dest = Path.build_filename(Environment.get_user_config_dir(),"openbox", "lxde-rc.xml");
            }
        }

        public void copy_file (string source_path, string dest_path)
        {
            File source_file = File.new_for_path (source_path);
            File dest_file = File.new_for_path (dest_path);
            File dest_directory = dest_file.get_parent();

            if (!dest_file.query_exists ())
            {
                if (!dest_directory.query_exists ())
                {
                    try
                    {
                        dest_directory.make_directory_with_parents();
                    }
                    catch (GLib.Error err)
                    {
                        message (err.message);
                    }
                }

                try
                {
                    source_file.copy(dest_file, FileCopyFlags.NONE, null);
                }
                catch (GLib.Error err)
                {
                    message (err.message);
                }
            }
        }
        public string load_source_path(string config_type)
        {
            string source;
            try
            {
                 source = this.kf.get_value (config_type, "source");
                 return source;
            }
            catch (KeyFileError err)
            {
    		    message (err.message);
                return "";
            }
        }
        public void copy_conf (string config_type, string dest_path)
        {
            if (this.kf.has_group (config_type))
            {
                copy_file(load_source_path(config_type), dest_path);
            }
        }
        public void apply ()
        {
            copy_conf ("Openbox", Openbox_dest);
            copy_conf ("Qt", Qt_dest);
            copy_conf ("Leafpad", Leafpad_dest);
            copy_conf ("Lxterminal", Lxterminal_dest);
            copy_conf ("XScreensaver", XScreensaver_dest);
            copy_conf ("libfm", libfm_dest);
            copy_conf ("cairo-dock", cairo_dock_dest);
        }
    }
}
