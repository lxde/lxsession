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

/* http://live.gnome.org/Vala/DBusServerSample#Using_GDBus */

namespace Lxsession
{

[DBus(name = "org.gnome.SessionManager")]
public class GnomeSessionServer : Object {
    string not_implemented = "Error, lxsession doesn't implement this API";
/*
    string gnome_session_version = "3.2.1";
*/

    /* Public property, exported via D-Bus */
    public int something { get; set; }

    /* Public signal, exported via D-Bus
     * Can be emitted on the server side and can be connected to on the client side.
     */
    public signal void ClientAdded(out string path);
    public signal void ClientRemoved(out string path);
    public signal void InhibitorAdded(out string path);
    public signal void InhibitorRemoved(out string path);
    public signal void SessionRunning();
    public signal void SessionOver();

    /* Public method, exported via D-Bus */

    public void Setenv( string value ) {
        /* TODO To implement */
        /* Adds the variable name to the application launch environment with the specified value.  May only be used during the Session Manager initialization phase. */
        /* <arg name="value" type="s" direction="in"> */
        message(not_implemented);
    }

    public void InitializationError ( string mess, bool fatal ) {
        /* TODO To implement
        May be used by applications launched during the Session Manager initialization phase to indicate there was a problem.
        <arg name="mess" type="s" direction="in">
        The error message
        <arg name="fatal" type="b" direction="in">
        Whether the error should be treated as fatal
        */
        message(not_implemented);
    }

    public async void RegisterClient(string app_id, string client_startup_id) {
    /* TODO To implement
    <doc:para>Register the caller as a Session Management client.</doc:para>
    <annotation name="org.freedesktop.DBus.GLib.Async" value=""/>
    <arg type="s" name="app_id" direction="in">
    <doc:summary>The application identifier</doc:summary>
    <arg type="s" name="client_startup_id" direction="in">
    <doc:summary>Client startup identifier</doc:summary>
    <arg type="o" name="client_id" direction="out">
    <doc:summary>The object path of the newly registered client</doc:summary>
    */
        message(not_implemented);
    }

    public async void UnregisterClient() {
    /* TODO To implement
    <doc:para>Unregister the specified client from Session Management.</doc:para>
    <annotation name="org.freedesktop.DBus.GLib.Async" value=""/>
    <arg type="o" name="client_id" direction="in">
    <doc:summary>The object path of the client</doc:summary>
    */
        message(not_implemented);
    }

    public async void Inhibit(string app_id, uint toplevel_xid, string reason, uint flags, out uint inhibit_cookie)
    {
    /* TODO implement completly */
    /* Description :
		Applications should invoke this method when they begin an operation that
		should not be interrupted, such as creating a CD or DVD.  The types of actions
		that may be blocked are specified by the flags parameter.  When the application
		completes the operation it should call Uninhibit()
		or disconnect from the session bus.

    app_id : The application identifier
    toplevel_xid : the toplevel X window identifier
    reason : The reason for the inhibit
    flags : Flags that spefify what should be inhibited (Values for flags may be bitwise or'ed together.)
	    1 Inhibit logging out
	    2 Inhibit user switching
	    4 Inhibit suspending the session or computer
	    8 Inhibit the session being marked as idle

    inhibit_cookie :    The returned cookie is used to uniquely identify this request.  It should be used
                        as an argument to Uninhibit() in order to remove the request.
    */
    message("Call Inhibit function");
    inhibit_cookie = 0;
        if (flags == 8)
        {
            var control = new ControlObject();
            control.set_status_busy(toplevel_xid);
            uint cookie = Random.next_int();
            inhibit_cookie = cookie;
        }
    }

    public async void Uninhibit(uint inhibit_cookie)
    {
    /* Description : Cancel a previous call to Inhibit() identified by the cookie. */
        var control = new ControlObject();
        control.exit_status_busy();
    }
/*

    <method name="IsInhibited">
      <arg type="u" name="flags" direction="in">
        <doc:doc>
          <doc:summary>Flags that spefify what should be inhibited</doc:summary>
        </doc:doc>
      </arg>
      <arg type="b" name="is_inhibited" direction="out">
        <doc:doc>
          <doc:summary>Returns TRUE if any of the operations in the bitfield flags are inhibited</doc:summary>
        </doc:doc>
      </arg>
      <doc:doc>
        <doc:description>
          <doc:para>Determine if operation(s) specified by the flags
            are currently inhibited.  Flags are same as those accepted
            by the
            <doc:ref type="method" to="org.gnome.SessionManager.Inhibit">Inhibit()</doc:ref>
            method.</doc:para>
        </doc:description>
      </doc:doc>
    </method>

    <method name="GetClients">
      <arg name="clients" direction="out" type="ao">
        <doc:doc>
          <doc:summary>an array of client IDs</doc:summary>
        </doc:doc>
      </arg>
      <doc:doc>
        <doc:description>
          <doc:para>This gets a list of all the <doc:ref type="interface" to="org.gnome.SessionManager.Client">Clients</doc:ref>
          that are currently known to the session manager.</doc:para>
          <doc:para>Each Client ID is an D-Bus object path for the object that implements the
          <doc:ref type="interface" to="org.gnome.SessionManager.Client">Client</doc:ref> interface.</doc:para>
        </doc:description>
        <doc:seealso><doc:ref type="interface" to="org.gnome.SessionManager.Client">org.gnome.SessionManager.Client</doc:ref></doc:seealso>
      </doc:doc>
    </method>

    <method name="GetInhibitors">
      <arg name="inhibitors" direction="out" type="ao">
        <doc:doc>
          <doc:summary>an array of inhibitor IDs</doc:summary>
        </doc:doc>
      </arg>
      <doc:doc>
        <doc:description>
          <doc:para>This gets a list of all the <doc:ref type="interface" to="org.gnome.SessionManager.Inhibitor">Inhibitors</doc:ref>
          that are currently known to the session manager.</doc:para>
          <doc:para>Each Inhibitor ID is an D-Bus object path for the object that implements the
          <doc:ref type="interface" to="org.gnome.SessionManager.Inhibitor">Inhibitor</doc:ref> interface.</doc:para>
        </doc:description>
        <doc:seealso><doc:ref type="interface" to="org.gnome.SessionManager.Inhibitor">org.gnome.SessionManager.Inhibitor</doc:ref></doc:seealso>
      </doc:doc>
    </method>


    <method name="IsAutostartConditionHandled">
      <arg name="condition" direction="in" type="s">
        <doc:doc>
          <doc:summary>The autostart condition string</doc:summary>
        </doc:doc>
      </arg>
      <arg name="handled" direction="out" type="b">
        <doc:doc>
          <doc:summary>True if condition is handled, false otherwise</doc:summary>
        </doc:doc>
      </arg>
      <doc:doc>
        <doc:description>
          <doc:para>Allows the caller to determine whether the session manager is
          handling changes to the specified autostart condition.</doc:para>
        </doc:description>
      </doc:doc>
    </method>
*/

    public void Shutdown() {
        var session = new SessionObject();
        session.lxsession_shutdown();
    }
    public async void CanShutdown(out bool is_available) {
        var session = new SessionObject();
        is_available = yield session.lxsession_can_shutdown();
    }

    public void Logout(uint mode) {
       /* TODO To implement */
       /* 
       0 Normal
       1 No confirmation inferface should be shown.
       2 Forcefully logout.  No confirmation will be shown and any inhibitors will be ignored.
       */
        /*
        var session = new SessionObject();
        session.lxsession_restart(); */
        stdout.printf(not_implemented);
    }

    public void IsSessionRunning(out bool running )
    {
       /* TODO To implement
      <arg name="running" direction="out" type="b">
        <doc:doc>
          <doc:summary>True if the session has entered the Running phase, false otherwise</doc:summary>
        </doc:doc>
      </arg>
      <doc:doc>
        <doc:description>
          <doc:para>Allows the caller to determine whether the session manager
          has entered the Running phase, in case the client missed the
          SessionRunning signal.</doc:para>
        </doc:description>
      </doc:doc>
    */
    running = false;
    }


}

}
