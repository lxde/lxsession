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
using Gtk;

namespace LDefaultApps
{
    public string read_autostart_conf ()
    {
        string config_path;
        config_path = get_config_home_path("autostart");
        var config_file = File.new_for_path (config_path);
        if (!config_file.query_exists ())
        {
            string config_system_path;
            config_system_path = get_config_path("autostart");

            if (config_system_path == null)
            {
                /* No system file and no home file, create a blank file in home */
                try
                {
                    message("Create blank file");
                    File blank_file = File.new_for_path (config_path);
		            blank_file.create (FileCreateFlags.PRIVATE);
                }
                catch (GLib.Error e)
                {
                    message (e.message);
                }
            }
            else
            {
                File file = File.new_for_path (config_system_path);
                var config_parent = config_file.get_parent();

                if (!config_parent.query_exists ())
                {
                    try
                    {
                        config_parent.make_directory_with_parents ();
                    }
                    catch (GLib.Error e)
                    {
                        message (e.message);
                    }
                }

               try
                {
                    file.copy (config_file, FileCopyFlags.NONE);
                }
                catch (GLib.Error e)
                {
                    message (e.message);
                }
            }
        }
        message("Conf file for autostart: %s", config_path);
        return config_path;
    }

    public void manual_autostart_init (Builder builder)
    {
        if (read_autostart_conf() == null)
        {
            message("Can't find an autostart file, abort");
        }
        else
        {
            FileStream stream = FileStream.open (read_autostart_conf(), "r");
	        assert (stream != null);

            message ("Autostart conf file : %s", read_autostart_conf());

            var auto_align = builder.get_object("autostart_alignment") as Gtk.Alignment;
            var auto_vbox = builder.get_object("manual_autostart_vbox") as Gtk.VBox;

            foreach (var widget in auto_vbox.get_children())
            {
                auto_vbox.remove(widget);
            }

	        string? line = null;
	        while ((line = stream.read_line ()) != null)
            {
                message("Autostart line : %s", line);
                var hbox = new HBox(false, 0);
                var check = new Gtk.CheckButton.with_label (line);
                if (line[0:1] == "#")
                {
                    check.set_active(false);
                }
                else
                {
                    check.set_active(true);
                }

                check.toggled.connect (() => {
                    message("Label to update : %s", check.get_label());
                    if (check.get_active())
                    {
                        if (check.get_label()[0:1] == "#")
                        {
                                update_autostart_conf(check.get_label(), "activate", builder);
                                message("Activate : %s", check.get_label());
                        }
                    }
                    else
                    {
                        if (check.get_label()[0:1] != "#")
                        {
                                update_autostart_conf(check.get_label(), "desactivate", builder);
                                message("Deactivate : %s", check.get_label());
                        }
                    }
                });

		        hbox.pack_start(check, false, false, 0);

                var button = new Button.from_stock("gtk-remove");
                button.clicked.connect (() => {
                    update_autostart_conf(check.get_label(), "remove", builder);
                    message ("try to remove : %s", check.get_label());
                });

		        hbox.pack_start(button, false, false, 0);

                auto_vbox.pack_start(hbox, false, false, 0);
	        }

            var add_hbox = new HBox(false, 0);
            var add_button = new Button.from_stock("gtk-add");
            var add_entry = new Entry();
            add_hbox.pack_start(add_button, false, false, 0);
            add_hbox.pack_start(add_entry, false, false, 0);
            auto_vbox.pack_start(add_hbox, false, false, 0);
            auto_align.add(auto_vbox);
            add_button.clicked.connect (() => {
                update_autostart_conf(add_entry.get_text(), "add", builder);
                add_entry.set_text("");
            });

            auto_vbox.show_all();
        }
    }

    public void update_autostart_conf (string line, string action, Builder builder)
    {
        var new_line = new StringBuilder ();
        switch (action)
        {
            case ("activate"):
                new_line.append(line);
                new_line.erase(0,1);
                new_line.append("\n");
                break;
            case ("desactivate"):
                new_line.append("#");
                new_line.append(line);
                new_line.append("\n");
                break;
            case ("add"):
                new_line.append(line);
                new_line.append("\n");
                break;
            case ("remove"):
                break;
        }
        try
        {
            string tmp_path = Path.build_filename(Environment.get_user_cache_dir(), "lxsession-default-apps", "autostart.tmp");
            var tmp_file = File.new_for_path (tmp_path);
            var dest_file = File.new_for_path (read_autostart_conf());

            FileStream stream = FileStream.open (read_autostart_conf(), "r");
            var tmp_stream = new DataOutputStream (tmp_file.create (FileCreateFlags.REPLACE_DESTINATION));

	        assert (stream != null);
	        string? read = null;
	        while ((read = stream.read_line ()) != null)
            {
                message ("read : %s", read);
                message ("line : %s", line); 
                if (read == line)
                {
                    tmp_stream.put_string(new_line.str);
                }
                else
                {
                    tmp_stream.put_string(read);
                    tmp_stream.put_string("\n");
                }
            }

            if (action == "add")
            {
                tmp_stream.put_string(new_line.str);
            }

            tmp_file.copy(dest_file, FileCopyFlags.OVERWRITE);
            tmp_file.delete();
            
            manual_autostart_init(builder);
        }
        catch (GLib.Error e)
        {
            message (e.message);
        }
        
    }

    public void autostart_core_applications (Builder builder, DbusBackend dbus_backend)
    {
        /* TODO Finish this
        var vbox = builder.get_object("autostart_core_applications") as Gtk.VBox;
        var item_box = new Gtk.VBox(false, 0);
        vbox.add(item_box);

        First, applications that are always autostarted (don't accept to disable)
        string[] list_not_disable = {"windows_manager", "panel"};

        for (int a = 0 ; a < list_not_disable.length ; a++)
        {
            string default_text = dbus_backend.Get(list_not_disable[a],"command");
            if ( default_text != "")
            {
                var item_label = new Label(default_text);
                item_box.add(item_label);
            }

        }

        vbox.show_all();
        */

    }

    /* TODO make the 2 following function common, or Dbus, or env, or anything to replace this c&p */
    public string get_config_home_path (string conf_file)
    {

        string user_config_dir = Path.build_filename(
                                 Environment.get_user_config_dir (),
                                 "lxsession",
                                 Environment.get_variable("DESKTOP_SESSION"),
                                 conf_file);

        return user_config_dir;

    }


    public string get_config_path (string conf_file) {

        string final_config_file;

        string user_config_dir = get_config_home_path(conf_file);

        if (FileUtils.test (user_config_dir, FileTest.EXISTS))
        {
            message ("User config used : %s", user_config_dir);
            final_config_file = user_config_dir;
        }
        else
        {
            string[] system_config_dirs = Environment.get_system_config_dirs ();
            string config_system_location = null;
            string path_system_config_file = null;

            foreach (string config in (system_config_dirs)) {
                config_system_location = Path.build_filename (config, "lxsession", Environment.get_variable("DESKTOP_SESSION"));
                message ("Config system location : %s", config_system_location);
                if (FileUtils.test (config_system_location, FileTest.EXISTS)) {
                    path_system_config_file = Path.build_filename (config_system_location, conf_file);
                    break;
                }
            }
          message ("System system path location : %s", path_system_config_file);
          final_config_file =  path_system_config_file;

         }
         message ("Final file used : %s", final_config_file);
         return final_config_file;

    }

}
