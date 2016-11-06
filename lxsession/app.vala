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

/* 
   TODO packagekit handler (GUI and stuff) ?
   TODO Use wnck for managing launching applications ?
*/
using Posix;

namespace Lxsession
{

public class AppObject: GLib.Object
{

    /* Core App Object, all other App objects should inherent from it
       You should not do an instance of it, use SimpleAppObject if you want
       a usefull Object
    */

    public Pid pid;

    public string name { get; set;}
    public string[] command { get; set;}
    public bool guard { get; set; default = false;}
    public string application_type { get; set;}
    public int crash_count { get; set; default = 0;}

    /* Number of time the application have to crash before stoping to reload */
    public int stop_reload { get; set; default = 5;}

    public AppObject()
    {
        init();
    }

    public void launch ()
    {
        generic_launch (null);
    }

    public void generic_launch (string? arg1)
    {
        if (this.name != null)
        {
            if (this.name != "")
            {
                try
                {
                    string[] spawn_env = Environ.get ();
                    Process.spawn_async (
                                 arg1,
                                 this.command,
                                 spawn_env,
                                 SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                 null,
                                 out this.pid);
                    ChildWatch.add(this.pid, callback_pid);

                    message ("Launching %s ", this.name);

                    for (int a = 0 ; a <= this.command.length ; a++)
                    {
                        GLib.stdout.printf("%s ",this.command[a]);
                    }
                    GLib.stdout.printf("\n");
                }
                catch (SpawnError err)
                {
                    warning (err.message);
                    warning ("Error when launching %s", this.name);
                }
            }
        }
    }

    public virtual void read_config_settings()
    {
        /* Each object need to implement this, so settings will be read when process is reloaded */
    }

    public virtual void read_settings()
    {
        /* Each object need to implement this, so settings will be read when process is reloaded */
    }

    public void stop()
    {
        if ((int) this.pid != 0)
        {
            message("Stopping process with pid %d", (int) this.pid);
            Posix.kill ((int) this.pid, 15);
        }
    }

    public void reload()
    {
        message("Reloading process");
        this.stop();
        this.launch();
    }

    public void init()
    {
        read_config_settings();
        read_settings();
    }

    private void callback_pid(Pid pid, int status)
    {
        /* Help :  http://en.wikipedia.org/wiki/Signal_(computing) 
                   http://valadoc.org/glib-2.0/GLib.ProcessSignal.html
        */
        message("%s exit with this type of exit: %i", this.name, status);

        Process.close_pid (pid);

        if (this.guard == true)
        {
            switch (status)
            {
                case 0:
                    message("Exit normal, don't reload");
                    break;
                case 15:
                    message("Exit by the user, don't reload");
                    break;
                case 256:
                    message("Exit normal, don't reload");
                    break;
                default:
                    message("Exit not normal, try to reload");
                    this.crash_count = this.crash_count + 1;
                    if (this.crash_count <= this.stop_reload)
                    {
                        this.launch();
                    }
                    else
                    {
                        message("Application crashed too much, stop reloading");
                    }
                    break;
	        }
        }
    }
}


public class SimpleAppObject: AppObject
{

    public SimpleAppObject()
    {
        this.name = "";
        this.command = {""};
        this.guard = false;
        this.application_type = "";
    }
} 

public class GenericAppObject: AppObject
{

    public GenericAppObject(AppType app_type)
    {
        this.name = app_type.name;
        this.command = app_type.command;
        this.guard = app_type.guard;
        this.application_type = app_type.application_type;
    }
} 

public class GenericSimpleApp: SimpleAppObject
{
    public string settings_command { get; set; default = "";}

    public GenericSimpleApp (string argument)
    {
        settings_command = argument;
        init();
    }

    public override void read_settings()
    {
        string[] create_command = settings_command.split_set(" ",0);
        this.name = create_command[0];
        this.command = create_command;
    }
}

public class WindowsManagerApp: SimpleAppObject
{
    string wm_command;
    string mode;
    string session;
    string extras;

    public WindowsManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        if (global_settings.get_item_string("Session", "window_manager", null) != null)
        {
            mode = "simple";
            wm_command = global_settings.get_item_string("Session", "window_manager", null);
            session = "";
            extras = "";
        }
        else
        {
            mode = "advanced";
            wm_command = global_settings.get_item_string("Session", "windows_manager", "command");
            session = global_settings.get_item_string("Session", "windows_manager", "session");
            extras = global_settings.get_item_string("Session", "windows_manager", "extras");
        }

        string session_command;

        if (wm_command == "wm_safe") 
        {
            this.name = "wm_safe";
            this.command = {find_window_manager()};
        }
        else
        {
            if (mode == "simple")
            {
                this.name = wm_command;
                this.command = {wm_command};
            }
            else
            {
                this.name = wm_command;
                string create_command;
                string xdg_config_env = Environment.get_variable("XDG_CONFIG_HOME");
                switch (wm_command)
                {
                    case "openbox":
                        switch (session)
                        {
                            case "LXDE":
                                session_command = " --config-file " + xdg_config_env + "/openbox/lxde-rc.xml";
                                break;
                            case "Lubuntu":
                                session_command = " --config-file " + xdg_config_env + "/openbox/lubuntu-rc.xml";
                                break;
                            default:
                                session_command = " ";
                                break;
                        }
                        break;

                    case "openbox-custom":
                        switch (session)
                        {
                            default:
                                session_command = " --config-file " + session;
                                break;
                        }
                        break;

                    default:
                        session_command = null;
                        break;
                }

                switch (extras)
                {
                    case null:
                        create_command = wm_command + session_command;
                        break;
                    case "":
                        create_command = wm_command + session_command;
                        break;
                    case " ":
                        create_command = wm_command + session_command;
                        break;
                    default:
                        create_command = wm_command + session_command + " " + extras;
                        break;
                }

                this.command = create_command.split_set(" ",0);
            }
        }
        this.guard = true;
    }

    private string find_window_manager()
    {

        var wm_list = new Array<string> ();

        wm_list.append_val("openbox-lxde");
        wm_list.append_val("openbox-lubuntu");
        wm_list.append_val("openbox");
        wm_list.append_val("compiz");
        wm_list.append_val("kwin");
        wm_list.append_val("mutter");
        wm_list.append_val("fluxbox");
        wm_list.append_val("metacity");
        wm_list.append_val("xfwin");
        wm_list.append_val("matchbox");

        string return_value = "";

        for(int i = 0; i < wm_list.length; ++i)
        {
			unowned string wm = wm_list.index(i);
            string test_wm = Environment.find_program_in_path(wm);
            if ( test_wm != null)
            {
                message ("Finding %s",wm);
                return_value = wm;
                break;
            }
        }

        return return_value;

    }

    private void callback_pid(Pid pid, int status)
    {
        /* Help :  http://en.wikipedia.org/wiki/Signal_(computing) 
                   http://valadoc.org/glib-2.0/GLib.ProcessSignal.html
        */
        message("%s exit with this type of exit: %i\n", this.name, status);

        if (status == -1)
        {
            this.name = "wm_safe";
            this.command = {find_window_manager()};
            global_settings.set_generic_default("Session", "windows_manager", "command", "string", "wm_safe");
        }

        Process.close_pid (pid);

        if (this.guard == true)
        { 
	        switch (status)
            {
                case 0:
                    message("Exit normal, don't reload");
                    break;
                case 15:
                    message("Exit by the user, don't reload");
                    break;
                case 256:
                    message("Exit normal, don't reload");
                    break;
                default:
                    message("Exit not normal, try to reload");
                    this.crash_count = this.crash_count + 1;
                    if (this.crash_count <= this.stop_reload)
                    {
                        this.launch();
                    }
                    else
                    {
                        message("Application crashed too much, stop reloading");
                    }
                    break;
	        }
        }
    }

    public new void launch ()
    {
        this.read_config_settings();
        this.read_settings();

        if (this.name != null)
        {
            try
            {
                string[] spawn_env = Environ.get ();
                Process.spawn_async (
                             null,
                             this.command,
                             spawn_env,
                             SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                             null,
                             out pid);
                ChildWatch.add(pid, this.callback_pid);

                for (int a = 0 ; a <= this.command.length ; a++)
                {
                    GLib.stdout.printf("%s ",this.command[a]);
                }
                GLib.stdout.printf("\n");

            }
            catch (SpawnError err)
            {
                warning (err.message);
            }
        }

    }
}

public class PanelApp: SimpleAppObject
{
    public string panel_command;
    public string panel_session;

    public PanelApp ()
    {
        init();
    }

    public override void read_config_settings()
    {
        panel_command = global_settings.get_item_string("Session", "panel", "command");
        // message("DEBUG6 : %s", global_settings.get_item_string("Session", "panel", "command"));
        panel_session = global_settings.get_item_string("Session", "panel", "session");
        // message("DEBUG6 : %s", global_settings.get_item_string("Session", "panel", "session"));
    }

    public override void read_settings()
    {
        switch (panel_command) 
        {
            case "lxpanel":
                this.name = panel_command;
                if (panel_session != null)
                {
                    string create_command = "lxpanel --profile " + panel_session;
                    this.command = create_command.split_set(" ",0);
                }
                else
                {
                    this.command = {panel_command};
                }
                break;
            case "awn":
                this.name = panel_command;
                string create_command = "avant-window-navigator";
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = panel_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
        this.guard = true;
    }
}

public class DockApp: PanelApp
{
    public DockApp ()
    {
        init();
    }

    public override void read_config_settings()
    {
        panel_command = global_settings.get_item_string("Session", "dock", "command");
        panel_session = global_settings.get_item_string("Session", "dock", "session");
    }
}

public class ScreensaverApp: SimpleAppObject
{
    string screensaver_command;

    public ScreensaverApp ()
    {
        init();
    }

    public override void read_settings()
    {
        screensaver_command = global_settings.get_item_string("Session", "screensaver", "command");

        switch (screensaver_command) 
        {
            case "xscreensaver":
                this.name = screensaver_command;
                string create_command = "xscreensaver -no-splash";
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = screensaver_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
        this.guard = true;
    }
}

public class PowerManagerApp: SimpleAppObject
{
    string powermanager_command;
    string laptop_mode;

    public PowerManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        powermanager_command = global_settings.get_item_string("Session", "power_manager", "command");
        laptop_mode = global_settings.get_item_string("State", "laptop_mode", null);

        switch (powermanager_command) 
        {
            case "auto":
                /* If we are on a laptop, we need a power manager, try to start xfce one */
                /* If we are not on a laptop, assume we don't need power management */
                if (laptop_mode == "yes")
                {
                    string create_command = "xfce4-power-manager";
                    this.name = "xfce4-power-manager";
                    this.command = create_command.split_set(" ",0);
                }

                break;
            case "no":
                this.name = "power_manager_off";
                break;
            default:
                string[] create_command = powermanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
        this.guard = true;
    }
}

public class FileManagerApp: SimpleAppObject
{
    string filemanager_command;
    string filemanager_session;
    string filemanager_extras;

    public FileManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        filemanager_command = global_settings.get_item_string("Session", "file_manager", "command");
        filemanager_session = global_settings.get_item_string("Session", "file_manager", "session");
        filemanager_extras = global_settings.get_item_string("Session", "file_manager", "extras");

        switch (filemanager_command) 
        {
            case "pcmanfm":
                this.name = filemanager_command;
                if (filemanager_session != null)
                {
                    string create_command = "pcmanfm --profile " + filemanager_session + filemanager_extras;
                    this.command = create_command.split_set(" ",0);
                }
                else
                {
                    this.command = {filemanager_command};
                }
                break;
            case "pcmanfm-qt":
                this.name = filemanager_command;
                if (filemanager_session != null)
                {
                    string create_command = "pcmanfm-qt --profile " + filemanager_session + filemanager_extras;
                    this.command = create_command.split_set(" ",0);
                }
                else
                {
                    this.command = {filemanager_command};
                }
                break;
            case "nautilus":
                this.name = filemanager_command;
                string create_command = "nautilus" + " -n " + filemanager_extras;
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = filemanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class DesktopApp: SimpleAppObject
{
    string desktop_command;
    string desktop_wallpaper;

    public DesktopApp ()
    {
        init();
    }

    public override void read_settings()
    {

        desktop_command = global_settings.get_item_string("Session", "desktop_manager", "command");
        desktop_wallpaper = global_settings.get_item_string("Session", "desktop_manager", "wallpaper");   

        switch (desktop_command) 
        {
            case "filemanager":
                string filemanager_session = global_settings.get_item_string("Session", "file_manager", "session");
                string filemanager_extras = global_settings.get_item_string("Session", "file_manager", "extras");

                if (global_file_manager != null)
                {
                    message("File manager needed for desktop manager but doesn't exist, creating it");
                    var filemanager = new FileManagerApp();
                    global_file_manager = filemanager;
                }

                switch (global_settings.get_item_string("Session", "file_manager", "command"))
                {
                    case "pcmanfm":
                        this.name = global_settings.get_item_string("Session", "file_manager", "command");
                        string create_command = "pcmanfm --desktop --profile " + filemanager_session + filemanager_extras;
                        this.command = create_command.split_set(" ",0);
                        break;
                    case "pcmanfm-qt":
                        this.name = global_settings.get_item_string("Session", "file_manager", "command");
                        string create_command = "pcmanfm-qt --desktop --profile " + filemanager_session + filemanager_extras;
                        this.command = create_command.split_set(" ",0);
                        break;
                    case "nautilus":
                        this.name = global_settings.get_item_string("Session", "file_manager", "command");
                        string create_command = "nautilus" + " -n " + filemanager_extras;
                        this.command = create_command.split_set(" ",0);
                        break;
                }
                break;
            case "feh":
                this.name = desktop_command;
                string create_command = "feh" + " --bg-scale " + desktop_wallpaper;
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = desktop_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
        this.guard = true;
    }

    public void launch_settings()
    {
        string[] backup_command = this.command;

        switch (this.name)
        {
            case "pcmanfm":
                string create_settings_command = "pcmanfm --desktop-pref";
                this.command = create_settings_command.split_set(" ",0);
                break;

            default:
                break;
        }
        this.launch();
        this.command = backup_command;
    }

}

public class PolkitApp: SimpleAppObject
{
    string polkit_command;

    public PolkitApp ()
    {
        init();
    }

    public override void read_settings()
    {
        polkit_command = global_settings.get_item_string("Session", "polkit", "command");

        switch (polkit_command) 
        {
            case "gnome":
                this.name = "polkit-gnome-authentication-agent-1";
                string create_command = "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1";
                this.command = create_command.split_set(" ",0);
                break;
            case "razorqt":
                this.name = "razor-policykit-agent";
                string create_command = "/usr/bin/razor-policykit-agent";
                this.command = create_command.split_set(" ",0);
                break;
            case "lxpolkit":
                message("polkit separate");
                this.name = "lxpolkit";
                string create_command = "lxpolkit";
                this.command = create_command.split_set(" ",0);
                break;
        }
        this.guard = true;

    }

#if BUILDIN_POLKIT
    public new void launch ()
    {
        policykit_agent_init();
    }
#endif

    public void deactivate ()
    {
#if BUILDIN_POLKIT
        policykit_agent_finalize();
#endif
    }
}

public class NetworkGuiApp: SimpleAppObject
{
    string network_command;
    string laptop_mode;

    public NetworkGuiApp ()
    {
        init();
    }

    public override void read_settings()
    {
        network_command = global_settings.get_item_string("Session", "network_gui", "command");
        laptop_mode = global_settings.get_item_string("State", "laptop_mode", null);

        switch (network_command)
        {
            case "no":
                /* Don't start anything */
                break;
            case "auto":
                /* If we are on a laptop, assume we need a GUI, and try to find one, starting with nm-applet */
                /* If you are not on a laptop, assume we don't need any GUI */
                if (laptop_mode == "yes")
                {
                    string test_nm_applet = Environment.find_program_in_path("nm-applet");
                     if (test_nm_applet != null)
                     {
                         this.name = "nm-applet";
                         string create_command = "nm-applet";
                         this.command = create_command.split_set(" ",0);
                         break;
                     }
                     else
                     {
                        string test_wicd = Environment.find_program_in_path("wicd");
                        if (test_wicd != null)
                        {
                            this.name = "wicd";
                            string create_command = "wicd";
                            this.command = create_command.split_set(" ",0);
                            break;
                        }
                    }
                }
                 break;
            default:
                string[] create_command = network_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
        this.guard = true;
    }
}

public class AudioManagerApp: SimpleAppObject
{
    string audiomanager_command;

    public AudioManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        audiomanager_command = global_settings.get_item_string("Session", "audio_manager", "command");

        switch (audiomanager_command)
        {
            case "alsamixer":
                this.name = "alsamixer";
                string create_command = "xterm -e alsamixer";
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = audiomanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class QuitManagerApp: SimpleAppObject
{
    string quitmanager_command;
    string quitmanager_image;
    string quitmanager_layout;


    public QuitManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        quitmanager_command = global_settings.get_item_string("Session", "quit_manager", "command");
        quitmanager_image = global_settings.get_item_string("Session", "quit_manager", "image");
        quitmanager_layout = global_settings.get_item_string("Session", "quit_manager", "layout");

        switch (quitmanager_command)
        {
            case "lxsession-logout":
                this.name = "lxsession-logout";
                string create_command = "lxsession-logout --banner " + quitmanager_image + " --side=" + quitmanager_layout;
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = quitmanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class WorkspaceManagerApp: SimpleAppObject
{
    string workspacemanager_command;

    public WorkspaceManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        workspacemanager_command = global_settings.get_item_string("Session", "workspace_manager", "command");

        switch (workspacemanager_command)
        {
            case "obconf":
                this.name = "obconf";
                string create_command = "obconf --tab 6";
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = workspacemanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class LauncherManagerApp: SimpleAppObject
{
    string launchermanager_command;

    public LauncherManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        launchermanager_command = global_settings.get_item_string("Session", "launcher_manager", "command");

        switch (launchermanager_command)
        {
            case "lxpanelctl":
                this.name = "lxpanelctl";
                string create_command = "lxpanelctl run";
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = launchermanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }

    public void autostart_launch()
    {
        switch (launchermanager_command)
        {
            case "synapse":
                string create_autostart_command = "synapse --startup";
                lxsession_spawn_command_line_async(create_autostart_command);
                break;
            default:
                this.launch();
                break;
        }
    }
}

public class TerminalManagerApp: SimpleAppObject
{
    string terminalmanager_command;

    public TerminalManagerApp ()
    {
        init();
    }

    public override void read_config_settings()
    {
        terminalmanager_command = global_settings.get_item_string("Session", "terminal_manager", "command");
    }

    public override void read_settings()
    {
        switch (terminalmanager_command)
        {
            case "lxterminal":
                this.name = "lxterminal";
                string create_command = "lxterminal -e";
                this.command = create_command.split_set(" ",0);
                break;
            default:
                string[] create_command = terminalmanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }

    public new void launch (string argument)
    {
        if (argument == "")
        {
            argument = null;
        }

        generic_launch (argument);
    }
}

public class ProxyManagerApp: SimpleAppObject
{
    string proxymanager_command;
    string proxymanager_http;

    public ProxyManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        proxymanager_command = global_settings.get_item_string("Session", "proxy_manager", "command");
        proxymanager_http = global_settings.get_item_string("Session", "proxy_manager", "http");

        switch (proxymanager_command)
        {
            case "build-in":
                switch (proxymanager_http)
                {
                    case null:
                        break;
                    case "":
                        break;
                    case " ":
                        break;
                    default:
                    Environment.set_variable("HTTP_PROXY", proxymanager_http, true);
                    break;
                }
                break;
        }
    }
}

public class A11yApp: SimpleAppObject
{
    string a11y_command;

    public A11yApp ()
    {
        init();
    }

    public override void read_settings()
    {
        a11y_command = global_settings.get_item_string("Session", "a11y", "command");

        switch (a11y_command)
        {
            case null:
                break;
            case "":
                break;
            case " ":
                break;
            case "gnome":
                string tmp_command = "/usr/lib/at-spi2-core/at-spi-bus-launcher --launch-immediately";
                string[] create_command = tmp_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
            default:
                string[] create_command = a11y_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class XrandrApp: SimpleAppObject
{
    /*  Don't use GenericApp, we may want to implement other option than
        reading a xrandr command directly
    */
    string xrandr_command;

    public XrandrApp ()
    {
        init();
    }

    public override void read_settings()
    {
        xrandr_command = global_settings.get_item_string("Session", "xrandr", "command");

        switch (xrandr_command)
        {
            case null:
                break;
            case "":
                break;
            case " ":
                break;
            default:
                string[] create_command = xrandr_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class KeyringApp: SimpleAppObject
{
    string keyring_command;
    string keyring_type;

    public KeyringApp ()
    {
        init();
    }

    public override void read_settings()
    {
        keyring_command = global_settings.get_item_string("Session", "keyring", "command");
        keyring_type = global_settings.get_item_string("Session", "keyring", "type");

        switch (keyring_command)
        {
            case "gnome-all":
                string tmp_command = "gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg";
                string[] create_command = tmp_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
            case "ssh-agent":
                string tmp_command = "/usr/bin/ssh-agent -s";
                string[] create_command = tmp_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
            default:
                string[] create_command = keyring_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class ScreenshotManagerApp: SimpleAppObject
{
    string screenshotmanager_command;

    public ScreenshotManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        screenshotmanager_command = global_settings.get_item_string("Session", "screenshot_manager", "command");

        switch (screenshotmanager_command)
        {
            default:
                string[] create_command = screenshotmanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }

    public void window_launch()
    {
        read_settings();

        string[] backup_command = this.command;

        switch (screenshotmanager_command)
        {
            case "scrot":
                string create_window_command = "scrot -u -b";
                this.command = create_window_command.split_set(" ",0);
                break;

            default:
                break;
        }

        this.launch();
        this.command = backup_command;
    }
}

public class UpdatesManagerApp: SimpleAppObject
{
    string updatesmanager_command;

    IconObject updates_icon;
    MenuObject icon_menu;

    IconObject language_icon;

    IconObject reboot_icon;

    string apt_update_path = "/var/lib/apt/periodic/update-success-stamp";
    GLib.File apt_update_file ;
    GLib.FileMonitor apt_update_monitor ;

    string dpkg_update_path = "/var/lib/dpkg/status";
    GLib.File dpkg_update_file ;
    GLib.FileMonitor dpkg_update_monitor ;

    string dpkg_run_path = "/var/lib/update-notifier/dpkg-run-stamp";
    GLib.File dpkg_run_file ;
    GLib.FileMonitor dpkg_run_monitor ;

    string apt_lists_update_path = "/var/lib/apt/lists";
    GLib.File apt_lists_update_file ;
    GLib.FileMonitor apt_lists_update_monitor ;

    string reboot_path = "/var/run/reboot-required";
    GLib.File reboot_file ;
    GLib.FileMonitor reboot_monitor ;

    string dpkg_lock_file = "/var/lib/dpkg/lock";

    int lock_check = 0;

    public UpdatesManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        updatesmanager_command = global_settings.get_item_string("Session", "updates_manager", "command");

        switch (updatesmanager_command)
        {
            case null:
                break;
            case "":
                break;
            case " ":
                break;
            case "update-notifier-clone":
                setup_apt_config();
                setup_reboot_config();
                run_check();
                break;
            default:
                string[] create_command = updatesmanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }

    public void test_inactivate()
    {
        updates_icon.inactivate();
    }

    public void test_activate()
    {
        updates_icon.activate();
    }

    public void run_check()
    {
        if (this.lock_check == 0)
        {
            if (check_lock_file(dpkg_lock_file) == true)
            {
                this.lock_check = 1;
                int timeout = 60;
                if (global_settings.get_item_string("Session", "updates_manager", "timeout") != null)
                {
                    timeout = int.parse(global_settings.get_item_string("Session", "updates_manager", "timeout"));
                }
                GLib.Timeout.add_seconds(timeout, on_apt_update_file_change);
            }
        }
    }

    public void reboot_launch()
    {
        var session = new SessionObject();
        session.lxsession_restart();
    }

    public void run_check_reboot()
    {
        string notification_text ="";

        if (this.reboot_file.query_exists ())
        {
            if (this.reboot_icon == null)
            {
                var reboot_icon_menu = new MenuObject() ;
                string line = _("Reboot required");

                try
                {
                    var dis = new DataInputStream (this.reboot_file.read ());
                    line = dis.read_line ();
                }
                catch (GLib.Error e)
                {
                    message ("Error: %s\n", e.message);
                }

                if (line != null)
                {
                    notification_text = line;
                }

                var menu_item = new MenuItemObject();
                menu_item.set_label(notification_text);
                menu_item.activate.connect(() => {
                    reboot_launch();
                });
                menu_item.show();
                reboot_icon_menu.add(menu_item);

                this.reboot_icon = new IconObject("RebootIcon", "system-reboot", notification_text, reboot_icon_menu);
                this.reboot_icon.init();
                this.reboot_icon.clear_actions ();
                this.reboot_icon.add_action ("launch_reboot", _("Reboot"), () =>
                {
                    reboot_launch();
                });
                this.reboot_icon.activate();
            }
        }
        else
        {
            if (this.reboot_icon != null)
            {
                this.reboot_icon.inactivate();
            }
        }
    }

    public void language_launch()
    {
        if (this.language_icon != null)
        {
            try
            {
                Process.spawn_command_line_async("gnome-language-selector");
                this.language_icon.inactivate();
            }
            catch (SpawnError err)
            {
                warning (err.message);
            }
        }
    }

    public void check_language_support()
    {
        string command = "check-language-support";

        string standard_output;
        string standard_error;
        int exit_status;

        string launch_string = _("Launch language support");

        try
        {
            Process.spawn_command_line_sync (command, out standard_output, out standard_error, out exit_status);

            message ("Launching %s", command);
            message ("Language state: %s", standard_error);
            message ("Language exit status: %i", exit_status);
            message ("Language output: %s", standard_output);

        }
        catch (SpawnError err)
        {
            warning (err.message);
        }

        if (standard_output != null)
        {
            if (standard_output.length >= 3)
            {
                if (this.language_icon == null)
                {
                    var language_icon_menu = new MenuObject() ;

                    var menu_item = new MenuItemObject();
                    menu_item.set_label(launch_string);
                    menu_item.activate.connect(() => {
                        language_launch();
                    });
                    menu_item.show();
                    language_icon_menu.add(menu_item);

                    this.language_icon = new IconObject("LanguageIcon", "preferences-desktop-locale", _("Language support missing"), language_icon_menu);
                    this.language_icon.init();
                    this.language_icon.clear_actions ();
                    this.language_icon.add_action ("launch_language_support", launch_string, () =>
                    {
                        language_launch();
                    });
                    this.language_icon.activate();
                }
            }
            else if (this.language_icon != null)
                {
                    this.language_icon.inactivate();
                }
        }
        else if (this.language_icon != null)
            {
                this.language_icon.inactivate();
            }
    }

    public void upgrade_launch (string upgrade_manager_command)
    {
        try
        {
            Process.spawn_command_line_async(upgrade_manager_command);
        }
        catch (SpawnError err)
        {
            warning (err.message);
        }
    }

    public bool on_apt_update_file_change()
    {
        /* Launch something that check if updates are available */
        /* For now, use lxsession-apt-check, which is apt-check from update-notifier */

        string standard_output;
        string standard_error;
        int exit_status;

        string notification_text = _("Updates available");

        string launch_string = _("Launch Update Manager");
        string upgrade_manager_command = "";

        string[] updates_num;
        int updates_urgent = 0;
        int updates_normal = 0;
        int updates_state = 0;
        int number_updates = 0;

        /* Lock the check process, to avoid launching the check many times when one is already running */
        this.lock_check = 1;

        if (this.icon_menu == null)
        {
            this.icon_menu = new MenuObject();

            if (global_settings.get_item_string("Session", "upgrade_manager", "command") != null)
            {
                upgrade_manager_command = global_settings.get_item_string("Session", "upgrade_manager", "command");

                var menu_item = new MenuItemObject();
                menu_item.set_label(launch_string);
                menu_item.activate.connect(() => {
                    upgrade_launch (upgrade_manager_command);
                });
                menu_item.show();
                icon_menu.add(menu_item);
            }
        }

        string command = "/usr/bin/nice" + " " + "/usr/bin/ionice" + " " + "-c3" + " " + "/usr/lib/update-notifier/apt-check";

        string error_string = "";

        try
        {
            Process.spawn_command_line_sync (command, out standard_output, out standard_error, out exit_status);

            message ("Launching %s", command);
            message ("Update state: %s", standard_error);
            message ("Update exit status: %i", exit_status);

        }
        catch (SpawnError err)
        {
            warning (err.message);
        }

        if (this.updates_icon == null)
        {
            this.updates_icon = new IconObject("UpdatesIcon", "software-update-available", notification_text, this.icon_menu);
            this.updates_icon.init();
            if (global_settings.get_item_string("Session", "upgrade_manager", "command") != null)
            {
                upgrade_manager_command = global_settings.get_item_string("Session", "upgrade_manager", "command");
                this.updates_icon.clear_actions ();
                this.updates_icon.add_action ("launch_upgrade_manager", launch_string, () =>
                {
                    upgrade_launch (upgrade_manager_command);
                });
            }
            this.updates_icon.inactivate();
        }
        else
        {
            this.updates_icon.inactivate();
        }

        if (standard_error != "")
        {
            if (standard_error[0:1] == "E")
            {
                updates_urgent = 0;
                updates_normal = 0;
                updates_state = 1;
                error_string =   _("An error occurred, please run Package Manager from the left-click menu or apt-get in a terminal to see what is wrong.");
                if (standard_error.length > 3)
                {
                    notification_text = error_string + "\n" + _("The error message was: ") + standard_error;
                }
                else
                {
                    notification_text = error_string;
                }
            }
            else
                {
                    updates_num = standard_error.split_set(";",2);
                    message ("Number of upgrades: %s", updates_num[0]);
                    message ("Number of security upgrades: %s", updates_num[1]);
                    updates_num[2] = "0";

                    updates_urgent = int.parse(updates_num[1]);
                    updates_normal = int.parse(updates_num[0]);
                    number_updates = updates_normal + updates_urgent;

                    if (number_updates == 1)
                    {
                        notification_text = number_updates.to_string() + _(" Update available");
                    }
                    else if (number_updates > 1)
                        {
                            notification_text = number_updates.to_string() + (" ") + _("Updates available");
                        }
                }

        }
        else
        {
            updates_state = 1;
        }


        if (number_updates > 0)
        {
            message("Activate icon because of updates available");
            this.updates_icon.set_notification_body(notification_text);
            this.updates_icon.activate();
        }

        if (updates_urgent > 0)
        {
            message("Set urgent icon");
            this.updates_icon.set_icon("software-update-urgent");
            this.updates_icon.set_notification_body(notification_text);
        }


        if (updates_state > 0)
        {
            message("Problem in package state");
            this.updates_icon.set_icon("software-update-urgent");
            this.updates_icon.set_notification_body(notification_text);
            this.updates_icon.clear_actions ();
            this.updates_icon.add_action ("launch_upgrade_manager", launch_string, () =>
            {
                upgrade_launch ("synaptic-pkexec");
            });
            var new_menu = new MenuObject();
            var new_menu_item = new MenuItemObject();
            new_menu_item.set_label(launch_string);
            new_menu_item.activate.connect(() => {
                upgrade_launch ("synaptic-pkexec");
            });
            new_menu_item.show();
            new_menu.add(new_menu_item);
            this.updates_icon.set_menu(new_menu);
            this.updates_icon.activate();
        }

        /* Check if language support is complete */
        check_language_support();

        /* Check if a reboot is requiered */
        run_check_reboot();

        /* Unlock the check */
        this.lock_check = 0;

        return false;
    }

    public void setup_apt_config ()
    {
        /* Note directories monitored by update-notifier :
                "/var/lib/apt/lists/" ==> files of meta data of the repositories
                "/var/lib/apt/lists/partial/"
                "/var/cache/apt/archives/" ==> .deb in cache
                "/var/cache/apt/archives/partial/"

            Files monitored by update-notifier :
              "/var/lib/dpkg/status" => big file of dpkg status
              "/var/lib/update-notifier/dpkg-run-stamp" update-notifier stamp for dpkg ?
              "/var/lib/apt/periodic/update-success-stamp" 
        */

        try
        {
            this.apt_update_file = File.new_for_path(this.apt_update_path);
            this.apt_update_monitor = apt_update_file.monitor_file(GLib.FileMonitorFlags.NONE);
            this.apt_update_monitor.changed.connect(run_check);
            message ("Monitoring apt changes");
        }
        catch (GLib.Error err)
        {
            message (err.message);
        }

        try
        {
            this.dpkg_update_file = File.new_for_path(this.dpkg_update_path);
            this.dpkg_update_monitor = dpkg_update_file.monitor_file(GLib.FileMonitorFlags.NONE);
            this.dpkg_update_monitor.changed.connect(run_check);
            message ("Monitoring dpkg changes");
        }
        catch (GLib.Error err)
        {
            message (err.message);
        }

        try
        {
            this.dpkg_run_file = File.new_for_path(this.dpkg_run_path);
            this.dpkg_run_monitor = dpkg_run_file.monitor_file(GLib.FileMonitorFlags.NONE);
            this.dpkg_run_monitor.changed.connect(run_check);
            message ("Monitoring dpkg run changes");
        }
        catch (GLib.Error err)
        {
            message (err.message);
        }

        try
        {
            this.apt_lists_update_file = File.new_for_path(this.apt_lists_update_path);
            this.apt_lists_update_monitor = apt_lists_update_file.monitor_directory(GLib.FileMonitorFlags.NONE);
            this.apt_lists_update_monitor.changed.connect(run_check);
            message ("Monitoring apt_lists changes");
        }
        catch (GLib.Error err)
        {
            message (err.message);
        }
    }

    public void setup_reboot_config ()
    {
        try
        {
            this.reboot_file = File.new_for_path(this.reboot_path);
            this.reboot_monitor = reboot_file.monitor_file(GLib.FileMonitorFlags.NONE);
            this.reboot_monitor.changed.connect(run_check_reboot);
            message ("Monitoring reboot changes");
        }
        catch (GLib.Error err)
        {
            message (err.message);
        }
    }

    /* From https://mail.gnome.org/archives/vala-list/2010-October/msg00036.html */
    public bool check_lock_file(string check_file)
    {
            
            string lock_file_name = check_file;
            int fd = Posix.open (lock_file_name, Posix.O_RDWR); 
            if (fd == -1)
            {
              print ("There was an error opening the file '"  
                + lock_file_name + " (Error number "  
                + Posix.errno.to_string() + ")\n");
              return true;
            }
                    
            // Try to get a lock
            Posix.Flock fl = Posix.Flock();
            fl.l_type = Posix.F_WRLCK;
            fl.l_whence = Posix.SEEK_SET;
            fl.l_start = 100;
            fl.l_len = 0;
                    
            int fcntl_return = Posix.fcntl (fd, Posix.F_SETLK, fl);
            if (fcntl_return == -1) 
                    return true;
                    
            // Release the lock again
            fl.l_type = Posix.F_UNLCK;
            fl.l_whence = Posix.SEEK_SET;
            fl.l_start = 100;
            fl.l_len = 0;
            fcntl_return = Posix.fcntl (fd, Posix.F_SETLK, fl);

            return false;
    }

}
public class CrashManagerApp: SimpleAppObject
{
    string crash_manager_command;
    IconObject crash_icon;

    string crash_dir_path = "/var/crash/";
    GLib.File crash_dir_file ;
    GLib.FileMonitor crash_dir_monitor ;

    int lock_crash_check = 0;

    public CrashManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        crash_manager_command = global_settings.get_item_string("Session", "crash_manager", "command");

        switch (crash_manager_command)
        {
            case null:
                break;
            case "":
                break;
            case " ":
                break;
            case "apport-gtk":
                setup_crash_log_config ();
                run_crash_check();
                break;
            default:
                string[] create_command = crash_manager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }

    public void test_activate ()
    {
        if (this.crash_icon != null)
        {
            this.crash_icon.activate();
        }
    }

    public void test_inactivate ()
    {
        if (this.crash_icon != null)
        {
            this.crash_icon.inactivate();
        }
    }

    public void setup_crash_log_config ()
    {
        try
        {
            this.crash_dir_file = File.new_for_path(this.crash_dir_path);
            this.crash_dir_monitor = crash_dir_file.monitor_directory(GLib.FileMonitorFlags.NONE);
            this.crash_dir_monitor.changed.connect(run_crash_check);
            message ("Monitoring crash dir changes");
        }
        catch (GLib.Error err)
        {
            message (err.message);
        }
    }

    public void run_crash_check()
    {
        if (this.lock_crash_check == 0)
        {
            this.lock_crash_check = 1;
            int timeout = 60;
            if (global_settings.get_item_string("Session", "crash_manager", "timeout") != null)
            {
                timeout = int.parse(global_settings.get_item_string("Session", "crash_manager", "timeout"));
            }
            GLib.Timeout.add_seconds(timeout, on_crash_file_change);
        }
    }

    public List<string> check_crash_file()
    {
        List<string> crash_list = new List<string> ();
        List<string> final_crash_list = new List<string> ();
        string[] uploaded_list = {};
        string file_name;

        if (this.crash_dir_file != null)
        {
            try
            {
                var directory = File.new_for_path (crash_dir_path);
                var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

                FileInfo file_info;
                while ((file_info = enumerator.next_file ()) != null)
                {
                    file_name = file_info.get_name();
                    if (file_name != ".lock")
                    {
                        if (file_name.has_suffix(".crash"))
                        {
                            message("Add to crash_list: %s", file_name);
                            crash_list.append(file_name);
                        }
                        else if (file_name.has_suffix(".uploaded"))
                        {
                            uploaded_list += file_name.replace(".uploaded", ".crash");
                            message("Added to upload_list: %s", file_name.replace(".uploaded", ".crash"));
                        }
                    }
                }
            }
            catch (Error e)
            {
                message ("Error: %s\n", e.message);
            }
        }

        foreach (string element in crash_list)
        {
            message("Check element in crash_list: %s", element);
            if (uploaded_list != null)
            {
                if (element in uploaded_list)   
                {
                    message("Remove element in crash_list: %s", element);
                }
                else
                {
                    final_crash_list.append(element);
                }
            }
            else
            {
                final_crash_list.append(element);
            }
        }

        return final_crash_list;
    }

    public void crash_report_launch (string command)
    {
        try
        {
            Process.spawn_command_line_async(command);
            message ("Launching crash command : %s", command);
        }
        catch (SpawnError err)
        {
            warning (err.message);
        }
    }

    public MenuObject build_menu(List<string> crash_list)
    {
        uint len = crash_list.length();
        var menu = new MenuObject();

        if (len >= 1)
        {
            foreach (string element in crash_list)
            {
                string command = "/usr/bin/pkexec /usr/share/apport/apport-gtk" + " " + this.crash_dir_path + element;

                var menu_item = new MenuItemObject();
                menu_item.set_label(_("Report ") + element);
                menu_item.activate.connect(() => {
                        crash_report_launch(command);
                });
                menu_item.show();
                menu.add(menu_item);
            }
        }

        return menu;

    }

    public bool on_crash_file_change ()
    {
        List<string> crash_list;
        uint len;
        MenuObject crash_menu;

        /* Lock the check process, to avoid launching the check many times when one is already running */
        this.lock_crash_check = 1;

        crash_list = check_crash_file();
        len = crash_list.length();
        uint last_item = len - 1;

        if (len >= 1)
        {
            crash_menu = build_menu(crash_list);
            string command =  "/usr/bin/pkexec /usr/share/apport/apport-gtk" + " " + this.crash_dir_path + crash_list.nth_data(last_item) ;
            string remove_command = "/usr/bin/pkexec rm -f " + this.crash_dir_path + crash_list.nth_data(last_item);

            string launch_string = "Report last crash";
            string remove_string = "Remove last crash";

            if (this.crash_icon == null)
            { 
                this.crash_icon = new IconObject("CrashIcon", "apport", _("Crash files available for report"), crash_menu);
                this.crash_icon.init();
            }
            this.crash_icon.set_menu(crash_menu);
            /* TODO Make a window dialog to be able to really report bug on notification screen (and also add the remove mode)

            this.crash_icon.clear_actions ();
            this.crash_icon.add_action ("launch_crash_report", launch_string, () =>
            {
                crash_report_launch (command);
            });
            */
            if (global_settings.get_item_string("Session", "crash_manager", "dev_mode") == "yes")
            {
                this.crash_icon.add_action ("remove_crash_report", remove_string, () =>
                {
                    crash_report_launch (remove_command);
                });
            }
            this.crash_icon.activate();
        }
        /* Unlock the check */
        this.lock_crash_check = 0;
        return false;
    }
}
}
