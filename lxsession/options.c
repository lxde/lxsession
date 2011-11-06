/*
 *      options.c
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

#include <glib.h>

#include "default-apps.h"

void options_command_keymap(GKeyFile* kf)
{
    gchar * keymap_model = NULL, * keymap_layout = NULL, * keymap_variant = NULL, * keymap_options = NULL, * keymap_mode = NULL , * command = NULL, * mode = NULL;

    int status;
    char* output = NULL;

    keymap_mode = g_key_file_get_string( kf, "Keymap", "mode", NULL);

    /* Case 1 user => Use ~/.config/lxsession/SESSION/desktop.conf */
    if (g_strcmp0 (keymap_mode,"user"))
    {
        keymap_model = g_key_file_get_string( kf, "Keymap", "model", NULL);
        keymap_layout = g_key_file_get_string( kf, "Keymap", "layout", NULL);
        keymap_variant = g_key_file_get_string( kf, "Keymap", "variant", NULL);
        keymap_options = g_key_file_get_string( kf, "Keymap", "options", NULL);

        command = "setxkbmap" ;

    }

    /* Case 2 system => Use /etc/default/keyboard */
    if (g_strcmp0 (keymap_mode,"system"))
    {
        /*TODO read following parameters :
          XKBMODEL="pc105"
          XKBLAYOUT="fr"
          XKBVARIANT="oss"
          XKBOPTIONS=""
        */

        command = "setxkbmap" ;
    }

    if (keymap_model)
    {
        g_strconcat(command, " -model ", NULL); 
        g_strconcat(command, keymap_model, NULL);
    }

    if (keymap_layout)
    {
        g_strconcat(command, " -layout ", NULL); 
        g_strconcat(command, keymap_layout, NULL);
    }

    if (keymap_variant)
    {
        g_strconcat(command, " -variant ", NULL); 
        g_strconcat(command, keymap_variant, NULL);
    }

    if (keymap_options)
    {
        g_strconcat(command, " -options ", NULL); 
        g_strconcat(command, keymap_options, NULL);
    }

    if (command)
    {
        g_spawn_command_line_sync(command, &output, NULL, &status, NULL );
    }

}

void options_command_xrandr(GKeyFile* kf)
{
    gchar * xrandr_mode = NULL;
    xrandr_mode = g_key_file_get_string( kf, "XRandr", "mode", NULL);

    int status;
    char* output = NULL;

    if (xrandr_mode)
    {
         if (g_strcmp0 (xrandr_mode,"command"))
         {
             command = g_key_file_get_string( kf, "XRandr", "command", NULL);

             if (command)
             {
                 g_spawn_command_line_sync(command, &output, NULL, &status, NULL );
             }
         }
         /* TODO Implement fine grained configuration */
    }
}
