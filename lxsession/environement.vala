/* 
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

using Posix;

namespace Lxsession {

public class LxsessionEnv: GLib.Object {

    private string display_env = "DISPLAY";
    private string pid_env = "_LXSESSION_PID";
    private string session_env = "DESKTOP_SESSION";
    private string desktop_environment_env = "XDG_CURRENT_DESKTOP";

    private string display_name;
    private string pid_str;
    private string session;
    private string desktop_environment;

    public LxsessionEnv(string session_arg, string desktop_environment_arg)
    {

        /* Constructor */
        session = session_arg;
        desktop_environment = desktop_environment_arg;
        display_name = Environment.get_variable(display_env);

    }

    public void export_env()
    {

        message("Exporting variable");
        message("desktop_environnement %s", desktop_environment_env);
        pid_str = "%d".printf (Posix.getpid());
        Environment.set_variable(session_env, session, true);
        Environment.set_variable(desktop_environment_env, desktop_environment, true);
        Environment.set_variable(pid_env, pid_str, true);
        Environment.set_variable(display_env, display_name, true);

        Environment.set_application_name ("lxsession");

    }

    public bool check_alone() {

        string lxsession_pid;

        message ("Getting lxsession pid");
        lxsession_pid = Environment.get_variable(pid_env);

        message ("Checking pid : %s", lxsession_pid);

        if (lxsession_pid == null)
        {
            message ("Lxsession not detected");
            return true;
        }
        else
        {
            message ("Lxsession detected");
            return false;
        }

    }
}

}
