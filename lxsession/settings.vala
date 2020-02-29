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

/* TODO Split correctly the settings for enable differents backends (.ini, gsettings ...) */ 

namespace Lxsession
{
    public class LxsessionConfig: GLib.Object
    {

        /* Session identification */
        public string session_name { get; set; default = "LXDE";}
        public string desktop_env_name { get; set; default = "LXDE";}

        /* Settings db */
        public HashTable<string, string> config_item_db;
        public HashTable<string, string> session_support_item_db;
        public HashTable<string, string> xsettings_support_item_db;
        public HashTable<string, string> state_support_item_db;
        public HashTable<string, string> dbus_support_item_db;
        public HashTable<string, string> keymap_support_item_db;
        public HashTable<string, string> environment_support_item_db;

        public LxsessionConfig ()
        {
            config_item_db = init_item_db();
            session_support_item_db = init_item_db();
            xsettings_support_item_db = init_item_db();
            state_support_item_db = init_item_db();
            dbus_support_item_db = init_item_db();
            keymap_support_item_db = init_item_db();
            environment_support_item_db = init_item_db();
        }

        private HashTable<string, string> init_item_db ()
        {
            var return_map = new HashTable<string, string> (str_hash, str_equal);
            return return_map;
        }

        public void create_config_item (string categorie, string key1, string? key2, string type, string? variable)
        {
            /* only support string for now */
            string item_key = categorie + ";" + key1 + ";" + key2 + ";";

            config_item_db[item_key] = variable;

            update_support_keys (categorie, key1, key2);
        }

        public void delete_config_item (string categorie, string key1, string? key2, string type)
        {
            /* only support string for now */
            string item_key = categorie + ";" + key1 + ";" + key2 + ";";

            if (config_item_db.contains(item_key) == true)
            {
                config_item_db.remove(item_key);
                update_support_keys (categorie, key1, key2);

            }
        }

        public void get_item(string categorie, string key1, string? key2, out string variable, out string type)
        {
            /* only support string for now */
            string item_key = categorie + ";" + key1 + ";" + key2 + ";";

            // DEBUG message ("get_item item_key: %s", item_key);

            variable = config_item_db[item_key];
            type = "string";
        }

        public string get_item_string (string categorie, string key1, string? key2)
        {
            string type_output;
            string variable_output;
            get_item(categorie, key1, key2, out variable_output, out type_output);

            return variable_output;
        }

        public void set_config_item_value (string categorie, string key1, string? key2, string type, string dbus_arg)
        {
            /*
                Update config_item_db, or create the config_item if it's not exist.
            */
            string item_key = categorie + ";" + key1 + ";" + key2 +";";

            // DEBUG message ("key of read_value: %s", item_key);

            if (config_item_db.contains(item_key) == true)
            {
                // message ("Enter if of read_value for %s, %s, %s, %s, %s: ", categorie, key1, key2, type, dbus_arg);
                if (config_item_db[item_key] != dbus_arg)
                {
                    config_item_db[item_key] = dbus_arg;
                    on_update_generic(dbus_arg, categorie, key1, key2);
                }
            }
            else
            {
                create_config_item(categorie, key1, key2, type, dbus_arg);
            }
         }

        public void set_config_item_value_on_starting (string categorie, string key1, string? key2, string type, string dbus_arg)
        {
            /*
                Update config_item_db, or create the config_item if it's not exist.
            */
            string item_key = categorie + ";" + key1 + ";" + key2 +";";

            // DEBUG message ("key of read_value: %s", item_key);

            if (config_item_db.contains(item_key) == true)
            {
                // message ("Enter if of read_value for %s, %s, %s, %s, %s: ", categorie, key1, key2, type, dbus_arg);
                if (config_item_db[item_key] != dbus_arg)
                {
                    config_item_db[item_key] = dbus_arg;
                }
            }
            else
            {
                create_config_item(categorie, key1, key2, type, dbus_arg);
            }
         }

        public HashTable<string, string> get_support_db(string categorie)
        {
            var support_db = new HashTable<string, string> (str_hash, str_equal);
            /* Init for session, so it will not be null */
            support_db = session_support_item_db;

            switch (categorie)
            {
                case "Session":
                    support_db = session_support_item_db;
                    break;
                case "Xsettings":
                    support_db = xsettings_support_item_db;
                    break;
                case "GTK":
                    support_db = xsettings_support_item_db;
                    break;
                case "Mouse":
                    support_db = xsettings_support_item_db;
                    break;
                case "Keyboard":
                    support_db = xsettings_support_item_db;
                    break;
                case "State":
                    support_db = state_support_item_db;
                    break;
                case "Dbus":
                    support_db = dbus_support_item_db;
                    break;
                case "Keymap":
                    support_db = keymap_support_item_db;
                    break;
                case "Environment":
                    support_db = environment_support_item_db;
                    break;
            }

            return support_db;
        }

        public void update_support_keys (string categorie, string key1, string? key2)
        {
            var support_db = new HashTable<string, string> (str_hash, str_equal);
            support_db = get_support_db(categorie);

            if (support_db.contains(key1))
            {
                string[] list = support_db[key1].split_set(";",0);
                if (key2 == null)
                {
                    /* Pass, the key2 is empty, so no detailled support available*/
                }
                else
                {
                    if (key2 in list)
                    {
                        /* Pass, already in support */
                    }
                    else
                    {
                        support_db[key1] = support_db[key1] + key2 + ";";
                    }
                }
            }
            else
            {
                support_db[key1] = key2 + ";";
            }
        }

        public string get_support (string categorie)
        {
            string items = null;
            var support_db = new HashTable<string, string> (str_hash, str_equal);
            support_db = get_support_db(categorie);

            foreach (string key in support_db.get_keys())
            {
                if (items == null)
                {
                    items = key + ";";
                }
                else
                {
                    items = items + key + ";" ;
                }
            }

            return items;
        }

        public string get_support_key (string categorie, string key1)
        {
            string return_value = null;
            var support_db = new HashTable<string, string> (str_hash, str_equal);
            support_db = get_support_db(categorie);

            message("Return support key: %s", support_db[key1]);
            return_value =  support_db[key1];

            return return_value;
        }

        public void init_signal ()
        {
            /* Connect to signals changes */
            global_sig.generic_set_signal.connect(set_config_item_value);
        }

        public void guess_default()
        {
            /* Migrate old windows-manager settings to the new ones */
            if (get_item_string("Session", "window_manager", null) == "openbox-lxde")
            {
                set_generic_default("Session", "windows_manager", "command", "string", "openbox");
                set_generic_default("Session", "windows_manager", "session", "string", "LXDE");
            }

            /* Keep old behavior for autostarted application if this option is not specify */
            set_generic_default("Session", "disable_autostart", null, "string", "no");

            set_generic_default("Session", "polkit", "command", "string", "lxpolkit");
            set_generic_default("Session", "clipboard", "command", "string", "lxclipboard");
            set_generic_default("Session", "xsettings_manager", "command", "string", "build-in");
            set_generic_default("Session", "proxy_manager", "command", "string", "build-in");
            set_generic_default("Session", "keyring", "command", "string", "ssh-agent");

            /* Set Xsettings default */

            set_generic_default("GTK", "iXft", "Antialias", "string", "1");
            set_generic_default("GTK", "iXft", "Hinting", "string", "1");
            set_generic_default("GTK", "sXft", "HintStyle", "string", "hintslight");
            set_generic_default("GTK", "sXft", "RGBA", "string", "rgb");

            set_generic_default("GTK", "sNet", "ThemeName", "string", "Clearlooks");
            set_generic_default("GTK", "sNet", "IconThemeName", "string", "nuoveXT2");
            set_generic_default("GTK", "iNet", "EnableEventSounds", "string", "1");
            set_generic_default("GTK", "iNet", "EnableInputFeedbackSounds", "string", "1");
            set_generic_default("GTK", "sGtk", "ColorScheme", "string", "");
            set_generic_default("GTK", "sGtk", "FontName", "string", "Sans 10");
            set_generic_default("GTK", "iGtk", "ToolbarStyle", "string", "3");
            set_generic_default("GTK", "iGtk", "ToolbarIconSize", "string", "3");
            set_generic_default("GTK", "iGtk", "ButtonImages", "string", "1");
            set_generic_default("GTK", "iGtk", "MenuImages", "string", "1");
            set_generic_default("GTK", "iGtk", "CursorThemeSize", "string", "18");
            set_generic_default("GTK", "sGtk", "CursorThemeName", "string", "DMZ-White");
/*
            TODO    Add also the ones from the spec : http://www.freedesktop.org/wiki/Specifications/XSettingsRegistry/
                    And the commented one of the desktop.conf.example

*/
            set_generic_default("Mouse", "AccFactor", null, "string", "20");
            set_generic_default("Mouse", "AccThreshold", null, "string", "10");
            set_generic_default("Mouse", "LeftHanded", null, "string", "0");

            set_generic_default("Keyboard", "Delay", null, "string", "500");
            set_generic_default("Keyboard", "Interval", null, "string", "30");
            set_generic_default("Keyboard", "Beep", null, "string", "1");

            /* Misc */
            set_generic_default("State", "guess_default", null, "string", "true");
            set_generic_default("Dbus", "lxde", null, "string", "true");
            set_generic_default("Environment", "menu_prefix", null, "string", "lxde-");

            /*  Distributions, if you want to ensure good transition from previous version of lxsession
                you need to patch here to set the default for various new commands
                See Lubuntu example below
            */

            if (this.session_name == "Lubuntu")
            {
                set_generic_default("Session", "quit_manager", "command", "string", "lxsession-logout");
                set_generic_default("Session", "quit_manager", "image", "string", "/usr/share/lubuntu/images/logout-banner.png");
                set_generic_default("Session", "quit_manager", "layout", "string", "top");

                /* Migrate old windows-manager settings to the new ones */
                if (get_item_string("Session", "window_manager", null) == "openbox-lubuntu")
                {
                    set_generic_default("Session", "windows_manager", "command", "string", "openbox");
                    set_generic_default("Session", "windows_manager", "session", "string", "Lubuntu");
                }

                set_generic_default("Session", "workspace_manager", "command", "string", "obconf");
                set_generic_default("Session", "audio_manager", "command", "string", "alsamixer");
                set_generic_default("Session", "screenshot_manager", "command", "string", "scrot");
                set_generic_default("Session", "upgrade_manager", "command", "string", "upgrade-manager");

                set_generic_default("Session", "webbrowser", "command", "string", "firefox");
                set_generic_default("Session", "email", "command", "string", "sylpheed");
                set_generic_default("Session", "pdf_reader", "command", "string", "evince");
                set_generic_default("Session", "video_player", "command", "string", "gnome-mplayer");
                set_generic_default("Session", "audio_player", "command", "string", "audacious");
                set_generic_default("Session", "image_display", "command", "string", "gpicview");
                set_generic_default("Session", "text_editor", "command", "string", "leafpad");
                set_generic_default("Session", "archive", "command", "string", "file-roller");
                set_generic_default("Session", "calculator", "command", "string", "galculator");
                set_generic_default("Session", "spreadsheet", "command", "string", "gnumeric");
                set_generic_default("Session", "bittorent", "command", "string", "transmission-gtk");
                set_generic_default("Session", "document", "command", "string", "abiword");
                set_generic_default("Session", "webcam", "command", "string", "gucview");
                set_generic_default("Session", "burn", "command", "string", "xfburn");
                set_generic_default("Session", "notes", "command", "string", "xpad");
                set_generic_default("Session", "disk_utility", "command", "string", "gnome-disks");
                set_generic_default("Session", "tasks", "command", "string", "lxtask");

            }
            if (this.desktop_env_name == "LXDE")
            {
                /* We are under a LXDE generic desktop, guess some LXDE default */
                set_generic_default("Session", "quit_manager", "command", "string", "lxsession-logout");
                set_generic_default("Session", "quit_manager", "image", "string", "/usr/share/lxde/images/logout-banner.png");
                set_generic_default("Session", "quit_manager", "layout", "string", "top");

                set_generic_default("Session", "lock_manager", "command", "string", "lxlock");
                set_generic_default("Session", "terminal_manager", "command", "string", "lxterminal");
                set_generic_default("Session", "launcher_manager", "command", "string", "lxpanelctl");
            }
        }

        public void set_generic_default(string categorie, string key1, string? key2, string type, string default_value)
        {
            switch (type)
            {
                case "string":
                    if (get_item_string(categorie, key1, key2) == null)
                    {
                        message ("Settings default for %s, %s, %s : %s", categorie, key1, key2, default_value);
                        set_config_item_value(categorie, key1, key2, type, default_value);
                    }
                    break;
            }
        }

        public void on_update_generic (string dbus_arg, string categorie, string key1, string? key2)
        {
            string item_key = categorie + ";" + key1 + ";" + key2 +";";

            string type = "string";

            // message ("key of set_value: %s", item_key);

            if (config_item_db.contains(item_key) == true)
            {
                switch (type)
                {
                    case "string":
                        on_update_string_set (dbus_arg, categorie, key1, key2);
                        break;
                }
            }
        }

        public virtual void on_update_string_set (string dbus_arg, string kf_categorie, string kf_key1, string? kf_key2)
        {

        }

        public virtual void on_update_string_list_set (string[] dbus_arg, string kf_categorie, string kf_key1, string? kf_key2)
        {

        }

        public virtual void on_update_int_set (int dbus_arg, string kf_categorie, string kf_key1, string? kf_key2)
        {

        }
    }

public class LxsessionConfigKeyFile: LxsessionConfig
{
    /* Settings locations */
    public KeyFile kf = new KeyFile();
    public string desktop_config_path { get; set; default = null;}
    public string desktop_config_home_path { get; set; default = null;}
    public GLib.File desktop_file ;
    public GLib.File home_desktop_file ;
    public GLib.FileMonitor monitor_desktop_file ;
    public GLib.FileMonitor monitor_home_desktop_file;
    public GLib.Cancellable monitor_cancel;

    public LxsessionConfigKeyFile(string session_arg, string desktop_env_name_arg)
    {
        global_sig.reload_settings_daemon.connect(on_reload_settings_daemon);

        init_desktop_files();
        
        this.session_name = session_arg;
        this.desktop_env_name = desktop_env_name_arg;

        read_keyfile();

        init_signal ();

        /* Monitor desktop file */
        setup_monitor_desktop_file();

        /* Guess default */
        if (get_item_string("State", "guess_default", null) != "false")
        {
            guess_default();
        }
    }

    public void init_desktop_files()
    {
        desktop_config_path = get_config_path("desktop.conf");
        desktop_config_home_path = get_config_home_path("desktop.conf");
    }

    public void setup_monitor_desktop_file()
    {
        try {
            desktop_file = File.new_for_path(desktop_config_path);
            monitor_desktop_file = desktop_file.monitor_file(GLib.FileMonitorFlags.NONE, monitor_cancel);
            monitor_desktop_file.changed.connect(on_desktop_file_change);
            message ("Monitoring: %s", desktop_config_path);

            if ( desktop_file.get_path() == desktop_config_home_path)
            {
                 message ("Desktop file is already in config home, do nothing");
            }
            else
            {
                message ("Desktop file is not in config home, monitoring creation of it");
                setup_creation_desktop_file();
            }

        } catch (GLib.Error err) {
            message (err.message);
        }
    }

    public void setup_creation_desktop_file()
    {
        try {
            home_desktop_file = File.new_for_path(desktop_config_home_path);
            monitor_home_desktop_file = home_desktop_file.monitor_file(GLib.FileMonitorFlags.NONE);
            monitor_home_desktop_file.changed.connect(on_desktop_file_creation);
            message ("Monitoring home path: %s", home_desktop_file.get_path());
        } catch (GLib.Error err) {
            message (err.message);
        }
    } 

    public void reload_xsettings ()
    {
        if (global_xsettings_manager == null)
        {
            var xsettings = new XSettingsOption();
            global_xsettings_manager = xsettings;
            global_xsettings_manager.activate();
            message("Create a xsettings option");
        }
        else
        {
            global_xsettings_manager.reload();
            message("Reload the xsettings option");
        }
    }

    public void on_desktop_file_change ()
    {
        message("Desktop file change, reloading XSettings daemon");
        reload_xsettings();
    }

    public void on_desktop_file_creation ()
    {
        message("Desktop file created in home directory, switch configuration to it");
        desktop_config_path = desktop_config_home_path;
        monitor_cancel.cancel();

        reload_xsettings();
        setup_monitor_desktop_file();
    }

    public string read_keyfile_string_value (KeyFile keyfile, string kf_categorie, string kf_key1, string? kf_key2, string? default_value)
    {
        string copy_value = null;
        string return_value = null;
        try
        {
            if (kf_key2 == null)
            {
                copy_value = keyfile.get_value (kf_categorie, kf_key1);
            }
            else
            {
                copy_value = keyfile.get_value (kf_categorie, kf_key1 + "/" + kf_key2);
            }
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        if (copy_value == null)
        {
            return_value = default_value;
        }
        else
        {
            if (default_value != copy_value)
            {
                return_value = copy_value;
            }
            else
            {
                return_value = default_value;
            }
        }

        return return_value;
    }

    public int read_keyfile_int_value (KeyFile keyfile, string kf_categorie, string kf_key1, string? kf_key2, int default_value)
    {
        int return_value = 0;

        try
        {
            if (kf_key2 == null)
            {
                return_value = keyfile.get_integer (kf_categorie, kf_key1);
            }
            else
            {
                return_value = keyfile.get_integer (kf_categorie, kf_key1 + "/" + kf_key2);
            }
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        if (return_value == 0)
        {
            return_value = default_value;
        }
        else
        {
            if (return_value == default_value)
            {
                return_value = default_value;
            }
        }
        return return_value;
    }

    public string[] read_keyfile_string_list_value (KeyFile keyfile, string kf_categorie, string kf_key1, string? kf_key2, string[] default_value)
    {
        string[] copy_value = null;
        string[] return_value = null;
        try
        {
            if (kf_key2 == null)
            {
                copy_value = keyfile.get_string_list (kf_categorie, kf_key1);
            }
            else
            {
                copy_value = keyfile.get_string_list (kf_categorie, kf_key1 + "/" + kf_key2);
            }
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }

        if (copy_value == null)
        {
            return_value = default_value;
        }
        else
        {
            if (default_value != copy_value)
            {
                return_value = copy_value;
            }
            else
            {
                return_value = default_value;
            }
        }

        return return_value;
    }


    public void read_key_value (KeyFile kf, string categorie, string key1, string? key2, string type)
    {
        string default_variable = null;
        string final_variable = null;
        string type_output = null;

        string item_key = categorie + ";" + key1 + ";" + key2 +";";

        switch (type)
        {
            case "string":
                final_variable = read_keyfile_string_value(kf, categorie, key1, key2, default_variable);
                break;
        }

        if (config_item_db.contains(item_key) == false)
        {
            // message ("Create new config key: %s", item_key);
            create_config_item(categorie, key1, key2, type, final_variable);
        }
        else
        {
            get_item(categorie, key1, key2, out default_variable, out type_output);
            set_config_item_value_on_starting(categorie, key1, key2, type, final_variable);
        }

    }

    public void read_keyfile()
    {
        kf = load_keyfile (desktop_config_path);

        /* Remove buggy keys */
        if (read_keyfile_string_value(kf, "GTK", "iGtk", "ColorScheme", null) != null)
        {
            delete_config_item("GTK", "iGtk", "ColorScheme", "string");
        }

        /* Windows manager */
        if (read_keyfile_string_value(kf, "Session", "windows_manager", "command", null) != null)
        {
            read_key_value(kf, "Session", "windows_manager", "command", "string");
            read_key_value(kf, "Session", "windows_manager", "session", "string");
            read_key_value(kf, "Session", "windows_manager", "extras", "string");
        }
        else
        {
            read_key_value(kf, "Session", "window_manager", null, "string");
        }

        /* Panel */
        if (read_keyfile_string_value(kf, "Session", "panel", "command", null) != null)
        {
            read_key_value(kf, "Session", "panel", "command", "string");
            read_key_value(kf, "Session", "panel", "session", "string");
        }

        /* Dock */
        if (read_keyfile_string_value(kf, "Session", "dock", "command", null) != null)
        {
            read_key_value(kf, "Session", "dock", "command", "string");
            read_key_value(kf, "Session", "dock", "session", "string");
        }

        /* File Manager */
        if (read_keyfile_string_value(kf, "Session", "file_manager", "command", null) != null)
        {
            read_key_value(kf, "Session", "file_manager", "command", "string");
            read_key_value(kf, "Session", "file_manager", "session", "string");
            read_key_value(kf, "Session", "file_manager", "extras", "string");
        }

        /* Desktop handler */
        if (read_keyfile_string_value(kf, "Session", "desktop_manager", "command", null) != null)
        {
            read_key_value(kf, "Session", "desktop_manager", "command", "string");
            read_key_value(kf, "Session", "desktop_manager", "wallpaper", "string");
        }

        /* Launcher manager */
        if (read_keyfile_string_value(kf, "Session", "launcher_manager", "command", null) != null)
        {
            read_key_value(kf, "Session", "launcher_manager", "command", "string");
            read_key_value(kf, "Session", "launcher_manager", "autostart", "string");
        }

        /* Composite manager */
        if (read_keyfile_string_value(kf, "Session", "composite_manager", "command", null) != null)
        {
            read_key_value(kf, "Session", "composite_manager", "command", "string");
            read_key_value(kf, "Session", "composite_manager", "autostart", "string");
        }

        /* IM */
        if (read_keyfile_string_value(kf, "Session", "im1", "command", null) != null)
        {
            read_key_value(kf, "Session", "im1", "command", "string");
            read_key_value(kf, "Session", "im1", "autostart", "string");
        }

        if (read_keyfile_string_value(kf, "Session", "im2", "command", null) != null)
        {
            read_key_value(kf, "Session", "im2", "command", "string");
            read_key_value(kf, "Session", "im2", "autostart", "string");
        }

        /* Widget */
        if (read_keyfile_string_value(kf, "Session", "widget1", "command", null) != null)
        {
            read_key_value(kf, "Session", "widget1", "command", "string");
            read_key_value(kf, "Session", "widget1", "autostart", "string");
        }

        /* Notification */
        if (read_keyfile_string_value(kf, "Session", "notification", "command", null) != null)
        {
            read_key_value(kf, "Session", "notification", "command", "string");
            read_key_value(kf, "Session", "notification", "autostart", "string");
        }

        /* Key bindings */
        if (read_keyfile_string_value(kf, "Session", "keybindings", "command", null) != null)
        {
            read_key_value(kf, "Session", "keybindings", "command", "string");
            read_key_value(kf, "Session", "keybindings", "autostart", "string");
        }

        /* IM manager */
        if (read_keyfile_string_value(kf, "Session", "im_manager", "command", null) != null)
        {
            read_key_value(kf, "Session", "im_manager", "command", "string");
            read_key_value(kf, "Session", "im_manager", "autostart", "string");
        }

        /* Other session applications */
        read_key_value(kf, "Session", "screensaver", "command", "string");
        read_key_value(kf, "Session", "power_manager", "command", "string");
        read_key_value(kf, "Session", "polkit", "command", "string");
        read_key_value(kf, "Session", "audio_manager", "command", "string");
        read_key_value(kf, "Session", "quit_manager", "command", "string");

        if (read_keyfile_string_value(kf, "Session", "quit_manager", "command", null) != null)
        {
            read_key_value(kf, "Session", "quit_manager", "command", "string");
            read_key_value(kf, "Session", "quit_manager", "image", "string");
            read_key_value(kf, "Session", "quit_manager", "layout", "string");
        }

        read_key_value(kf, "Session", "workspace_manager", "command", "string");
        read_key_value(kf, "Session", "terminal_manager", "command", "string");
        read_key_value(kf, "Session", "screenshot_manager", "command", "string");
        read_key_value(kf, "Session", "lock_manager", "command", "string");
        read_key_value(kf, "Session", "message_manager", "command", "string");
        read_key_value(kf, "Session", "upgrade_manager", "command", "string");
        read_key_value(kf, "Session", "updates_manager", "command", "string");
        read_key_value(kf, "Session", "updates_manager", "timeout", "string");
        read_key_value(kf, "Session", "crash_manager", "command", "string");
        read_key_value(kf, "Session", "crash_manager", "dev_mode", "string");
        read_key_value(kf, "Session", "crash_manager", "timeout", "string");
        read_key_value(kf, "Session", "clipboard", "command", "string");
        read_key_value(kf, "Session", "disable_autostart", null, "string");
        read_key_value(kf, "Session", "upstart_user_session", null, "string");
        read_key_value(kf, "Session", "xsettings_manager", "command", "string");
        read_key_value(kf, "Session", "proxy_manager", "command", "string");
        read_key_value(kf, "Session", "proxy_manager", "http", "string");
        read_key_value(kf, "Session", "a11y", "command", "string");
        read_key_value(kf, "Session", "keyring", "command", "string");
        read_key_value(kf, "Session", "xrandr", "command", "string");
        read_key_value(kf, "Session", "network_gui", "command", "string");

        /* Mime applications */
        read_key_value(kf, "Session", "webbrowser", "command", "string");
        read_key_value(kf, "Session", "email", "command", "string");
        read_key_value(kf, "Session", "pdf_reader", "command", "string");
        read_key_value(kf, "Session", "video_player", "command", "string");
        read_key_value(kf, "Session", "audio_player", "command", "string");
        read_key_value(kf, "Session", "image_display", "command", "string");
        read_key_value(kf, "Session", "text_editor", "command", "string");
        read_key_value(kf, "Session", "archive", "command", "string");
        read_key_value(kf, "Session", "charmap", "command", "string");
        read_key_value(kf, "Session", "calculator", "command", "string");
        read_key_value(kf, "Session", "spreadsheet", "command", "string");
        read_key_value(kf, "Session", "bittorent", "command", "string");
        read_key_value(kf, "Session", "document", "command", "string");
        read_key_value(kf, "Session", "webcam", "command", "string");
        read_key_value(kf, "Session", "burn", "command", "string");
        read_key_value(kf, "Session", "notes", "command", "string");
        read_key_value(kf, "Session", "disk_utility", "command", "string");
        read_key_value(kf, "Session", "tasks", "command", "string");

        /* Keymap */
        if (read_keyfile_string_value(kf, "Keymap", "mode", null, null) != null)
        {
            read_key_value(kf, "Keymap", "mode", null, "string");
            read_key_value(kf, "Keymap", "model", null, "string");
            read_key_value(kf, "Keymap", "layout", null, "string");
            read_key_value(kf, "Keymap", "variant", null, "string");
            read_key_value(kf, "Keymap", "options", null, "string");
        }

        /* Other */
        read_key_value(kf, "State", "laptop_mode", null, "string");
        read_key_value(kf, "State", "guess_default", null, "string");
        read_key_value(kf, "Dbus", "lxde", null, "string");
        read_key_value(kf, "Dbus", "gnome", null, "string");
        read_key_value(kf, "Environment", "type", null, "string");
        read_key_value(kf, "Environment", "menu_prefix", null, "string");
        read_key_value(kf, "Environment", "ubuntu_menuproxy", null, "string");
        read_key_value(kf, "Environment", "toolkit_integration", null, "string");
        read_key_value(kf, "Environment", "gtk", "overlay_scrollbar_disable", "string");
        read_key_value(kf, "Environment", "qt", "force_theme", "string");
        read_key_value(kf, "Environment", "qt", "platform", "string");

        read_key_value(kf, "GTK", "sNet", "ThemeName", "string");
        read_key_value(kf, "GTK", "sNet", "IconThemeName", "string");
        read_key_value(kf, "GTK", "sGtk", "FontName", "string");
        read_key_value(kf, "GTK", "iGtk", "ToolbarStyle", "string");
        read_key_value(kf, "GTK", "iGtk", "ButtonImages", "string");
        read_key_value(kf, "GTK", "iGtk", "MenuImages", "string");
        read_key_value(kf, "GTK", "iGtk", "CursorThemeSize", "string");
        read_key_value(kf, "GTK", "iXft", "Antialias", "string");
        read_key_value(kf, "GTK", "iXft", "Hinting", "string");
        read_key_value(kf, "GTK", "sXft", "HintStyle", "string");
        read_key_value(kf, "GTK", "sXft", "RGBA", "string");
        read_key_value(kf, "GTK", "sGtk", "ColorScheme", "string");
        read_key_value(kf, "GTK", "sGtk", "CursorThemeName", "string");
        read_key_value(kf, "GTK", "iGtk", "ToolbarIconSize", "string");
        read_key_value(kf, "GTK", "iNet", "EnableEventSounds", "string");
        read_key_value(kf, "GTK", "iNet", "EnableInputFeedbackSounds", "string");
        read_key_value(kf, "Mouse", "AccFactor", null, "string");
        read_key_value(kf, "Mouse", "AccThreshold", null, "string");
        read_key_value(kf, "Mouse", "LeftHanded", null, "string");
        read_key_value(kf, "Keyboard", "Delay", null, "string");
        read_key_value(kf, "Keyboard", "Interval", null, "string");
        read_key_value(kf, "Keyboard", "Beep", null, "string");

        read_secondary_keyfile();

    }

    public virtual void read_secondary_keyfile()
    {

    }

    public void sync_setting_files ()
    {
        string desktop_file = desktop_config_home_path;
        if (FileUtils.test (desktop_file, FileTest.EXISTS))
        {
            string autostart_file = get_config_home_path("autostart");
            if (FileUtils.test (autostart_file, FileTest.EXISTS))
            {
                /* File in sync, nothing to do */
            }
            else
            {
                var file = File.new_for_path (get_config_path("autostart"));
                var destination = File.new_for_path (get_config_home_path("autostart"));
                try
                {
                    file.copy (destination, FileCopyFlags.NONE);
                }
                catch (GLib.Error err)
                {
		            message (err.message);
                }
            }
        }
    }

    public void save_keyfile ()
    {
        // message ("Saving desktop file");
        var str = kf.to_data (null);
        try
        {
            FileUtils.set_contents (desktop_config_path, str, str.length);
        }
        catch (FileError err)
        {
            warning (err.message);
            try
            {
                /* Try to save on user config directory */
                string user_config_dir = desktop_config_home_path;

                File file_parent;
                var file = File.new_for_path(user_config_dir);
                file_parent = file.get_parent();
                if (!file_parent.query_exists())
                {
                    try
                    {
                        file_parent.make_directory_with_parents();
                    }
                    catch (GLib.Error err)
                    {
                        warning (err.message);
                    }
                }

                FileUtils.set_contents (user_config_dir, str, str.length);
                desktop_config_path = user_config_dir;
                setup_monitor_desktop_file();
                sync_setting_files ();
            }
            catch (FileError err)
            {
                warning (err.message);
            }
        }
        save_secondary_keyfile();
    }

    public virtual void save_secondary_keyfile()
    {

    }

    public override void on_update_string_set (string dbus_arg, string kf_categorie, string kf_key1, string? kf_key2)
    {
        switch (kf_key2)
            {
                case null:
                    // message("Changing %s - %s to %s" , kf_categorie, kf_key1, dbus_arg);
                    kf.set_value (kf_categorie, kf_key1, dbus_arg);
                    break;
                case "":
                    // message("Changing %s - %s to %s" , kf_categorie, kf_key1, dbus_arg);
                    kf.set_value (kf_categorie, kf_key1, dbus_arg);
                    break;
                case " ":
                    // message("Changing %s - %s to %s" , kf_categorie, kf_key1, dbus_arg);
                    kf.set_value (kf_categorie, kf_key1, dbus_arg);
                    break;
                default:
                    // message("Changing %s - %s - %s to %s" , kf_categorie, kf_key1, kf_key2, dbus_arg);
                    kf.set_value (kf_categorie, kf_key1 + "/" + kf_key2, dbus_arg);
                    break;
            }
        save_keyfile();
    }

    public override void on_update_string_list_set (string[] dbus_arg, string kf_categorie, string kf_key1, string? kf_key2)
    {
        switch (kf_key2)
            {
                case null:
                    // message("Changing %s - %s" , kf_categorie, kf_key1);
                    kf.set_string_list (kf_categorie, kf_key1, dbus_arg);
                    break;
                case "":
                    // message("Changing %s - %s" , kf_categorie, kf_key1);
                    kf.set_string_list (kf_categorie, kf_key1, dbus_arg);
                    break;
                case " ":
                    // message("Changing %s - %s" , kf_categorie, kf_key1);
                    kf.set_string_list (kf_categorie, kf_key1, dbus_arg);
                    break;
                default:
                    // message("Changing %s - %s - %s" , kf_categorie, kf_key1, kf_key2);
                    kf.set_string_list (kf_categorie, kf_key1 + "/" + kf_key2, dbus_arg);
                    break;
            }
        save_keyfile();
    }

    public override void on_update_int_set (int dbus_arg, string kf_categorie, string kf_key1, string? kf_key2)
    {
        switch (kf_key2)
            {
                case null:
                    message("Changing %s - %s to %i" , kf_categorie, kf_key1, dbus_arg);
                    kf.set_integer (kf_categorie, kf_key1, dbus_arg);
                    break;
                case "":
                    message("Changing %s - %s to %i" , kf_categorie, kf_key1, dbus_arg);
                    kf.set_integer (kf_categorie, kf_key1, dbus_arg);
                    break;
                case " ":
                    message("Changing %s - %s to %i" , kf_categorie, kf_key1, dbus_arg);
                    kf.set_integer (kf_categorie, kf_key1, dbus_arg);
                    break;
                default:
                    message("Changing %s - %s - %s to %i" , kf_categorie, kf_key1, kf_key2, dbus_arg);
                    kf.set_integer (kf_categorie, kf_key1 + "/" + kf_key2, dbus_arg);
                    break;
            }
        save_keyfile();
    }

    public void on_reload_settings_daemon ()
    {
        message("Reloading XSettings daemon");
        reload_xsettings();
    }

}

public class RazorQtConfigKeyFile: LxsessionConfigKeyFile
{
    public KeyFile kf_session = new KeyFile();

    public string session_razor_config_path;
    public string session_razor_config_home_path;
    public GLib.File session_razor_file ;
    public GLib.File home_session_razor_file ;

    public KeyFile kf_conf = new KeyFile();

    public string conf_razor_config_path;
    public string conf_razor_config_home_path;
    public GLib.File confrazor_file ;
    public GLib.File home_conf_razor_file ;

    public RazorQtConfigKeyFile(string session_arg, string desktop_env_name_arg)
    {
        base (session_arg, desktop_env_name_arg);

            init_desktop_files();
            init_desktop_razor_files();
            
            this.session_name = session_arg;
            this.desktop_env_name = desktop_env_name_arg;

            read_keyfile();

            init_signal ();

            /* Monitor desktop file */
            setup_monitor_desktop_file();

            /* Guess default */
            if (get_item_string("State", "guess_default", null) != "false")
            {
                guess_default();
            }
    }

    public void init_desktop_razor_files()
    {
        session_razor_config_home_path = Path.build_filename(Environment.get_user_config_dir (), "razor", "session.conf");
        var home_session_razor_file = File.new_for_path(session_razor_config_home_path);

        session_razor_config_path = Path.build_filename("etc", "xdg", "razor", "session.conf");
        var session_razor_file = File.new_for_path(session_razor_config_path);

        if (home_session_razor_file.query_exists ())
        {
            session_razor_config_path = session_razor_config_home_path;
        }
        else if (session_razor_file.query_exists ())
        {
            /* Do nothing, keep session_razor_config_path value */
        }
        else
        {
            session_razor_config_path = session_razor_config_home_path;
            try
            {
                home_session_razor_file.create(FileCreateFlags.NONE);
            }
            catch (GLib.Error err)
            {
		        message (err.message);
            }
        }

        conf_razor_config_home_path = Path.build_filename(Environment.get_user_config_dir (), "razor", "razor.conf");
        var home_conf_razor_file = File.new_for_path(conf_razor_config_home_path);

        conf_razor_config_path = Path.build_filename("etc", "xdg", "razor", "razor.conf");
        var conf_razor_file = File.new_for_path(conf_razor_config_path);

        if (home_conf_razor_file.query_exists ())
        {
            conf_razor_config_path = conf_razor_config_home_path;
        }
        else if (conf_razor_file.query_exists ())
        {
            /* Do nothing, keep conf_razor_config_path value */
        }
        else
        {
            conf_razor_config_path = conf_razor_config_home_path;
            try
            {
                home_conf_razor_file.create(FileCreateFlags.NONE);
            }
            catch (GLib.Error err)
            {
		        message (err.message);
            }
        }

    }

    public void read_razor_key_value (KeyFile kf, string categorie, string key1, string? key2, string type, string categorie_razor, string key1_razor, string? key2_razor)
    {
        string default_variable = null;
        string final_variable = null;
        string type_output = null;

        string item_key = categorie + ";" + key1 + ";" + key2 +";";

        switch (type)
        {
            case "string":
                final_variable = read_razor_keyfile_bool_value(kf, categorie_razor, key1_razor, key2_razor, default_variable);
                break;
        }

        if (config_item_db.contains(item_key))
        {
            message ("Create new config key: %s", item_key);
            create_config_item(categorie, key1, key2, type, null);
        }
        else
        {
            get_item(categorie, key1, key2, out default_variable, out type_output);
            set_config_item_value(categorie, key1, key2, type, final_variable);
        }

    }

    public override void read_secondary_keyfile()
    {

        /* override razor menu prefix */
        set_generic_default("Environment", "menu_prefix", null, "string", "razor-");

        kf_session = load_keyfile (session_razor_config_path);

        /* Windows manager */
        read_razor_key_value(kf, "Session", "windows_manager", "command", "string", "General", "windowmanager", null);

        /* Panel */
        read_razor_key_value(kf, "Session", "panel", "command", "string", "modules", "razor-panel", null);
        read_razor_key_value(kf, "Session", "desktop", "command", "string", "modules", "razor-desktop", null);
        read_razor_key_value(kf, "Session", "launcher_manager", "command", "string", "modules", "razor-runner", null);

        if (get_item_string("Session", "launcher_manager", "command") == "razor-runner")
        {
            set_config_item_value("Session", "launcher_manager", "autostart", "string", "true");
        }

        read_razor_key_value(kf, "Session", "polkit", "command", "string", "modules", "razor-policykit-agent", null);

        /* TODO Convert this config on file to lxsession config
        razor-appswitcher=false
        */

        kf_conf = load_keyfile (session_razor_config_path);

        read_razor_key_value(kf_conf, "GTK", "sNet", "ThemeName", "string", "Theme", "theme", null);
        read_razor_key_value(kf_conf, "GTK", "sNet", "IconThemeName", "string", "Theme", "icon_theme", null);

    }

    public string read_razor_keyfile_bool_value (KeyFile keyfile, string kf_categorie, string kf_key1, string? kf_key2, string? default_value)
    {
        string copy_value = null;
        string return_value = null;
        try
        {
            if (kf_key2 == null)
            {
                copy_value = keyfile.get_value (kf_categorie, kf_key1);
            }
            else
            {
                copy_value = keyfile.get_value (kf_categorie, kf_key1 + "/" + kf_key2);
            }
	    }
        catch (KeyFileError err)
        {
		    message (err.message);
        }


        if (copy_value == null)
        {
            return_value = default_value;
        }
        else
        {
            if (copy_value == "true")
            {
                return_value = kf_key1;
            }
            else
            {
                return_value = default_value;
            }
        }

        return return_value;
    }


    public override void save_secondary_keyfile()
    {
        session_razor_config_path = session_razor_config_home_path;
        conf_razor_config_path = conf_razor_config_home_path;

        kf_session.set_value ("General", "windowmanager", get_item_string("Session", "windows_manager", "command"));

        if (get_item_string("Session", "panel", "command") == "razor-panel")
        {
            kf_session.set_value ("modules", "razor-panel", "true");
        }
        else
        {
            kf_session.set_value ("modules", "razor-panel", "false");
        }

        if (get_item_string("Session", "desktop", "command") == "razor-desktop")
        {
            kf_session.set_value ("modules", "razor-desktop", "true");
        }
        else
        {
            kf_session.set_value ("modules", "razor-desktop", "false");
        }

        if (get_item_string("Session", "launcher_manager", "command") == "razor-runner")
        {
            kf_session.set_value ("modules", "razor-runner", "true");
        }
        else
        {
            kf_session.set_value ("modules", "razor-runner", "false");
        }

        if (get_item_string("Session", "polkit", "command") == "razor-policykit-agent")
        {
            kf_session.set_value ("modules", "razor-policykit-agent", "true");
        }
        else
        {
            kf_session.set_value ("modules", "razor-policykit-agent", "false");
        }

        /* TODO Convert this config on file to lxsession config
        razor-appswitcher=false
        */

        message ("Saving razor session file");
        var str_session = kf_session.to_data (null);
        try
        {
            FileUtils.set_contents (session_razor_config_path, str_session, str_session.length);
        }
        catch (FileError err)
        {
            warning (err.message);
        }

        message ("Saving razor conf file");
        var str_conf = kf_conf.to_data (null);
        try
        {
            FileUtils.set_contents (conf_razor_config_path, str_conf, str_conf.length);
        }
        catch (FileError err)
        {
            warning (err.message);
        }
    }
}

}
