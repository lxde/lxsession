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
#if USE_ADVANCED_NOTIFICATIONS
using AppIndicator;
using Notify;
#endif
#endif

namespace Lxsession
{
#if USE_GTK
    public class MenuItemObject : Gtk.MenuItem
#else
    public class MenuItemObject : MenuItemGenericObject
#endif
    {
        public MenuItemObject ()
        {

        }
    }

    public class MenuItemGenericObject
    {
        public MenuItemGenericObject ()
        {

        } 
    }


#if USE_GTK
    public class MenuObject : Gtk.Menu
#else
    public class MenuObject : MenuGenericObject
#endif
    {
        public MenuObject ()
        {

        }
    }

    public class MenuGenericObject : GLib.Object
    {
        public delegate void ActionCallback ();

        public void add_item (string text, owned ActionCallback callback)
        {
            warning("Not implemented");
        }
    }

    public class IconObject : GLib.Object
    {
        public string name;
        public string icon_name;    
        public string notification_text;

        public MenuObject menu;
#if USE_GTK
#if USE_ADVANCED_NOTIFICATIONS
        public Indicator indicator;
        public Notify.Notification notification;
#endif
#endif

        public delegate void ActionCallback ();
        
        public IconObject(string name_param, string? icon_name_param, string? notification_param, MenuObject? menu_param)
        {
            this.name = name_param;

            if (icon_name_param != null)
            {
                this.icon_name = icon_name_param;
            }
            else
            {
                this.icon_name = "dialog-warning";
            }

            if (notification_param != null)
            {
                this.notification_text = notification_param;
            }

            this.menu = menu_param;
#if USE_GTK
#if USE_ADVANCED_NOTIFICATIONS
            this.indicator = new Indicator(this.name, this.icon_name, IndicatorCategory.APPLICATION_STATUS);
            this.notification = new Notify.Notification ("LXsession", this.notification_text, this.icon_name);
            this.notification.set_timeout(6000);
#endif
#endif
        }

#if USE_GTK
#if USE_ADVANCED_NOTIFICATIONS
        public void init()
        {
            if (this.indicator == null)
            {
                this.indicator = new Indicator(this.name, this.icon_name, IndicatorCategory.APPLICATION_STATUS);
            }

            this.indicator.set_status(IndicatorStatus.ACTIVE);

            if (this.menu != null)
            {
                this.indicator.set_menu(this.menu);
            }
        }

        public void activate()
        {
            message("Try activate");
            if (this.indicator != null)
            {
                message("Activate");
                this.indicator.set_status(IndicatorStatus.ACTIVE);
                try
                {
                    this.notification.show ();
                }
                catch (GLib.Error e)
                {
                    message ("Error: %s\n", e.message);
                }
                message("Activate done");
            }
        }

        public void inactivate()
        {
            message("Try inactivate");
            if (this.indicator != null)
            {
                message("Inactivate");
                this.indicator.set_status(IndicatorStatus.PASSIVE);
                message("Inactivate done");
            }
        }

        public void set_icon(string param_icon_name)
        {
            this.icon_name = param_icon_name;   
            message("Set new icon");
            this.indicator.icon_name = param_icon_name;
        }

        public void set_menu(MenuObject param_menu)
        {
            this.menu = param_menu;
            this.indicator.set_menu(param_menu);
        }

        public void add_action (string action, string label, owned ActionCallback callback)
        {
            if (this.notification != null)
            {
                this.notification.add_action (action, label, (n, a) => 
                {
                    callback ();
                });
            }
        }

        public void set_notification_body(string text)
        {
            if (this.notification != null)
            {
                this.notification_text = text;
                this.notification.body = text;
            }
        }

        public void clear_actions ()
        {
            if (this.notification != null)
            {
                this.notification.clear_actions() ;
            }
        }
#else
        public void init()
        {

        }

        public void activate()
        {

        }

        public void inactivate()
        {

        }

        public void set_icon(string param_icon_name)
        {

        }

        public void set_menu(MenuObject param_menu)
        {

        }

        public void add_action (string action, string label, owned ActionCallback callback)
        {

        }

        public void set_notification_body(string text)
        {

        }

        public void clear_actions ()
        {

        }
#endif
    }    
}
