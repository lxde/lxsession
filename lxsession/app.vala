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
using Gee;
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

    public AppObject()
    {

    }

    public void launch ()
    {
        generic_launch (null);
    }

    public void generic_launch (string? arg1)
    {
        this.read_config_settings();
        this.read_settings();

        if (this.name != null)
        {
            if (this.name != "")
            {
                try
                {
                    Process.spawn_async (
                                 arg1,
                                 this.command,
                                 null,
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
                    message("Exit not normal, reload");
                    this.launch();
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
    string settings_command;

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
        if (global_settings.window_manager != null)
        {
            mode = "simple";
            wm_command = global_settings.window_manager;
            session = "";
            extras = "";
        }
        else
        {
            mode = "advanced";
            wm_command = global_settings.windows_manager_command;
            session = global_settings.windows_manager_session;
            extras = global_settings.windows_manager_extras;
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
                                session_command = "--config-file " + xdg_config_env + "/openbox/lxde-rc.xml";
                                break;
                            case "Lubuntu":
                                session_command = "--config-file " + xdg_config_env + "/openbox/lubuntu-rc.xml";
                                break;
                            default:
                                session_command = "";
                                break;
                        }
                        break;
                    case "openbox-custom":
                        switch (session)
                        {
                            default:
                                session_command = "--config-file " + session;
                                break;
                        }
                        break;
                    default:
                        session_command = "";
                        break;
                }
                    switch (extras)
                    {
                        case null:
                            create_command = wm_command + " " + session_command;
                            break;
                        case "":
                            create_command = wm_command + " " + session_command;
                            break;
                        case " ":
                            create_command = wm_command + " " + session_command;
                            break;
                        default:
                            create_command = wm_command + " " + session_command + " " + extras;
                            break;
                    }
                this.command = create_command.split_set(" ",0);
            }
        }
        this.guard = true;
    }

    private string find_window_manager()
    {

        var wm_list = new ArrayList<string> ();

        wm_list.add("openbox-lxde");
        wm_list.add("openbox-lubuntu");
        wm_list.add("openbox");
        wm_list.add("compiz");
        wm_list.add("kwin");
        wm_list.add("mutter");
        wm_list.add("fluxbox");
        wm_list.add("metacity");
        wm_list.add("xfwin");
        wm_list.add("matchbox");

        string return_value = "";

        foreach (string i in wm_list)
        {
            string test_wm = Environment.find_program_in_path(i);
            if ( test_wm != null)
            {
                message ("Finding %s",i);
                return_value = i;
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
            global_sig.update_window_manager("wm_safe");
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
                    message("Exit not normal, reload");
                    this.launch();
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
            try {
                Process.spawn_async (
                             null,
                             this.command,
                             null,
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
            catch (SpawnError err){
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
        panel_command = global_settings.panel_command;
        panel_session = global_settings.panel_session;
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
        panel_command = global_settings.dock_command;
        panel_session = global_settings.dock_session;
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
        screensaver_command = global_settings.screensaver_command;

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
        powermanager_command = global_settings.power_manager_command;
        laptop_mode = global_settings.laptop_mode;

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
        filemanager_command = global_settings.file_manager_command;
        filemanager_session = global_settings.file_manager_session;
        filemanager_extras = global_settings.file_manager_extras;

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

        desktop_command = global_settings.desktop_command;
        desktop_wallpaper = global_settings.desktop_wallpaper;   

        switch (desktop_command) 
        {
            case "filemanager":
                string filemanager_session = global_settings.file_manager_session;
                string filemanager_extras = global_settings.file_manager_extras;

                if (global_file_manager != null)
                {
                    message("File manager needed for desktop manager but doesn't exist, creating it");
                    var filemanager = new FileManagerApp();
                    global_file_manager = filemanager;
                }

                switch (global_settings.file_manager_command)
                {
                    case "pcmanfm":
                        this.name = global_settings.file_manager_command;
                        string create_command = "pcmanfm --desktop --profile " + filemanager_session + filemanager_extras;
                        this.command = create_command.split_set(" ",0);
                        break;
                    case "pcmanfm-qt":
                        this.name = global_settings.file_manager_command;
                        string create_command = "pcmanfm-qt --desktop --profile " + filemanager_session + filemanager_extras;
                        this.command = create_command.split_set(" ",0);
                        break;
                    case "nautilus":
                        this.name = global_settings.file_manager_command;
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
        polkit_command = global_settings.polkit_command;

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
#if BUILDIN_POLKIT
                policykit_agent_init();
#else
                this.name = "lxpolkit";
                string create_command = "lxpolkit";
                this.command = create_command.split_set(" ",0);
#endif
                break;
        }
        this.guard = true;

    }

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
        network_command = global_settings.network_gui_command;
        laptop_mode = global_settings.laptop_mode;

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
        audiomanager_command = global_settings.audio_manager_command;

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
        quitmanager_command = global_settings.quit_manager_command;
        quitmanager_image = global_settings.quit_manager_image;
        quitmanager_layout = global_settings.quit_manager_layout;

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
        workspacemanager_command = global_settings.workspace_manager_command;

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
        launchermanager_command = global_settings.launcher_manager_command;

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
                try
                {
                    Process.spawn_command_line_async(create_autostart_command);
                }
                catch (SpawnError err)
                {
                    warning (err.message);
                }
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
        terminalmanager_command = global_settings.terminal_manager_command;
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

public class CompositeManagerApp: SimpleAppObject
{
    string compositemanager_command;

    public CompositeManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        compositemanager_command = global_settings.composite_manager_command;

        switch (compositemanager_command)
        {
            default:
                string[] create_command = compositemanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class IMApp: SimpleAppObject
{
    public string im_command;

    public IMApp ()
    {
        init();
    }

    public override void read_settings()
    {
        switch (im_command)
        {
            default:
                string[] create_command = im_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class IM1App: IMApp
{
    public IM1App ()
    {
        init();
    }

    public override void read_config_settings()
    {
        im_command = global_settings.im1_command;
    }
}

public class IM2App: IMApp
{
    public IM2App ()
    {
        init();
    }

    public override void read_config_settings()
    {
        im_command = global_settings.im2_command;
    }
}

public class WidgetApp: SimpleAppObject
{
    public string widget_command;

    public WidgetApp ()
    {
        init();
    }

    public override void read_config_settings()
    {
        widget_command = global_settings.widget1_command;
    }

    public override void read_settings()
    {
        switch (widget_command)
        {
            default:
                string[] create_command = widget_command.split_set(" ",0);
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
        screenshotmanager_command = global_settings.screenshot_manager_command;

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
        string[] backup_command = this.command;

        switch (this.name)
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

public class LockManagerApp: SimpleAppObject
{
    string lockmanager_command;

    public LockManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        lockmanager_command = global_settings.lock_manager_command;

        switch (lockmanager_command)
        {
            default:
                string[] create_command = lockmanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

public class UpgradeManagerApp: SimpleAppObject
{
    string upgrademanager_command;

    public UpgradeManagerApp ()
    {
        init();
    }

    public override void read_settings()
    {
        upgrademanager_command = global_settings.upgrade_manager_command;

        switch (upgrademanager_command)
        {
            default:
                string[] create_command = upgrademanager_command.split_set(" ",0);
                this.name = create_command[0];
                this.command = create_command;
                break;
        }
    }
}

}
