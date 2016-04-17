/* Taken from LightDM and modified.
 * Copyright (C) 2012 Fabrice THIROUX <fabrice.thiroux@free.fr>.
 *
 **** License from former file (power.c) ****
 *
 * Copyright (C) 2010-2011 Robert Ancell.
 * Author: Robert Ancell <robert.ancell@canonical.com>
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option) any
 * later version. See http://www.gnu.org/copyleft/lgpl.html the full text of the
 * license.
 */
#include <config.h>
#include <glib.h>
#include <string.h>
#include <gio/gio.h>

/*** Mechanism independent ***/

static GDBusProxy *upower_proxy = NULL;
static GDBusProxy *ck_proxy = NULL;
static GDBusProxy *systemd_proxy = NULL;
static GDBusProxy *lightdm_proxy = NULL;
static GDBusProxy *lxde_proxy = NULL;


/*** UPower mechanism ***/

static gboolean
upower_call_function (const gchar *function, gboolean default_result, GError **error)
{
    GVariant *result;
    gboolean function_result = FALSE;

    if (!upower_proxy)
    {
        upower_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      "org.freedesktop.UPower",
                                                      "/org/freedesktop/UPower",
                                                      "org.freedesktop.UPower",
                                                      NULL,
                                                      error);
        if (!upower_proxy)
            return FALSE;
    }

    result = g_dbus_proxy_call_sync (upower_proxy,
                                     function,
                                     NULL,
                                     G_DBUS_CALL_FLAGS_NONE,
                                     -1,
                                     NULL,
                                     error);
    if (!result)
        return default_result;

    if (g_variant_is_of_type (result, G_VARIANT_TYPE ("(b)")))
        g_variant_get (result, "(b)", &function_result);

    g_variant_unref (result);
    return function_result;
}

gboolean
dbus_UPower_CanSuspend (void)
{
    return upower_call_function ("SuspendAllowed", FALSE, NULL);
}

gboolean
dbus_UPower_Suspend (GError **error)
{
    return upower_call_function ("Suspend", TRUE, error);
}

gboolean
dbus_UPower_CanHibernate (void)
{
    return upower_call_function ("HibernateAllowed", FALSE, NULL);
}

gboolean
dbus_UPower_Hibernate (GError **error)
{
    return upower_call_function ("Hibernate", TRUE, error);
}

/*** ConsoleKit mechanism ***/

static gboolean
ck_query (const gchar *function, gboolean default_result, GError **error)
{
    GVariant *result;
    gboolean function_result = FALSE;
    const gchar *str;

    if (!ck_proxy)
    {
        ck_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      "org.freedesktop.ConsoleKit",
                                                      "/org/freedesktop/ConsoleKit/Manager",
                                                      "org.freedesktop.ConsoleKit.Manager",
                                                      NULL,
                                                      error);
        if (!ck_proxy)
            return FALSE;
    }

    result = g_dbus_proxy_call_sync (ck_proxy,
                                     function,
                                     NULL,
                                     G_DBUS_CALL_FLAGS_NONE,
                                     -1,
                                     NULL,
                                     error);
    if (!result)
        return default_result;

    if (g_variant_is_of_type (result, G_VARIANT_TYPE ("(s)")))
    {
			g_variant_get (result, "(s)", &str);
			if ( g_strcmp0 (str, "yes") == 0 || g_strcmp0 (str, "challenge") == 0 )
				function_result = TRUE;
			else
				function_result = default_result;
		}

    g_variant_unref (result);
    return function_result;
}

static void
ck_call_function (const gchar *function, gboolean value, GError **error)
{
    GVariant *result;

    if (!ck_proxy)
    {
        ck_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      "org.freedesktop.ConsoleKit",
                                                      "/org/freedesktop/ConsoleKit",
                                                      "org.freedesktop.ConsoleKit.Manager",
                                                      NULL,
                                                      error);
        if (!ck_proxy)
            return;
    }

    result = g_dbus_proxy_call_sync (ck_proxy,
                                     function,
                                     g_variant_new ("(b)", value),
                                     G_DBUS_CALL_FLAGS_NONE,
                                     -1,
                                     NULL,
                                     error);
    g_variant_unref (result);
    return;
}

gboolean
dbus_ConsoleKit_CanPowerOff (void)
{
    return ck_query ("CanPowerOff", FALSE, NULL);
}

void
dbus_ConsoleKit_PowerOff (GError **error)
{
    ck_call_function ("PowerOff", TRUE, error);
}

gboolean
dbus_ConsoleKit_CanReboot (void)
{
    return ck_query ("CanReboot", FALSE, NULL);
}

void
dbus_ConsoleKit_Reboot (GError **error)
{
    ck_call_function ("Reboot", TRUE, error);
}

gboolean
dbus_ConsoleKit_CanSuspend (void)
{
    return ck_query ("CanSuspend", FALSE, NULL);
}

void
dbus_ConsoleKit_Suspend (GError **error)
{
    ck_call_function ("Suspend", TRUE, error);
}

gboolean
dbus_ConsoleKit_CanHibernate (void)
{
    return ck_query ("CanHibernate", FALSE, NULL);
}

void
dbus_ConsoleKit_Hibernate (GError **error)
{
    ck_call_function ("Hibernate", TRUE, error);
}

/*** Systemd mechanism ***/

static gboolean
systemd_query (const gchar *function, gboolean default_result, GError **error)
{
    GVariant *result;
    gboolean function_result = FALSE;
    const gchar *str;

    if (!systemd_proxy)
    {
        systemd_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      "org.freedesktop.login1",
                                                      "/org/freedesktop/login1",
                                                      "org.freedesktop.login1.Manager",
                                                      NULL,
                                                      error);
        if (!systemd_proxy)
            return FALSE;
    }

    result = g_dbus_proxy_call_sync (systemd_proxy,
                                     function,
                                     NULL,
                                     G_DBUS_CALL_FLAGS_NONE,
                                     -1,
                                     NULL,
                                     error);
    if (!result)
        return default_result;

    if (g_variant_is_of_type (result, G_VARIANT_TYPE ("(s)")))
    {
			g_variant_get (result, "(s)", &str);
			if ( g_strcmp0 (str, "yes") == 0 || g_strcmp0 (str, "challenge") == 0 )
				function_result = TRUE;
			else
				function_result = default_result;
		}

    g_variant_unref (result);
    return function_result;
}

static void
systemd_call_function (const gchar *function, gboolean value, GError **error)
{
    GVariant *result;

    if (!systemd_proxy)
    {
        systemd_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      "org.freedesktop.login1",
                                                      "/org/freedesktop/login1",
                                                      "org.freedesktop.login1.Manager",
                                                      NULL,
                                                      error);
        if (!systemd_proxy)
            return;
    }

    result = g_dbus_proxy_call_sync (systemd_proxy,
                                     function,
                                     g_variant_new ("(b)", value),
                                     G_DBUS_CALL_FLAGS_NONE,
                                     -1,
                                     NULL,
                                     error);
    g_variant_unref (result);
    return;
}

gboolean
dbus_systemd_CanPowerOff (void)
{
    return systemd_query ("CanPowerOff", FALSE, NULL);
}

void
dbus_systemd_PowerOff (GError **error)
{
    systemd_call_function ("PowerOff", TRUE, error);
}

gboolean
dbus_systemd_CanReboot (void)
{
    return systemd_query ("CanReboot", FALSE, NULL);
}

void
dbus_systemd_Reboot (GError **error)
{
    systemd_call_function ("Reboot", TRUE, error);
}

gboolean
dbus_systemd_CanSuspend (void)
{
    return systemd_query ("CanSuspend", FALSE, NULL);
}

void
dbus_systemd_Suspend (GError **error)
{
    systemd_call_function ("Suspend", TRUE, error);
}

gboolean
dbus_systemd_CanHibernate (void)
{
    return systemd_query ("CanHibernate", FALSE, NULL);
}

void
dbus_systemd_Hibernate (GError **error)
{
    systemd_call_function ("Hibernate", TRUE, error);
}

/*** Lightdm mechanism ***/

static gboolean
lightdm_call_function (const gchar *function, gboolean default_result, GError **error)
{
    GVariant *result;
    gboolean function_result = FALSE;

    if (!lightdm_proxy)
    {
        lightdm_proxy = g_dbus_proxy_new_for_bus_sync ( G_BUS_TYPE_SYSTEM,
                                                        G_DBUS_PROXY_FLAGS_NONE,
                                                        NULL,
                                                        "org.freedesktop.DisplayManager",
                                                        g_getenv ("XDG_SEAT_PATH"),
                                                        "org.freedesktop.DisplayManager.Seat",
                                                        NULL,
                                                        error);
        if (!lightdm_proxy)
            return FALSE;
    }

    result = g_dbus_proxy_call_sync (lightdm_proxy,
                                     function,
                                     NULL,
                                     G_DBUS_CALL_FLAGS_NONE,
                                     -1,
                                     NULL,
                                     error);
    if (!result)
        return default_result;

    if (g_variant_is_of_type (result, G_VARIANT_TYPE ("(b)")))
        g_variant_get (result, "(b)", &function_result);

    g_variant_unref (result);
    return function_result;
}

gboolean
dbus_Lightdm_SwitchToGreeter (GError **error)
{
    return lightdm_call_function ("SwitchToGreeter", TRUE, error);
}

/*** LXDE mechanism ***/

static gboolean
lxde_call_function (const gchar *function, gboolean default_result, GError **error)
{
    GVariant *result;
    gboolean function_result = FALSE;

    if (!lxde_proxy)
    {
        lxde_proxy = g_dbus_proxy_new_for_bus_sync (    G_BUS_TYPE_SYSTEM,
                                                        G_DBUS_PROXY_FLAGS_NONE,
                                                        NULL,
                                                        "org.lxde.SessionManager",
                                                        "/org/lxde/SessionManager",
                                                        "org.lxde.SessionManager",
                                                        NULL,
                                                        error);
        if (!lxde_proxy)
            return FALSE;
    }

    result = g_dbus_proxy_call_sync (lxde_proxy,
                                     function,
                                     NULL,
                                     G_DBUS_CALL_FLAGS_NONE,
                                     -1,
                                     NULL,
                                     error);
    if (!result)
        return default_result;

    if (g_variant_is_of_type (result, G_VARIANT_TYPE ("(b)")))
        g_variant_get (result, "(b)", &function_result);

    g_variant_unref (result);
    return function_result;
}

gboolean
dbus_LXDE_Logout (GError **error)
{
    return lxde_call_function ("Restart", TRUE, error);
}
