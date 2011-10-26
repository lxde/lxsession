/*
 *      default-apps.h
 *
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

/* Standart functions from lxsession.c */
void load_default_apps( const char* filename );

/*
Functions for specific default apps
Return TRUE if configuration file need to be sync / saved
*/
gboolean app_command_window_manager(GKeyFile* kf);
gboolean app_command_panel(GKeyFile* kf);
gboolean app_command_screensaver(GKeyFile* kf);

/* TODO
gchar app_command_power_manager(GKeyFile* kf);
gchar app_command_notifications(GKeyFile* kf);
#gchar app_command_ubuntu_one(GKeyFile* kf);
#gchar app_command_network_gui(GKeyFile* kf);
#gchar app_command_file_manager(GKeyFile* kf);
#gchar app_command_polkit(GKeyFile* kf);

#Functions for default configuration
#gchar app_command_sound_manager(GKeyFile* kf);
#gchar app_command_keymap_manager(GKeyFile* kf);
#gchar app_command_quit_manager(GKeyFile* kf);
#gchar app_command_workspace_manager(GKeyFile* kf);
#gchar app_command_launcher_manager(GKeyFile* kf);

Prototype :

================================================================
Window-manager      : openbox-lubuntu
                      compiz
                      safe-mode

Power-manager       : gnome-power-manager
                      xfce-power-manager
                      None
                      Auto (detect if it's a laptop or a desktop)

Sound management    : Alsa
                      Pulseaudio

Network-manager GUI : Network-manager applet
                      Connman
                      None
                      Auto (detect if it's a laptop or a desktop)
....

*/
