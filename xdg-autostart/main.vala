/* 
 *      Copyright 2014 Julien Lavergne <gilir@ubuntu.com>
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
    public class Main: GLib.Object
    {
            static string desktop_environnement = null;

            const OptionEntry[] option_entries = {
            { "desktop_environnement", 'd', 0, OptionArg.STRING, ref desktop_environnement, "Desktop environment to use for desktop files, like LXDE, KDE ... Default to LXDE", "NAME" },
            { null }
            };

        public static int main(string[] args)
        {
            try
            {
                var options_args = new OptionContext("- Lxsession autostart utility");
                options_args.set_help_enabled(true);
                options_args.add_main_entries(option_entries, null);
                options_args.parse(ref args);
            }
            catch (OptionError e)
            {
                critical ("Option parsing failed: %s\n", e.message);
                return -1;
            }

            if (desktop_environnement == null)
            {
                xdg_autostart("LXDE");
                return 0;
            }
            else
            {
                xdg_autostart(desktop_environnement);
                return 0;
            }
        }
    }
}
