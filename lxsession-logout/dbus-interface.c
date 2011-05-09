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

#include <config.h>
#include <glib.h>
#include <string.h>
#ifdef HAVE_DBUS
#include <dbus/dbus.h>
#endif

/*** Mechanism independent ***/

#ifdef HAVE_DBUS
/* D-Bus context. */
static struct {
    int connection_tried : 1;			/* True if connection has been tried */
    DBusConnection * connection;		/* Handle for connection */
} dbus_context;

enum { DBUS_TIMEOUT = 2000 };			/* Reply timeout */

/* FORWARDS */
gboolean dbus_ConsoleKit_CanStop(void);
gboolean dbus_ConsoleKit_CanRestart(void);
char * dbus_ConsoleKit_Stop(void);
char * dbus_ConsoleKit_Restart(void);
gboolean dbus_UPower_CanSuspend(void);
gboolean dbus_UPower_CanHibernate(void);
char * dbus_UPower_Suspend(void);
char * dbus_UPower_Hibernate(void);
gboolean dbus_HAL_CanShutdown(void);
gboolean dbus_HAL_CanReboot(void);
gboolean dbus_HAL_CanSuspend(void);
gboolean dbus_HAL_CanHibernate(void);
char * dbus_HAL_Shutdown(void);
char * dbus_HAL_Reboot(void);
char * dbus_HAL_Suspend(void);
char * dbus_HAL_Hibernate(void);
/* End FORWARDS */

/* Connect to the system bus.  Once a connection is made, it is saved for reuse. */
static DBusConnection * dbus_connect(void)
{
    if ((dbus_context.connection == NULL) && ( ! dbus_context.connection_tried))
    {
        DBusError error;
        dbus_error_init(&error);
        dbus_context.connection = dbus_bus_get(DBUS_BUS_SYSTEM, &error);
        if (dbus_context.connection == NULL)
        {
            g_warning(G_STRLOC ": Failed to connect to the system message bus: %s", error.message);
            dbus_error_free(&error);
        }
        dbus_context.connection_tried = TRUE;
    }

    return dbus_context.connection;
}

/* Send a message. */
static DBusMessage * dbus_send_message(DBusMessage * message, char * * error_text)
{
    /* Get a connection handle. */
    DBusConnection * connection = dbus_connect();
    if (connection == NULL)
        return FALSE;

    /* Send the message. */
    DBusError error;
    dbus_error_init(&error);
    DBusMessage * reply = dbus_connection_send_with_reply_and_block(connection, message, DBUS_TIMEOUT, &error);
    dbus_message_unref(message);
    if (reply == NULL)
    {
        if ((error.name == NULL) || (strcmp(error.name, DBUS_ERROR_NO_REPLY) != 0))
        {
            if (error_text != NULL)
                *error_text = g_strdup(error.message);
            g_warning(G_STRLOC ": DBUS: %s", error.message);
        }
        dbus_error_free(&error);
    }
    return reply;
}

/* Read a result for a method that returns void. */
static char * dbus_read_result_void(DBusMessage * reply)
{
    if (reply != NULL)
        dbus_message_unref(reply);

    /* No result.  Assume success. */
    return NULL;
}

/* Read a result for a method that returns boolean. */
static gboolean dbus_read_result_boolean(DBusMessage * reply)
{
    gboolean result = FALSE;
    if (reply != NULL)
    {
        /* Get the boolean result. */
        DBusError error;
        dbus_error_init(&error);
        dbus_bool_t status = dbus_message_get_args(
            reply,
            &error,
            DBUS_TYPE_BOOLEAN, &result,
            DBUS_TYPE_INVALID);
        dbus_message_unref(reply);
        if ( ! status)
        {
            g_warning(G_STRLOC ": DBUS: %s", error.message);
            dbus_error_free(&error);
            return FALSE;
        }
    }
    return result;
}
#endif

/*** ConsoleKit mechanism ***/

#ifdef HAVE_DBUS
/* Formulate a message to the ConsoleKit Manager interface. */
static DBusMessage * dbus_ConsoleKit_formulate_message(const char * const query)
{
    return dbus_message_new_method_call(
        "org.freedesktop.ConsoleKit",
        "/org/freedesktop/ConsoleKit/Manager",
        "org.freedesktop.ConsoleKit.Manager",
        query);
}
#endif

/* Send a specified message to the ConsoleKit interface and process a boolean result. */
static gboolean dbus_ConsoleKit_query(const char * const query)
{
#ifdef HAVE_DBUS
    return dbus_read_result_boolean(dbus_send_message(dbus_ConsoleKit_formulate_message(query), NULL));
#else
    return FALSE;
#endif
}

/* Send a specified message to the ConsoleKit interface and process a void result. */
static char * dbus_ConsoleKit_command(const char * const command)
{
#ifdef HAVE_DBUS
    char * error = NULL;
    dbus_read_result_void(dbus_send_message(dbus_ConsoleKit_formulate_message(command), &error));
    return error;
#else
    return NULL;
#endif
}

/* Invoke the CanStop method on ConsoleKit. */
gboolean dbus_ConsoleKit_CanStop(void)
{
    return dbus_ConsoleKit_query("CanStop");
}

/* Invoke the CanRestart method on ConsoleKit. */
gboolean dbus_ConsoleKit_CanRestart(void)
{
    return dbus_ConsoleKit_query("CanRestart");
}

/* Invoke the Stop method on ConsoleKit. */
char * dbus_ConsoleKit_Stop(void)
{
    return dbus_ConsoleKit_command("Stop");
}

/* Invoke the Restart method on ConsoleKit. */
char * dbus_ConsoleKit_Restart(void)
{
    return dbus_ConsoleKit_command("Restart");
}

/*** UPower mechanism ***/

#ifdef HAVE_DBUS
/* Formulate a message to the UPower interface. */
static DBusMessage * dbus_UPower_formulate_command(const char * const command)
{
    return dbus_message_new_method_call(
        "org.freedesktop.UPower",
	"/org/freedesktop/UPower",
	"org.freedesktop.UPower",
        command);
}
#endif

/* Send a specified message to the UPower interface and process a boolean result. */
static gboolean dbus_UPower_query(const char * const query)
{
#ifdef HAVE_DBUS
    /* Formulate a message to the Properties interface. */
    DBusMessage * message = dbus_message_new_method_call(
        "org.freedesktop.UPower",
	"/org/freedesktop/UPower",
	"org.freedesktop.DBus.Properties",
        "Get");
    const char * const interface_name = "org.freedesktop.UPower";
    dbus_message_append_args(message,
        DBUS_TYPE_STRING, &interface_name,
        DBUS_TYPE_STRING, &query,
        DBUS_TYPE_INVALID);

    /* Send the message. */
    DBusMessage * reply = dbus_send_message(message, NULL);
    if (reply == NULL)
	return FALSE;

    /* The return type is VARIANT expected to contain BOOLEAN. */
    gboolean result = FALSE;
    DBusMessageIter iter;
    DBusMessageIter inner;
    dbus_message_iter_init(reply, &iter);
    if (dbus_message_iter_get_arg_type(&iter) == DBUS_TYPE_VARIANT)
    {
        dbus_message_iter_recurse(&iter, &inner);
        if (dbus_message_iter_get_arg_type(&inner) == DBUS_TYPE_BOOLEAN)
            dbus_message_iter_get_basic(&inner, &result);
    }
    dbus_message_unref(reply);
    return result;
#else
    return FALSE;
#endif
}

/* Send a specified message to the UPower interface and process a void result. */
static char * dbus_UPower_command(const char * const command)
{
#ifdef HAVE_DBUS
    char * error = NULL;
    dbus_read_result_void(dbus_send_message(dbus_UPower_formulate_command(command), &error));
    return error;
#else
    return NULL;
#endif
}

/* Read the can-suspend property of UPower. */
gboolean dbus_UPower_CanSuspend(void)
{
    return dbus_UPower_query("CanSuspend");
}

/* Read the can-hibernate property of UPower. */
gboolean dbus_UPower_CanHibernate(void)
{
    return dbus_UPower_query("CanHibernate");
}

/* Invoke the Suspend method on UPower. */
char * dbus_UPower_Suspend(void)
{
    return dbus_UPower_command("Suspend");
}

/* Invoke the Hibernate method on UPower. */
char * dbus_UPower_Hibernate(void)
{
    return dbus_UPower_command("Hibernate");
}

/*** HAL mechanism ***/

#ifdef HAVE_DBUS
/* Formulate a message to the HAL SystemPowerManagement interface. */
static DBusMessage * dbus_HAL_formulate_message(const char * const query)
{
    return dbus_message_new_method_call(
        "org.freedesktop.Hal",
	"/org/freedesktop/Hal/devices/computer",
	"org.freedesktop.Hal.Device.SystemPowerManagement",
        query);
}

/* Formulate a message to the HAL SystemPowerManagement interface to query a property. */
static DBusMessage * dbus_HAL_formulate_property_query(const char * const method, const char * const property)
{
    DBusMessage * message = dbus_message_new_method_call(
        "org.freedesktop.Hal",
	"/org/freedesktop/Hal/devices/computer",
	"org.freedesktop.Hal.Device",
        method);
    if (message != NULL)
        dbus_message_append_args(message, DBUS_TYPE_STRING, &property, DBUS_TYPE_INVALID);
    return message;
}

/* Formulate a message to the HAL SystemPowerManagement interface to query a boolean property. */
static DBusMessage * dbus_HAL_formulate_boolean_property_query(const char * const property)
{
    return dbus_HAL_formulate_property_query("GetPropertyBoolean", property);
}

/* Formulate a message to the HAL SystemPowerManagement interface to query a string property. */
static DBusMessage * dbus_HAL_formulate_string_property_query(const char * const property)
{
    return dbus_HAL_formulate_property_query("GetPropertyString", property);
}
#endif

/* Send a specified property query to the HAL interface and process whether the result exists. */
static gboolean dbus_HAL_string_exists_query(const char * const property)
{
#ifdef HAVE_DBUS
    DBusMessage * message = dbus_HAL_formulate_string_property_query(property);
    if (message == NULL)
        return FALSE;
    DBusMessage * reply = dbus_send_message(message, NULL);
    if (reply == NULL)
	return FALSE;
    dbus_message_unref(reply);
    return TRUE;
#else
    return FALSE;
#endif
}

/* Send a specified property query to the HAL interface and process a boolean result. */
static gboolean dbus_HAL_boolean_query(const char * const property)
{
#ifdef HAVE_DBUS
    return dbus_read_result_boolean(dbus_send_message(dbus_HAL_formulate_boolean_property_query(property), NULL));
#else
    return FALSE;
#endif
}

/* Send a specified message to the HAL interface and process a void result. */
static char * dbus_HAL_command(const char * const command)
{
#ifdef HAVE_DBUS
    /* Formulate the message. */
    DBusMessage * message = dbus_HAL_formulate_message(command);
    if (message == NULL)
        return NULL;

    /* Suspend has an argument. */
    if (strcmp(command, "Suspend") == 0)
    {
        dbus_int32_t suspend_arg = 0;
        dbus_message_append_args(message, DBUS_TYPE_INT32, &suspend_arg, DBUS_TYPE_INVALID);
    }

    /* Send the message and wait for a reply. */
    char * error = NULL;
    dbus_read_result_void(dbus_send_message(message, &error));
    return error;
#else
    return NULL;
#endif
}

/* Read the can-shutdown property of HAL. */
gboolean dbus_HAL_CanShutdown(void)
{
    return dbus_HAL_string_exists_query("power_management.type");
}

/* Read the can-reboot property of HAL. */
gboolean dbus_HAL_CanReboot(void)
{
    return dbus_HAL_string_exists_query("power_management.type");
}

/* Read the can-suspend property of HAL. */
gboolean dbus_HAL_CanSuspend(void)
{
    return dbus_HAL_boolean_query("power_management.can_suspend");
}

/* Read the can-hibernate property of HAL. */
gboolean dbus_HAL_CanHibernate(void)
{
    return dbus_HAL_boolean_query("power_management.can_hibernate");
}

/* Invoke the Shutdown method on HAL. */
char * dbus_HAL_Shutdown(void)
{
    return dbus_HAL_command("Shutdown");
}

/* Invoke the Reboot method on HAL. */
char * dbus_HAL_Reboot(void)
{
    return dbus_HAL_command("Reboot");
}

/* Invoke the Suspend method on HAL. */
char * dbus_HAL_Suspend(void)
{
    return dbus_HAL_command("Suspend");
}

/* Invoke the Hibernate method on HAL. */
char * dbus_HAL_Hibernate(void)
{
    return dbus_HAL_command("Hibernate");
}
