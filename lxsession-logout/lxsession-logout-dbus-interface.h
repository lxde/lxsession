/**
 * Copyright (c) 2010 LxDE Developers, see the file AUTHORS for details.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef _DBUS_INTERFACE_H
#define _DBUS_INTERFACE_H

#include <glib.h>

/* Interface to ConsoleKit for suspend, hibernate, shutdown and reboot. */
extern gboolean dbus_ConsoleKit_CanPowerOff(void);
extern gboolean dbus_ConsoleKit_CanReboot(void);
extern gboolean dbus_ConsoleKit_CanSuspend(void);
extern gboolean dbus_ConsoleKit_CanHibernate(void);
extern void dbus_ConsoleKit_PowerOff(GError **);
extern void dbus_ConsoleKit_Reboot(GError **);
extern void dbus_ConsoleKit_Suspend(GError **);
extern void dbus_ConsoleKit_Hibernate(GError **);

/* Interface to UPower for suspend and hibernate. */
extern gboolean dbus_UPower_CanSuspend(void);
extern gboolean dbus_UPower_CanHibernate(void);
extern gboolean dbus_UPower_Suspend(GError **);
extern gboolean dbus_UPower_Hibernate(GError **);

/* Interface to systemd for suspend, hibernate, shutdown and reboot. */
extern gboolean dbus_systemd_CanPowerOff(void);
extern gboolean dbus_systemd_CanReboot(void);
extern gboolean dbus_systemd_CanSuspend(void);
extern gboolean dbus_systemd_CanHibernate(void);
extern void dbus_systemd_PowerOff(GError **);
extern void dbus_systemd_Reboot(GError **);
extern void dbus_systemd_Suspend(GError **);
extern void dbus_systemd_Hibernate(GError **);

/* Interface to lightdm for switch user. */
extern gboolean dbus_Lightdm_SwitchToGreeter (GError **error);

/* Interface to lxde for logout. */
extern gboolean dbus_LXDE_Logout (GError **error);

#endif
