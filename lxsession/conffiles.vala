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

        public string Openbox_dest = Path.build_filename(Environment.get_user_config_dir(),"openbox", "lubuntu.xml");
        public string Qt_dest = Path.build_filename(Environment.get_user_config_dir(),"Trolltech.conf");
        public string Leafpad_dest = Path.build_filename(Environment.get_user_config_dir(),"leafpad","leafpadrc");
       // public string XScreensaver_dest = Path.build_filename(Environment.get_user_home(),".xscreensaver");

        public ConffilesObject(string conffiles_conf)
        {
            /* Constructor */
            kf = load_keyfile (conffiles_conf);
        }

        public void copy_file (string source_path, string dest_path)
        {
            File source_file = File.new_for_path (source_path);
            File dest_file = File.new_for_path (dest_path);
            if (!dest_file.query_exists ())
            {
                /*TODO Create sub directories ?*/
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
        public string load_dest_path(string config_type)
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
        public void copy_conf (string config_type, string source_path)
        {
            if (this.kf.has_group (config_type))
            {
                copy_file(source_path, load_dest_path(config_type));
            }
        }
        public void apply ()
        {
            copy_conf ("Openbox", Openbox_dest);
            copy_conf ("Qt", Qt_dest);
            copy_conf ("Leafpad", Leafpad_dest);
            //copy_conf ("XScreensaver", XScreensaver_dest);
        }
    }
}
