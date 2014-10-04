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

using Gtk;

namespace Lxsession
{
    public class GenericWindow : Gtk.Window
    {
	    public GenericWindow (string message)
        {
		    // Prepare Gtk.Window:
		    this.title = "Lxsession Message";
		    this.window_position = Gtk.WindowPosition.CENTER;
		    this.destroy.connect (Gtk.main_quit);
		    this.set_default_size (350, 70);

		    // The MessageDialog
		    Gtk.MessageDialog msg = new Gtk.MessageDialog ( this,
                                                            Gtk.DialogFlags.MODAL,
                                                            Gtk.MessageType.WARNING,
                                                            Gtk.ButtonsType.OK_CANCEL,
                                                            message);

			msg.response.connect ((response_id) =>
            {
			    switch (response_id) {
				    case Gtk.ResponseType.OK:
					    stdout.puts ("Ok\n");
					    break;
				    case Gtk.ResponseType.CANCEL:
					    stdout.puts ("Cancel\n");
					    break;
				    case Gtk.ResponseType.DELETE_EVENT:
					    stdout.puts ("Delete\n");
					    break;
			}
			msg.destroy();
            Gtk.main_quit();
		    });
		    msg.show ();
        }
	}

    public class Main: GLib.Object
    {
        static string message = "";
        static string type = "";

        const OptionEntry[] option_entries = {
        { "message", 'm', 0, OptionArg.STRING, ref message, "specify a string to be to displayed as a message", "NAME" },
        { "type", 't', 0, OptionArg.STRING, ref type, "specify the type of the message (w = warning, i = info)", "NAME" },
        { null }
        };

        public static int main(string[] args)
        {
            try
            {
                var options_args = new OptionContext("- Lxsession message utility");
                options_args.set_help_enabled(true);
                options_args.add_main_entries(option_entries, null);
                options_args.parse(ref args);
            }
            catch (OptionError e)
            {
                critical ("Option parsing failed: %s\n", e.message);
                return -1;
            }

            Gtk.init (ref args);

            /* TODO Handle type of message with new class of window */
		    GenericWindow app = new GenericWindow (message);
		    app.show_all ();

            /* start main loop */
            Gtk.main ();

            return 0;
        }
    }
}
