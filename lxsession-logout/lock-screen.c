/**
 * lock-screen.c
 *
 * Copyright (c) 2010 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <sys/wait.h>
#include "lock-screen.h"

#define LOCK_SCRIPT_PATH PACKAGE_DATA_DIR "/lxsession/lock-screen.sh"

static void read_config(GKeyFile* kf, gboolean *do_lock, char** lock_cmd, gboolean* has_do_lock, gboolean* has_lock_cmd)
{
    if(!*has_do_lock && g_key_file_has_key(kf, "Session", "LockScreen", NULL))
    {
        *do_lock = g_key_file_get_boolean(kf, "Session", "LockScreen", NULL);
        *has_do_lock = TRUE;
    }
    if(!*has_lock_cmd && g_key_file_has_key(kf, "Session", "LockCommand", NULL))
    {
        *lock_cmd = g_key_file_get_string(kf, "Session", "LockCommand", NULL);
        *has_lock_cmd = TRUE;
    }
}

gboolean lock_screen()
{
    gboolean ret = TRUE;
    /* try to load config file */
    const char * session_name = g_getenv("DESKTOP_SESSION");
    gboolean do_lock = TRUE;
    char* lock_cmd = NULL;

    if(session_name)
    {
        gboolean has_do_lock = FALSE;
        gboolean has_lock_cmd = FALSE;
        const gchar* const* dirs = g_get_system_config_dirs();
        int i, n = g_strv_length(dirs);

        GKeyFile* kf = g_key_file_new();
        char* file = g_build_filename(g_get_user_config_dir(), "lxsession", session_name, "desktop.conf", NULL);
        if(g_key_file_load_from_file(kf, file, 0, NULL))
            read_config(kf, &do_lock, &lock_cmd, &has_do_lock, &has_lock_cmd);
        g_free(file);

        for(i = n - 1; !(has_do_lock && has_lock_cmd) && i >= 0; --i)
        {
            file = g_build_filename(dirs[i], "lxsession", session_name, "desktop.conf", NULL);
            if(g_key_file_load_from_file(kf, file, 0, NULL))
                read_config(kf, &do_lock, &lock_cmd, &has_do_lock, &has_lock_cmd);
            g_free(file);
        }
        g_key_file_free(kf);
    }

    if(do_lock)
    {
        const char* cmd = lock_cmd ? lock_cmd : LOCK_SCRIPT_PATH;
        int status;
        if(g_spawn_command_line_sync(cmd, NULL, NULL, &status, NULL))
        {
            if(!(WIFEXITED(status) && WEXITSTATUS(status) == 0))
                ret = FALSE;
        }
        else
            ret = FALSE;
    }
    g_free(lock_cmd);

    return ret;
}
