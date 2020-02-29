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
    void init_application(   Builder builder,
                                    KeyFile kf,
                                    DbusBackend dbus_backend,
                                    string key1,
                                    string key2,
                                    string message_help,
                                    string[] more_list,
                                    string more_help,
                                    string? generic_item)
    {
        init_entry(builder, dbus_backend, key1);
        init_reload_button(builder, dbus_backend, key1, key2);
        init_help_message(builder, key1, message_help);
        init_more_button(builder, dbus_backend, kf, key1, more_list, more_help, generic_item);
    }

    void init_application_combobox ( Gtk.Builder builder,
                                            KeyFile kf,
                                            DbusBackend dbus_backend,
                                            string key1,
                                            string key2,
                                            string message_help,
                                            string[] more_list,
                                            string more_help,
                                            string? generic_item)
    {
        init_combobox(builder, dbus_backend, kf, key1 + "_combobox", key1, dbus_backend.Get(key1, "command"), generic_item);
        init_reload_button(builder, dbus_backend, key1, key2);
        init_help_message(builder, key1, message_help);
        init_more_button(builder, dbus_backend, kf, key1, more_list, more_help, generic_item);
    }

    void init_entry(Builder builder, DbusBackend dbus_backend, string key1)
    {
        string default_text = dbus_backend.Get(key1, "command");
        string entry_name = key1 + "_entry";
        var entry = builder.get_object (entry_name) as Entry;
        entry.set_text(default_text);
        entry.changed.connect(() => {
            if (entry.get_text() != null)
            {
                dbus_backend.Set(key1, "command", entry.get_text());
            }
        });
        entry.show_all();
    }

    void init_reload_button(Builder builder, DbusBackend dbus_backend, string key1, string key2)
    {
        var button = builder.get_object(key1 + "_reload") as Gtk.Button;
        button.clicked.connect (() => {
            dbus_backend.Launch(key1, key2);
        });
    }

    void init_help_message(Builder builder, string item, string message_label)
    {
        var help_button = builder.get_object(item + "_help_button") as Gtk.Button;
        help_button.clicked.connect (() => {
            var help_window = new Window();
            help_window.window_position = Gtk.WindowPosition.CENTER;
            help_window.set_default_size (350, 70);
            help_window.set_skip_taskbar_hint(true);
            try
            {
                help_window.icon = IconTheme.get_default ().load_icon ("preferences-desktop", 48, 0);
            }
            catch (Error e)
            {
                message ("Could not load application icon: %s\n", e.message);
            }

            var help_label = new Label(message_label);
            help_window.add(help_label);
            help_window.show_all();
        });
    }

    void init_more_button(Builder builder, DbusBackend dbus_backend, KeyFile kf, string item, string[] more_list, string more_help, string generic_item)
    {
        /* Copy the array, it doesn't seem to like to be passed directly */
        string[] more_list_copy = more_list;
        var button = builder.get_object(item + "_more") as Gtk.Button;
        button.clicked.connect (() => {
            init_windows_more(builder, dbus_backend, kf, item, more_list_copy, more_help, generic_item);
        });
    }

    void init_windows_more (Builder builder, DbusBackend dbus_backend, KeyFile kf, string item, string[] more_list, string message_help, string generic_item)
    {
        var window = new Gtk.Window();
        window.window_position = Gtk.WindowPosition.CENTER;
        window.set_default_size (300, 500);
        try
        {
            window.icon = IconTheme.get_default ().load_icon ("preferences-desktop", 48, 0);
        }
        catch (Error e)
        {
            message ("Could not load application icon: %s\n", e.message);
        }


        // The ScrolledWindow:
		Gtk.ScrolledWindow more_scrolled = new Gtk.ScrolledWindow (null, null);
        more_scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
		window.add (more_scrolled);

        var more_view_port = new Gtk.Viewport(null, null);
        more_scrolled.add(more_view_port);

        var master_vbox = new Gtk.VBox(false, 0);
        more_view_port.add(master_vbox);

        var help_message = new Label(message_help);
        master_vbox.add(help_message);
        for (int a = 0 ; a < more_list.length ; a++)
        {
            switch (more_list[a])
            {
                case "combobox_manual":
                    var box = new Gtk.HBox(false, 0);
                    master_vbox.add(box);

                    var label = new Label(_("Manual setting"));
                    box.add(label);

                    string default_text = dbus_backend.Get(item, "command");
                    var manual_entry = new Gtk.Entry();
                    manual_entry.set_text(default_text);
                    manual_entry.changed.connect(() => {
                        if (manual_entry.get_text() != null)
                        {
                            dbus_backend.Set(item, "command", manual_entry.get_text());
                            /* TODO update the main combobox */
                        }
                    });
                    box.add(manual_entry);
                    break;

                case "mime_association":
                    var box = new Gtk.HBox(false, 0);
                    master_vbox.add(box);

                    var label = new Label(_("Mime Association"));
                    box.add(label);

                    var button = new Gtk.Button.with_label(_("Apply"));
  
                    button.clicked.connect(() => {
                        string[] combobox_list;
                        combobox_list = get_mime_list(kf, item, "installed");
                        string default_path = "";
                        string default_exec = "";

                        for (int b = 0 ; b < combobox_list.length ; b++)
                        {
                            string item_list = combobox_list[b];
                            ComboItemObject combo_item = new ComboItemObject (item_list);
                            if (item == combo_item.exec)
                            {
                                default_path = combo_item.desktop_path;
                                default_exec = combo_item.exec;
                            }
                        }
                        create_mime_associate_window(dbus_backend, kf, item, default_exec);
                    });
                    box.add(button);
                    break;
                case "mime_available":
                    var box = new Gtk.VBox(false, 0);
                    master_vbox.add(box);

                    var label = new Label(_("Available applications"));
                    box.add(label);

                    Gtk.ListStore list_store = new Gtk.ListStore (3, typeof(string), typeof(string), typeof(string));
                    Gtk.TreeIter iter;

                    string[] list ;
                    if (generic_item != null)
                    {
                        list = get_mime_list(kf, generic_item, "available");
                    }
                    else
                    {
                        list = get_mime_list(kf, item, "available");
                    }

                    for (int c = 0 ; c < list.length ; c++)
                    {
                            string item_list = list[c];
                            ComboItemObject combo_item = new ComboItemObject (item_list);

                            list_store.append (out iter);
                            list_store.set (iter, 0, combo_item.icon_name , 1, combo_item.name, 2, "gtk-apply");
                    }

                    var return_treeview = new Gtk.TreeView.with_model(list_store);

                    Gtk.CellRendererPixbuf renderer_image = new Gtk.CellRendererPixbuf ();
                    return_treeview.insert_column_with_attributes (-1, "Icon", renderer_image, "icon-name", 0);

                    Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
                    return_treeview.insert_column_with_attributes (-1, "Name", renderer, "text", 1);

                    Gtk.CellRendererPixbuf renderer_apply = new Gtk.CellRendererPixbuf ();
                    return_treeview.insert_column_with_attributes (-1, "", renderer_apply, "icon-name", 2);

                    /* TODO callback the install button */

                    box.add(return_treeview);

                    break;
                case "autostart":
                    var hbox = new Gtk.HBox(false, 0);
                    master_vbox.add(hbox);

                    var check_button = new Gtk.CheckButton();
                    check_button.set_label(_("Autostart the application ?"));
                    string default_text = dbus_backend.Get(item, "autostart");
                    if (default_text == "true")
                    {
                        check_button.set_active(true);
                    }
                    else
                    {
                        check_button.set_active(false);
                    }
                    check_button.clicked.connect(() => {
                        dbus_backend.Set(item, "autostart", "true");
                    });
                    hbox.add(check_button);
                    break;

                case "handle_desktop":
                    var hbox = new Gtk.HBox(false, 0);
                    master_vbox.add(hbox);

                    var check_button = new Gtk.CheckButton();
                    check_button.set_label(_("Handle the desktop with it ?"));
                    string default_text = dbus_backend.Get("desktop_manager", "command");
                    if (default_text == "filemanager")
                    {
                        check_button.set_active(true);
                    }
                    else
                    {
                        check_button.set_active(false);
                    }
                    check_button.clicked.connect(() => {
                        dbus_backend.Set("desktop_manager", "command", "filemanager");
                    });
                    hbox.add(check_button);
                    break;

                case "debian_default":
                    var box = new Gtk.HBox(false, 0);
                    master_vbox.add(box);

                    var label = new Label(_("Set debian default programs"));
                    box.add(label);

                    var button = new Gtk.Button.with_label(_("Apply"));
  
                    button.clicked.connect(() => {

                        string default_text = dbus_backend.Get(item, "command");

                        string default_command;

                        if (default_text[0:1] == "/")
                        {
                            default_command = default_text;
                        }
                        else
                        {
                            default_command = "/usr/bin/" + default_text;
                        }
                        switch (item)
                        {
                            case "webbrowser":
                                try
                                {
                                    Process.spawn_command_line_async(   "gksu \"update-alternatives --set x-www-browser "
                                                                        + default_command + "\"");
                                }
                                catch (GLib.SpawnError err)
                                {
                                    warning (err.message);
                                }
                                break;

                            case "terminal_manager":
                                try
                                {
                                    Process.spawn_command_line_async(   "gksu \"update-alternatives --set x-terminal-emulator "
                                                                        + default_command + "\"");
                                }
                                catch (GLib.SpawnError err)
                                {
                                    warning (err.message);
                                }
                                break;
                        }
                    });
                    box.add(button);
                    break;
                default:
                    if (more_list[a] != null)
                    {
                        var hbox = new Gtk.HBox(false, 0);
                        master_vbox.add(hbox);
                        var label = new Label(more_list[a]);
                        hbox.add(label);
                        var entry = new Entry();
                        string default_text = dbus_backend.Get(item, more_list[a]);
                        entry.set_text(default_text);
                        entry.changed.connect(() => {
                            if (entry.get_text() != null)
                            {
                                dbus_backend.Set(item, more_list[a], entry.get_text());
                            }
                        });
                        entry.show_all();
                        hbox.add(entry);
                    }
                    break;
            }
        }
        window.show_all();
    }

    public class ComboItemObject: GLib.Object
    {
        public string name { get; set;}
        public string exec { get; set;}
        public Gtk.Image icon { get; set;}
        public string icon_name { get; set;}
        public string desktop_path { get; set;}
        public string install_package { get; set;}

        public string[] tmp_item_array;

        public ComboItemObject(string item)
        {
            this.tmp_item_array = item.split_set(",",0);
            this.name = tmp_item_array[0];
            this.exec = tmp_item_array[1];
            this.icon = create_image(tmp_item_array[2]);
            this.icon_name = tmp_item_array[2];
            this.desktop_path = tmp_item_array[3];
            this.install_package = tmp_item_array[4];
        }

        public Gtk.Image create_image (string item_image_string)
        {
            Gtk.Image image = new Gtk.Image ();

            if (item_image_string[0:1] == "/")
            {
                /* Absolute path for the icon, load it directly */
                image.set_from_file(item_image_string);
            }
            else
            {
                /* Name icon, load it by the name */
                image.set_from_icon_name(item_image_string, Gtk.IconSize.MENU);
            }

            return image;

        }
    }

    Gtk.ComboBox init_combobox (    Gtk.Builder builder,
                                    DbusBackend dbus_backend,
                                    KeyFile kf,
                                    string combobox_name,
                                    string combobox_list_name,
                                    string by_default,
                                    string? generic_item)
    {

        var return_combobox = builder.get_object (combobox_name) as Gtk.ComboBox;

        Gtk.ListStore list_store = new Gtk.ListStore (4, typeof(string), typeof (string), typeof (int) , typeof(string));
	    Gtk.TreeIter iter;
        int default_index = -1;
        bool default_set = false;

        string[] combobox_list;

        if (generic_item != null)
        {
            combobox_list = get_mime_list(kf, generic_item, "installed");
        }
        else
        {
            combobox_list = get_mime_list(kf, combobox_list_name, "installed");
        }

        /* First row, empty for not selected and for unselect */
        list_store.append (out iter);
        list_store.set (iter, 0, "window-close" , 1, _("Disable"), 2, 0, 3,"");

        for (int a = 0 ; a < combobox_list.length ; a++)
        {
                string item_list = combobox_list[a];
                ComboItemObject combo_item = new ComboItemObject (item_list);

                list_store.append (out iter);

                list_store.set (iter, 0, combo_item.icon_name , 1, combo_item.name, 2, a, 3, combo_item.exec );
                if (combo_item.exec == by_default)
                {
                    /* move +1, because 1st row is Disable */
                    default_index = a + 1;
                    default_set = true;
                }
        }

        message ("Default = %s", by_default);

        if (by_default == "" )
        {
            default_index = 0;
            default_set = true;
        }
        if (default_set == false)
        {
            Value val;
            int last_position;
            list_store.append (out iter);
            list_store.get_value (iter, 2, out val);
            last_position = val.get_int() + 1;
            list_store.set (iter, 0, "" , 1, by_default, 2, last_position, 3,by_default);
        }

        return_combobox.set_model (list_store);

        Gtk.CellRendererPixbuf renderer_image = new Gtk.CellRendererPixbuf ();
        return_combobox.pack_start (renderer_image, false);
        return_combobox.add_attribute (renderer_image, "icon-name", 0);

        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        return_combobox.pack_start (renderer, false);
        return_combobox.add_attribute (renderer, "text", 1);

/*
            Debug Exec name

            Gtk.CellRendererText renderer_exec = new Gtk.CellRendererText ();
            return_combobox.pack_start (renderer_exec, true);
            return_combobox.add_attribute (renderer_exec, "text", 3);
*/


        return_combobox.active = 0;

        /* Set default */
        if (default_index == -1)
        {
            message ("Iter == -1");
            switch (by_default)
            {
                case (null):
                    return_combobox.set_active(0);
                    break;
                case (""):
                    return_combobox.set_active(0);
                    break;
                case (" "):
                    return_combobox.set_active(0);
                    break;
                default:
                    return_combobox.set_active_iter(iter);
                    break;
            }
        }
        else
        {
            message ("Iter == %d", default_index);
            return_combobox.set_active(default_index);
        }

        return_combobox.changed.connect (() => {
            Value val1;
            Value val2;

            return_combobox.get_active_iter (out iter);
            list_store.get_value (iter, 2, out val1);
            list_store.get_value (iter, 3, out val2);

            message ("Selection: %d, %s\n", (int) val1, (string) val2);

            if (val2.get_string() != null)
            {
                dbus_backend.Set(combobox_list_name, "command", val2.get_string());
                message ("Setting %s: %d, %s\n", combobox_list_name, (int) val1, (string) val2);
            }

            create_mime_associate_window(dbus_backend, kf, combobox_list_name, val2.get_string());

        });

        /* Disconnect scroll event, to avoid changing item when we are scrolling the windows */
        return_combobox.scroll_event.connect (() => {

        return true;

        });

        return return_combobox;
    }

    void create_mime_associate_window(DbusBackend dbus_backend, KeyFile kf, string combobox_list_name, string command)
    {
        var window_mime = new Window();
        window_mime.window_position = Gtk.WindowPosition.CENTER;
        window_mime.set_default_size (400, 200);
        window_mime.set_skip_taskbar_hint(true);
        try
        {
            window_mime.icon = IconTheme.get_default ().load_icon ("preferences-desktop", 48, 0);
        }
        catch (Error e)
        {
            message ("Could not load application icon: %s\n", e.message);
        }

        // The ScrolledWindow:
		Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
		window_mime.add (scrolled);

        var mime_view_port = new Gtk.Viewport(null, null);
        mime_view_port.set_size_request (200, 200);
        scrolled.add(mime_view_port);

        var mime_vbox = new Gtk.VBox(false, 0);
        mime_view_port.add(mime_vbox);

        var info_label = new Label(_("Do you want to associate the following Mimetype ?\n"));
        mime_vbox.add(info_label);

        string[] mime_combobox_list;
        mime_combobox_list = get_mime_list(kf, combobox_list_name, "installed");
        string default_path = "";

        for (int b = 0 ; b < mime_combobox_list.length ; b++)
        {
            string item_list = mime_combobox_list[b];
            ComboItemObject combo_item = new ComboItemObject (item_list);
            message("combo_item.desktop_path: %s", combo_item.desktop_path);
            message("combobox_list_name: %s", combobox_list_name);
            message("combo_item.exec: %s", combo_item.exec);

            if (command == combo_item.exec)
            {
                default_path = combo_item.desktop_path;
            }
        }

        message("Look at default_path: %s", default_path);

        if (default_path != "")
        {
            KeyFile kf_mime = new KeyFile();
            string[] mime_list;
            try
            {  
                kf_mime.load_from_file(default_path, KeyFileFlags.NONE);
            }
            catch (KeyFileError err)
            {
                warning (err.message);
            }
            catch (FileError err)
            {
                warning (err.message);
            }

            try
            {
                mime_list = kf_mime.get_string_list("Desktop Entry", "MimeType");
                if (mime_list.length >= 1)
                {
                    string base_name = Path.get_basename(default_path);
                    var hbox_buttons = new Gtk.HBox(false, 0);
                    var ok_button = new Gtk.Button.with_label("OK");
                    var cancel_button = new Gtk.Button.with_label(_("Cancel"));
                    mime_vbox.add(hbox_buttons);
                    hbox_buttons.add(ok_button);
                    hbox_buttons.add(cancel_button);
                    message("Enter mime try");
                    for (int i = 0 ; i < mime_list.length ; i++)
                    {
                        string message_mime = mime_list[i] + "\n";
                        message("Look at message_mime: %s", message_mime);
                        var label_mime = new Label(message_mime);
                        mime_vbox.add(label_mime);
                    }

                    ok_button.clicked.connect(() => {
                        save_mime_type(mime_list, base_name);
                        window_mime.destroy();
                    });

                    cancel_button.clicked.connect(() => {
                        window_mime.destroy();
                    });

                    window_mime.show_all();
                }
                else
                {
                    window_mime.destroy();
                }
            }
            catch (KeyFileError err)
            {
                warning (err.message);
            }
        }
    }

    void save_mime_type(string[] mime_list, string base_name)
    {
        string mimeapps_list_directory = Path.build_filename(Environment.get_home_dir (),".local", "share", "applications");
        KeyFile kf_mimeapps =  load_key_conf(mimeapps_list_directory, "mimeapps.list");
        string mimeapps_list_path = Path.build_filename(mimeapps_list_directory, "mimeapps.list");

        if (mime_list != null)
        {
            for (int i = 0 ; i < mime_list.length ; i++)
            {
                kf_mimeapps.set_string("Added Associations", mime_list[i], base_name);
                kf_mimeapps.set_string("Default Applications", mime_list[i], base_name);
            }
        }

        var str = kf_mimeapps.to_data (null);
        try
        {
            FileUtils.set_contents (mimeapps_list_path, str, str.length);
        }
        catch (FileError err)
        {
            warning (err.message);
        }
    }

    string return_combobox_text(Gtk.ComboBox combo)
    {
        Gtk.TreeIter iter;
        Gtk.ListStore model;
        GLib.Value value1;

        combo.get_active_iter (out iter);
        model = (Gtk.ListStore) combo.get_model ();
        model.get_value (iter, 0, out value1);

        message (" Return value for %s", (string) value1);

        return (string) value1;
    }


    string[] get_mime_list (KeyFile kf, string key1, string mode)
    {
        string keys = key1 + "/" + mode;
        string[] return_value = {};
        try
        {
            return_value = kf.get_string_list("Mime", keys);
        }
        catch (GLib.KeyFileError err)
        {
            warning (err.message);
        }
        return return_value;
    }

    public Gtk.ComboBox ui_combobox_init (  Gtk.Builder builder,
                                            string combobox_name,
                                            string[] combobox_list, 
                                            string? entry_name,
                                            string by_default)
    {
        Gtk.ListStore list_store = new Gtk.ListStore (2, typeof (string), typeof (int));
	    Gtk.TreeIter iter;
        int default_index = -1;

        for (int a = 0 ; a < combobox_list.length ; a++)
        {
                list_store.append (out iter);
                list_store.set (iter, 0, combobox_list[a], 1, a);
                if (combobox_list[a] == by_default)
                {
                    default_index = a;
                }
        }

        list_store.append (out iter);
        list_store.set (iter, 0, "Other", 1, 99);

        message ("Default = %s", by_default);

        var return_combobox = builder.get_object (combobox_name) as Gtk.ComboBox;
        return_combobox.set_model (list_store);

        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        return_combobox.pack_start (renderer, true);
        return_combobox.add_attribute (renderer, "text", 0);
        return_combobox.active = 0;

        /* Set default */
        if (default_index == -1)
        {
            switch (by_default)
            {
                case (null):
                    return_combobox.set_active(0);
                    break;
                case (""):
                    return_combobox.set_active(0);
                    break;
                case (" "):
                    return_combobox.set_active(0);
                    break;
                default:
                    return_combobox.set_active_iter(iter);
                    if (entry_name != null)
                    {
                        var entry_default = builder.get_object (entry_name) as Entry;
                        entry_default.set_text(by_default);
                        entry_default.show_all();
                    }
                    break;
            }
        }
        else
        {
            message ("Iter == %d", default_index);
            return_combobox.set_active(default_index);
            if (entry_name != null)
            {
                var entry_default = builder.get_object (entry_name) as Entry;
#if USE_GTK2
                entry_default.hide_all();
#endif
#if USE_GTK3
                entry_default.hide();
#endif

            }
        }

        return_combobox.changed.connect (() => {
            Value val1;
            Value val2;

            return_combobox.get_active_iter (out iter);
            list_store.get_value (iter, 0, out val1);
            list_store.get_value (iter, 1, out val2);

            message ("Selection: %s, %d\n", (string) val1, (int) val2);

            if (entry_name != null)
            {
                var entry = builder.get_object (entry_name) as Entry;

                if (val2 == 99)
                {
                    entry.show_all();
                }
                else
                {
#if USE_GTK2
                    entry.hide_all();
#endif
#if USE_GTK3
                    entry.hide();
#endif
                }
            }
        });

        return return_combobox;
    }
}
