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

namespace Lxsession
{
    /*  Facility for launching application by extending the env variable set by lxsession
        TODO : replace by something smart and using upstart / systemd if available
    */
    public void lxsession_spawn_command_line_async(string command_line)
    {
        string[] command = command_line.split_set(" ",0);

        try
        {
            string[] spawn_env = Environ.get ();
            Pid child_pid;

            Process.spawn_async (
                         null,
                         command,
                         spawn_env,
                         SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                         null,
                         out child_pid);

		    ChildWatch.add (child_pid, (pid, status) => {
			    Process.close_pid (pid);
		    });

        }
        catch (SpawnError err)
        {
            warning (err.message);
            warning ("Error when launching %s", command[0]);
        }
    }


}
