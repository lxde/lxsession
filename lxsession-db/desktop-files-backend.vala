/* 
    Copyright 2012 Julien Lavergne <gilir@ubuntu.com>

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

namespace Lxsession
{
    [DBus(name = "org.lxde.SessionManager")]
    public interface DbusLxsession : GLib.Object
    {
        public abstract void MimeFoldersInstalledSet (string[] arg) throws IOError;
        public abstract void MimeFoldersAvailableSet (string[] arg) throws IOError;
        public abstract string[] MimeFoldersInstalledGet () throws IOError;
        public abstract string[] MimeFoldersAvailableGet () throws IOError;


        public abstract void MimeWebbrowserInstalledSet (string[] arg) throws IOError;
        public abstract void MimeWebbrowserAvailableSet (string[] arg) throws IOError;
        public abstract void MimeEmailInstalledSet (string[] arg) throws IOError;
        public abstract void MimeEmailAvailableSet (string[] arg) throws IOError;
    }

    public class DBDefaultApps: GLib.Object
    {
        public List<string> webbrowser_installed = new List<string> ();
        public List<string> webbrowser_available = new List<string> ();
        public string webbrowser_installed_blacklist;

        public List<string> email_installed = new List<string> ();
        public List<string> email_available = new List<string> ();
        public string email_installed_blacklist;

        public signal void finish_scanning_installed();
        public signal void finish_scanning_available();
        public signal void exit_now();

        public bool state_installed = false;
        public bool state_available = false;

        DbusLxsession dbus_lxsession = null;

        string mode;

        public DBDefaultApps(string mode_argument)
        {
            webbrowser_installed_blacklist = "lxde-x-www-browser.desktop;";
            email_installed_blacklist = "";

            dbus_lxsession = GLib.Bus.get_proxy_sync(BusType.SESSION,
                                            "org.lxde.SessionManager",
                                            "/org/lxde/SessionManager");
            if (mode_argument == null)
            {
                this.mode = "display";
            }
            else
            {
                this.mode = mode_argument;
            }
        }

        public void on_finish_scanning_installed()
        {
            message("Signal finish scanning with mode: %s",this.mode);
            if (this.mode == "display")
            {
                print_values_installed ();
            }
            else if (this.mode == "write")
            {
                save_values_installed();
            }

            this.state_installed = true;

            if (this.state_available == true)
            {
                exit_now();
            }
        }

        public void on_finish_scanning_available()
        {
            message("Signal finish scanning with mode: %s",this.mode);
            if (this.mode == "display")
            {
                global_db.print_values_available ();
            }
            else if (this.mode == "write")
            {
                global_db.save_values_available();
            }

            this.state_available = true;

            if (this.state_installed == true)
            {
                exit_now();
            }
        }

        public void update_installed ()
        {
            string[] default_install = null;

            try
            {
                default_install = dbus_lxsession.MimeFoldersInstalledGet();
            }
            catch (GLib.IOError e)
            {
                message(e.message);
            }

            if (default_install != null)
            {
                foreach (string folder in default_install)
                {
                    list_desktop_files.begin (folder, "installed");
                }
            }
            else
            {
                message ("No folders installed set. Abort");
            }
        }

        public void update_available ()
        {
            string[] default_available = null;

            try
            {
                default_available = dbus_lxsession.MimeFoldersAvailableGet();
            }
            catch (GLib.IOError e)
            {
                message(e.message);
            }

            if (default_available != null)
            {
                foreach (string folder in default_available)
                {
                    list_desktop_files.begin (folder, "available");
                }
            }
            else
            {
                message ("No folders available set. Abort");
            }
        }

        public void update ()
        {
            update_installed();
            finish_scanning_installed.connect(on_finish_scanning_installed);

            update_available();
            finish_scanning_available.connect(on_finish_scanning_available);
        }

        private async void list_desktop_files (string path, string mode)
        {
            message ("Start scanning\n");
            var dir = File.new_for_path (path);
            try
            {
                KeyFile kf = new KeyFile();
                /* asynchronous call, to get directory entries */
                var e = yield dir.enumerate_children_async (FileAttribute.STANDARD_NAME,
                                                            0, Priority.DEFAULT);
                while (true)
                {
                    /* asynchronous call, to get entries so far */
                    var files = yield e.next_files_async (10, Priority.DEFAULT);
                    if (files == null)
                    {
                        break;
                    }
                    /* append the files found so far to the list */
                    foreach (var info in files)
                    {
                        try
                        {
                            string desktop_path = Path.build_filename(path, info.get_name());
                            kf.load_from_file(desktop_path, KeyFileFlags.NONE);

                            if (kf.has_key("Desktop Entry", "Categories") == true)
                            {

                                /* Sorting the results */
                                if (mode == "installed")
                                {
                                    find_webbrowser_list(kf, desktop_path, info.get_name(), webbrowser_installed);
                                    find_email_list(kf, desktop_path, info.get_name(), email_installed);
                                }
                                else if (mode == "available")
                                {
                                    find_webbrowser_list(kf, desktop_path, info.get_name(), webbrowser_available);
                                    find_email_list(kf, desktop_path, info.get_name(), email_available);
                                }
                            }
                        }
                        catch (KeyFileError err)
                        {
                            /* No entry, just pass */;
                        }
                        catch (FileError err)
                        {
                            warning (err.message);
                        }
                    }
                }
            } 
            catch (Error err)
            {
                stderr.printf ("Error: list_files failed: %s\n", err.message);
            }
            message ("Finishing scanning\n");

            if (mode == "installed")
            {
                finish_scanning_installed();
            }
            else if (mode == "available")
            {
                finish_scanning_available();
            }
        }

        /* TODO Make a genereic find_ function ? */

        private void find_webbrowser_list(KeyFile kf, string desktop_path, string name, List<string> list)
        {
            try
            {
                if (name in webbrowser_installed_blacklist)
                {
                    /* Blacklisted, not in the list */
                }
                else
                {
                    string categories = kf.get_value ("Desktop Entry", "Categories");
                    if (categories != null)
                    {
                        if ("WebBrowser" in categories)
                        {
                            list.append (name);
                        }
                    }
                }
            }
            catch (KeyFileError err)
            {
                /* No entry, just pass */;
            }
        }

        private void find_email_list(KeyFile kf, string desktop_path, string name, List<string> list)
        {
            try
            {
                if (name in email_installed_blacklist)
                {
                    /* Blacklisted, not in the list */
                }
                else
                {
                    string categories = kf.get_value ("Desktop Entry", "Categories");
                    if (categories != null)
                    {
                        if ("Email" in categories)
                        {
                            list.append (name);
                        }
                    }
                }
            }
            catch (KeyFileError err)
            {
                /* No entry, just pass */;
            }
        }

        public string[] string_array_list_to_array (List<string> list)
        {
            string tmp_string = null;
            string[] array_save;

            foreach (string entry in list)
            {
                if (tmp_string == null)
                {
                    tmp_string = entry + ";";
                }
                else
                {
                    tmp_string = tmp_string + entry + ";";
                }
            }

            if (tmp_string != null)
            {
                array_save = tmp_string.split_set(";",0);
            }
            else
            {
                array_save = {};
            }

            return array_save;
        }

        /* Debug */

        public void print_values_available ()
        {
            message ("Printing available webbrowser");
	        foreach (string entry in webbrowser_available)
            {
		        message(entry);
	        }

            message ("Printing available email");
	        foreach (string entry in email_available)
            {
		        message(entry);
	        }
        }

        public void print_values_installed ()
        {
            message ("Printing installed webbrowser");
	        foreach (string entry in webbrowser_installed)
            {
		        message(entry);
	        }

            message ("Printing installed email");
	        foreach (string entry in email_installed)
            {
		        message(entry);
	        }
        }

        public void save_values_installed ()
        {
            try
            {
                dbus_lxsession.MimeWebbrowserInstalledSet(string_array_list_to_array(webbrowser_installed));
                dbus_lxsession.MimeEmailInstalledSet(string_array_list_to_array(email_installed));
            }
            catch (GLib.IOError e)
            {
                message(e.message);
            }
        }

        public void save_values_available ()
        {
            try
            {
                dbus_lxsession.MimeWebbrowserAvailableSet(string_array_list_to_array(webbrowser_available));
                dbus_lxsession.MimeEmailAvailableSet(string_array_list_to_array(email_available));
            }
            catch (GLib.IOError e)
            {
                message(e.message);
            }
        }
    }
}
