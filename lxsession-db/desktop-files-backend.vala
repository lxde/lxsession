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
    public class DBDefaultApps: GLib.Object
    {
        public List<string> webbrowser_installed = new List<string> ();
        public List<string> webbrowser_available = new List<string> ();
        public string webbrowser_installed_blacklist;

        public List<string> email_installed = new List<string> ();
        public List<string> email_available = new List<string> ();
        public string email_installed_blacklist;

        public List<string> file_manager_installed = new List<string> ();
        public List<string> file_manager_available = new List<string> ();
        public string file_manager_blacklist;

        public string screensaver_blacklist;
        public List<string> screensaver_installed = new List<string> ();
        public List<string> screensaver_available = new List<string> ();

        public string composite_manager_blacklist;
        public List<string> composite_manager_installed = new List<string> ();
        public List<string> composite_manager_available = new List<string> ();

        public string desktop_manager_blacklist;
        public List<string> desktop_manager_installed = new List<string> ();
        public List<string> desktop_manager_available = new List<string> ();

        public string power_manager_blacklist;
        public List<string> power_manager_installed = new List<string> ();
        public List<string> power_manager_available = new List<string> ();

        public string polkit_blacklist;
        public List<string> polkit_installed = new List<string> ();
        public List<string> polkit_available = new List<string> ();

        public string im_blacklist;
        public List<string> im_installed = new List<string> ();
        public List<string> im_available = new List<string> ();

        public string widget_blacklist;
        public List<string> widget_installed = new List<string> ();
        public List<string> widget_available = new List<string> ();

        public string terminal_manager_blacklist;
        public List<string> terminal_manager_installed = new List<string> ();
        public List<string> terminal_manager_available = new List<string> ();

        public string audio_blacklist;
        public List<string> audio_installed = new List<string> ();
        public List<string> audio_available = new List<string> ();

        public string video_blacklist;
        public List<string> video_installed = new List<string> ();
        public List<string> video_available = new List<string> ();

        public string audio_video_blacklist;

        public string viewer_blacklist;

        public List<string> image_display_installed = new List<string> ();
        public List<string> pdf_reader_installed = new List<string> ();

        public List<string> image_display_available = new List<string> ();
        public List<string> pdf_reader_available = new List<string> ();

        public string text_editor_blacklist;
        public List<string> text_editor_installed = new List<string> ();
        public List<string> text_editor_available = new List<string> ();

        public string archive_blacklist;
        public List<string> archive_installed = new List<string> ();
        public List<string> archive_available = new List<string> ();

        public string spreadsheet_blacklist;
        public List<string> spreadsheet_installed = new List<string> ();
        public List<string> spreadsheet_available = new List<string> ();

        public string bittorent_blacklist;
        public List<string> bittorent_installed = new List<string> ();
        public List<string> bittorent_available = new List<string> ();

        public string document_blacklist;
        public List<string> document_installed = new List<string> ();
        public List<string> document_available = new List<string> ();

        public string burn_blacklist;
        public List<string> burn_installed = new List<string> ();
        public List<string> burn_available = new List<string> ();

        public string tasks_blacklist;
        public List<string> tasks_installed = new List<string> ();
        public List<string> tasks_available = new List<string> ();

        public signal void finish_scanning_installed();
        public signal void finish_scanning_available();
        public signal void exit_now();

        public bool state_installed = false;
        public bool state_available = false;

        /* For now, hardcoding the values */
        string[] MimeFoldersInstalledGet = {"/usr/share/applications"};
        string[] MimeFoldersAvailableGet = {"/usr/share/app-install/desktop"};

        string mode;

        /* Configuration file */
        KeyFile kf;
        string config_path ;

        public DBDefaultApps(string mode_argument)
        {
            init();
            if (mode_argument == null)
            {
                this.mode = "display";
            }
            else
            {
                this.mode = mode_argument;
            }
        }

        public void init()
        {
            webbrowser_installed_blacklist = "lxde-x-www-browser.desktop;";
            email_installed_blacklist = "";
            file_manager_blacklist = "";
            screensaver_blacklist = "";
            composite_manager_blacklist = "";
            desktop_manager_blacklist = "";
            power_manager_blacklist = "";
            polkit_blacklist = "";
            im_blacklist = "";
            widget_blacklist = "";
            terminal_manager_blacklist = "";
            audio_blacklist = "";
            video_blacklist = "";
            audio_video_blacklist = "";
            viewer_blacklist = "";
            text_editor_blacklist = "";
            archive_blacklist = "";
            spreadsheet_blacklist = "";
            bittorent_blacklist = "";
            document_blacklist = "";
            burn_blacklist = "";
            tasks_blacklist = "";

            config_path = Path.build_filename(Environment.get_user_config_dir (),"lxsession-default-apps","settings.conf");

            kf = new KeyFile();

            message("test config_path: %s", config_path);

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
        }

        public void on_finish_scanning_installed()
        {
            message("Signal finish scanning installed with mode: %s",this.mode);
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
            message("Signal finish scanning available with mode: %s",this.mode);
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

            default_install = MimeFoldersInstalledGet;

            if (default_install != null)
            {
                foreach (string folder in default_install)
                {
                    message ("Scanning folder: %s", folder);
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

            default_available = MimeFoldersAvailableGet;

            if (default_available != null)
            {
                foreach (string folder in default_available)
                {
                    var dir_log = File.new_for_path (folder);
                    if (dir_log.query_exists ())
                    {
                        message ("Scanning folder: %s", folder);
                        list_desktop_files.begin (folder, "available");
                    }
                    else
                    {
                        message ("%s doesn't exist. Pass", folder);
                        finish_scanning_available();
                    }
                }
            }
            else
            {
                message ("No folders available set. Abort");
            }
        }

        public void update ()
        {
            finish_scanning_installed.connect(on_finish_scanning_installed);
            finish_scanning_available.connect(on_finish_scanning_available);

            update_installed();
            update_available();
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
                                find_list(kf, desktop_path, info.get_name(), mode);
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

                if (mode == "installed")
                {
                    finish_scanning_installed();
                }
                else if (mode == "available")
                {
                    finish_scanning_available();
                }

            } 
            catch (Error err)
            {
                stderr.printf ("Error: list_files failed: %s\n", err.message);
            }
            message ("Finishing scanning\n");
        }

        public string create_entry(KeyFile kf, string desktop_path)
        {
            /* Create the entry in the list :
                Name,exec,icon_name,desktop_path,install_package
            */

            string entry = "";
            string tmp_name = "";
            string tmp_icon = "";
            string tmp_install_package = "";

            try
            {
                tmp_name = kf.get_locale_string ("Desktop Entry", "Name");
            }
            catch (GLib.KeyFileError e)
            {
                /* Incomplete desktop file, just pass */
            }

            try
            {
                tmp_icon = kf.get_value ("Desktop Entry", "Icon");
            }
            catch (GLib.KeyFileError e)
            {
                /* Incomplete desktop file, just pass */
            }

            try
            {
                tmp_install_package = kf.get_value ("Desktop Entry", "X-AppInstall-Package");
            }
            catch (GLib.KeyFileError e)
            {
                /* Not a available desktop file, just pass */
            }

            entry = tmp_name + "," + create_exec_string(kf) + "," + tmp_icon + "," + desktop_path + "," + tmp_install_package;

            return entry;

        }

        public string create_exec_string (KeyFile kf)
        {
            string tmp_string = "";
            try
            {
                tmp_string = kf.get_value ("Desktop Entry", "Exec");
            }
            catch (GLib.KeyFileError e)
            {
                /* Not a available desktop file, just pass */
            }
            string[] tmp_value = tmp_string.split_set(" ",0);
            return tmp_value[0];
        }

        public void find_list(KeyFile kf, string desktop_path, string name, string mode)
        {
            try
            {
                string categories = kf.get_value ("Desktop Entry", "Categories");
                if (categories != null)
                {
                    if ("WebBrowser" in categories)
                    {
                        if (name in webbrowser_installed_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                webbrowser_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                webbrowser_available.append(new_entry);
                            }
                        }
                    }

                    if ("Email" in categories)
                    {
                        if (name in email_installed_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                email_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                email_available.append(new_entry);
                            }
                        }
                    }

                    if ("FileManager" in categories)
                    {
                        if (name in file_manager_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                file_manager_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                file_manager_available.append(new_entry);
                            }
                        }
                    }

                    if ("Screensaver" in categories)
                    {
                        if (name in screensaver_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                screensaver_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                screensaver_available.append(new_entry);
                            }
                        }
                    }

                    if ("Composite" in categories)
                    {
                        if (name in composite_manager_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                composite_manager_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                composite_manager_available.append(new_entry);
                            }
                        }
                    }

                    if ("Desktop" in categories)
                    {
                        if (name in desktop_manager_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                desktop_manager_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                desktop_manager_available.append(new_entry);
                            }
                        }
                    }

                    if ("Power" in categories)
                    {
                        if (name in power_manager_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                power_manager_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                power_manager_available.append(new_entry);
                            }
                        }
                    }

                    if ("Polkit" in categories)
                    {
                        if (name in polkit_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                polkit_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                polkit_available.append(new_entry);
                            }
                        }
                    }
                    if ("InstantMessaging" in categories)
                    {
                        if (name in im_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                im_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                im_available.append(new_entry);
                            }
                        }
                    }

                    if ("Widget" in categories)
                    {
                        if (name in widget_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                widget_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                widget_available.append(new_entry);
                            }
                        }
                    }

                    if ("Terminal" in categories)
                    {
                        if (name in terminal_manager_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                terminal_manager_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                terminal_manager_available.append(new_entry);
                            }
                        }
                    }
                    if ("AudioVideo" in categories)
                    {
                        if (name in audio_video_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                audio_installed.append(new_entry);
                                video_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                audio_installed.append(new_entry);
                                video_available.append(new_entry);
                            }
                        }
                    }
                    else if ("Audio" in categories)
                        {
                            if (name in audio_blacklist)
                            {
                                /* Blacklisted, pass */
                            }
                            else
                            {
                                string new_entry = create_entry(kf, desktop_path);
                                if (mode == "installed")
                                {
                                    audio_installed.append(new_entry);
                                }
                                else if (mode == "available")
                                {
                                    audio_available.append(new_entry);
                                }
                            }
                        }
                    else if ("Video" in categories)
                        {
                            if (name in video_blacklist)
                            {
                                /* Blacklisted, pass */
                            }
                            else
                            {
                                string new_entry = create_entry(kf, desktop_path);
                                if (mode == "installed")
                                {
                                    video_installed.append(new_entry);
                                }
                                else if (mode == "available")
                                {
                                    video_available.append(new_entry);
                                }
                            }
                        }

                    if ("Viewer" in categories)
                    {
                        if (name in viewer_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                image_display_installed.append(new_entry);
                                pdf_reader_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                image_display_available.append(new_entry);
                                pdf_reader_available.append(new_entry);
                            }
                        }
                    }

                    if ("TextEditor" in categories)
                    {
                        if (name in text_editor_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                text_editor_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                text_editor_available.append(new_entry);
                            }
                        }
                    }

                    if ("Archiving" in categories)
                    {
                        if (name in archive_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                archive_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                archive_available.append(new_entry);
                            }
                        }
                    }

                    if ("Spreadsheet" in categories)
                    {
                        if (name in spreadsheet_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                spreadsheet_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                spreadsheet_available.append(new_entry);
                            }
                        }
                    }

                    if ("P2P" in categories)
                    {
                        if (name in bittorent_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                bittorent_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                bittorent_available.append(new_entry);
                            }
                        }
                    }

                    if ("WordProcessor" in categories)
                    {
                        if (name in document_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                document_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                document_available.append(new_entry);
                            }
                        }
                    }

                    if ("DiscBurning" in categories)
                    {
                        if (name in burn_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                burn_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                burn_available.append(new_entry);
                            }
                        }
                    }

                    if ("Monitor" in categories)
                    {
                        if (name in tasks_blacklist)
                        {
                            /* Blacklisted, pass */
                        }
                        else
                        {
                            string new_entry = create_entry(kf, desktop_path);
                            if (mode == "installed")
                            {
                                tasks_installed.append(new_entry);
                            }
                            else if (mode == "available")
                            {
                                tasks_available.append(new_entry);
                            }
                        }
                    }

                }
            }
            catch (KeyFileError err)
            {
                /* No entry, just pass */;
            }
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
            keyfile_set_list_string(kf, "Mime", "webbrowser/installed", webbrowser_installed);
            keyfile_set_list_string(kf, "Mime", "email/installed", email_installed);
            keyfile_set_list_string(kf, "Mime", "file_manager/installed", file_manager_installed);
            keyfile_set_list_string(kf, "Mime", "screensaver/installed", screensaver_installed);
            keyfile_set_list_string(kf, "Mime", "composite_manager/installed", composite_manager_installed);
            keyfile_set_list_string(kf, "Mime", "desktop_manager/installed", desktop_manager_installed);
            keyfile_set_list_string(kf, "Mime", "power_manager/installed", power_manager_installed);
            keyfile_set_list_string(kf, "Mime", "polkit/installed", polkit_installed);
            keyfile_set_list_string(kf, "Mime", "im/installed", im_installed);
            keyfile_set_list_string(kf, "Mime", "widget/installed", widget_installed);
            keyfile_set_list_string(kf, "Mime", "terminal_manager/installed", terminal_manager_installed);
            keyfile_set_list_string(kf, "Mime", "audio_player/installed", audio_installed);
            keyfile_set_list_string(kf, "Mime", "video_player/installed", video_installed);
            keyfile_set_list_string(kf, "Mime", "pdf_reader/installed", pdf_reader_installed);
            keyfile_set_list_string(kf, "Mime", "image_display/installed", image_display_installed);
            keyfile_set_list_string(kf, "Mime", "text_editor/installed", text_editor_installed);
            keyfile_set_list_string(kf, "Mime", "archive/installed", archive_installed);
            keyfile_set_list_string(kf, "Mime", "spreadsheet/installed", spreadsheet_installed);
            keyfile_set_list_string(kf, "Mime", "bittorent/installed", bittorent_installed);
            keyfile_set_list_string(kf, "Mime", "document/installed", document_installed);
            keyfile_set_list_string(kf, "Mime", "burn/installed", burn_installed);
            keyfile_set_list_string(kf, "Mime", "tasks/installed", tasks_installed);

            save_keyfile();
        }

        public void save_values_available ()
        {
            keyfile_set_list_string(kf, "Mime", "webbrowser/available", webbrowser_available);
            keyfile_set_list_string(kf, "Mime", "email/available", email_available);
            keyfile_set_list_string(kf, "Mime", "file_manager/available", file_manager_available);
            keyfile_set_list_string(kf, "Mime", "screensaver/available", screensaver_available);
            keyfile_set_list_string(kf, "Mime", "composite_manager/available", composite_manager_available);
            keyfile_set_list_string(kf, "Mime", "desktop_manager/available", desktop_manager_available);
            keyfile_set_list_string(kf, "Mime", "power_manager/available", power_manager_available);
            keyfile_set_list_string(kf, "Mime", "polkit/available", polkit_available);
            keyfile_set_list_string(kf, "Mime", "im/available", im_available);
            keyfile_set_list_string(kf, "Mime", "widget/available", widget_available);
            keyfile_set_list_string(kf, "Mime", "terminal_manager/available", terminal_manager_available);
            keyfile_set_list_string(kf, "Mime", "audio_player/available", audio_available);
            keyfile_set_list_string(kf, "Mime", "video_player/available", video_available);
            keyfile_set_list_string(kf, "Mime", "pdf_reader/available", pdf_reader_available);
            keyfile_set_list_string(kf, "Mime", "image_display/available", image_display_available);
            keyfile_set_list_string(kf, "Mime", "text_editor/available", text_editor_available);
            keyfile_set_list_string(kf, "Mime", "archive/available", archive_available);
            keyfile_set_list_string(kf, "Mime", "spreadsheet/available", spreadsheet_available);
            keyfile_set_list_string(kf, "Mime", "bittorent/available", bittorent_available);
            keyfile_set_list_string(kf, "Mime", "document/available", document_available);
            keyfile_set_list_string(kf, "Mime", "burn/available", burn_available);
            keyfile_set_list_string(kf, "Mime", "tasks/available", tasks_available);

            save_keyfile();
        }

        public void save_keyfile ()
        {
            var str = kf.to_data (null);
            try
            {
                FileUtils.set_contents (config_path, str, str.length);
            }
            catch (FileError err)
            {
                warning (err.message);
            }
        }

        public void keyfile_set_list_string (KeyFile kf, string categorie, string key1, List<string> list)
        {
            string[] tmp_array = {};
            foreach(string entry in list)
            {
                if (entry != null)
                {
                    tmp_array += entry;
                }
            }

            kf.set_string_list(categorie, key1, tmp_array);
        }
    }
}
