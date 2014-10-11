/*
 *      lxpolkit.h
 *
 *      Copyright 2011 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
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

#ifndef __LXPOLKIT_H__
#define __LXPOLKIT_H__

#include <glib.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

void show_msg(GtkWindow* parent, GtkMessageType type, const char* msg);

gboolean policykit_agent_init();
void policykit_agent_finalize();

G_END_DECLS

#endif

