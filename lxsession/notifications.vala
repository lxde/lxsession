/* 
 *      Copyright 2015 Julien Lavergne <gilir@ubuntu.com>
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
#if USE_GTK
using Gtk;
using AppIndicator;
#endif

namespace Lxsession 
{
    [Compact]
    public class IconObject : GLib.Object
    {
        public string icon_name;
        public string tooltip_text;
        public string launch_menu_text;
        

        public IconObject(string? icon_name_param, string? tooltip_text_param, string? launch_menu_text_param )
        {
            if (icon_name_param != null)
            {
                this.icon_name = icon_name_param;
            }
            else
            {
                this.icon_name = "gtk-warning";
            }

            if (tooltip_text_param != null)
            {
                this.tooltip_text = tooltip_text_param;
            }
            else
            {
                this.tooltip_text = "";
            }

            if (launch_menu_text_param != null)
            {
                this.launch_menu_text = launch_menu_text_param;
            }
            else
            {
                this.launch_menu_text = "Launch";
            }
        }

        public void init()
        {
#if USE_GTK
            message("Enter notification code");
            var indicator = new Indicator(this.tooltip_text, this.icon_name,
                                          IndicatorCategory.APPLICATION_STATUS);

            indicator.set_status(IndicatorStatus.ACTIVE);

            var menu = new Gtk.Menu();

            var launch_menu = new Gtk.MenuItem.with_label(this.launch_menu_text);
            launch_menu.activate.connect(() => {
                /* TODO Launch Read and program */ 
            });
            launch_menu.show();
            menu.append(launch_menu);

            /*  Hack: Set an IndicatorStatus.ATTENTION, but don't show it, otherwise it doesn't show ...
                TODO See if the indicator type is the cause
            */
            var item = new Gtk.MenuItem.with_label("Dummy");
            item.activate.connect(() => {
                indicator.set_status(IndicatorStatus.ATTENTION);
            });
            menu.append(item);

            indicator.set_menu(menu);
#endif
//TODO Make it work without GTK
 
        }

     }

}
