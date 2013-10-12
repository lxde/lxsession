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

        message ("Defaut = %s", by_default);

        var return_combobox = builder.get_object (combobox_name) as Gtk.ComboBox;
        return_combobox.set_model (list_store);

        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        return_combobox.pack_start (renderer, true);
        return_combobox.add_attribute (renderer, "text", 0);
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
                entry_default.hide_all();
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
                    entry.hide_all();
                }
            }
        });

        return return_combobox;
    }

    public int return_combobox_position(Gtk.ComboBox combo)
    {
        Gtk.TreeIter iter;
        Gtk.ListStore model;
        GLib.Value value1;
        GLib.Value value1_position;

        combo.get_active_iter (out iter);
        model = (Gtk.ListStore) combo.get_model ();
        model.get_value (iter, 0, out value1);
        model.get_value (iter, 1, out value1_position);

        message (" Return position for %s", (string) value1);

        return (int) value1_position;
    }

    public string return_combobox_text(Gtk.ComboBox combo)
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

    void init_combobox_gui(Builder builder, DbusBackend dbus_backend, string key1, string key2, string[] default_values)
    {
        var combobox = new Gtk.ComboBox();
        var entry = builder.get_object (key1 + "_" + key2 + "_entry") as Entry;
        string default_get = dbus_backend.SessionGet(key1, key2);
        combobox = ui_combobox_init(    builder,
                                        key1 + "_" + key2 +"_combobox",
                                        default_values,
                                        key1 + "_" + key2 +"_entry",
                                        default_get);

        combobox.changed.connect (() => {
            if (return_combobox_position(combobox) == 99)
            {
                dbus_backend.SessionSet(key1, key2, entry.get_text());
            }
            else
            {
                dbus_backend.SessionSet(key1, key2, return_combobox_text(combobox));
            }
        });

        if (return_combobox_position(combobox) != 99)
        {
            message ("Hide !");
            var entry_box = (Gtk.Widget) entry;
            entry_box.hide();
        }
    }

    void init_launch_button(Builder builder, DbusBackend dbus_backend, string key1, string key2)
    {
        var button = builder.get_object(key1 + "_reload") as Gtk.Button;
        button.clicked.connect (() => {
            dbus_backend.SessionLaunch(key1, key2);
        });
    }
}
