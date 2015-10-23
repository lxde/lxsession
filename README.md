# LXSession #

The default LXDE session manager.

Full documentation on http://wiki.lxde.org/en/index.php?title=LXSession

## What's LXSession and who needs this? ##

A session manager is used to automatically start a set of applications and
set up a working desktop environment.
Besides, LXSession has a built-in lightweight Xsettings daemon, which can 
configure gtk+ themes, keyboard, and mouse for you on session startup.
In gnome the Xsettings part is provided by gnome-settings-daemon.

Gnome is bundled with its own gnome-session, KDE brings its own session
manager, too. XFCE and ROX desktop also have their own session managers,
xfce4-session and rox-session.

LXSession can start a set of programs specified by the distribution
makers or users. Furthermore, LXSession is more advanced than
some of the other ones because it can "guard" the specified
programs, and get them restarted if crashes happened.

Besides, the major difference between LXSession and the preceding programs
is that LXSession is lightweight, and it's not tighted to "any" desktop environment.
It's desktop-independent and can be used with any window manager.
With proper configuration, you can make your own desktop environment with
LXSession. This is very useful to the users and developers of non-mainstream
window managers and desktop environments.

Here we use our own desktop environment LXDE as a working example
to tell you, step by step, how to create your own new desktop environment.

Create a startup script for your desktop, and put it to /usr/bin.
For example, we create a script ``/usr/bin/startlxde``.

Then, add the commands you want to execute *before* LXSession,
such as setting up locales or others, and put "exec lxsession" in the last line.

For example, our startlxde script looks like this:

```sh
#!/bin/sh
exec /usr/bin/lxsession -s LXDE -e LXDE
```

Apparently, LXDE is the name of our desktop.
Replace it with the name of your desktop.

Then, make a desktop entry file for it under '/usr/share/xsessions'.
With this, you can select this desktop session from menu in GDM.
For example, this is the content of our LXDE.desktop:

```ini
[Desktop Entry]
Encoding=UTF-8
Name=LXDE
Comment=LXDE - Lightweight X11 desktop environment
Exec=/usr/bin/startlxde
Type=Application
```

Apparently, you can replace the name and description with your own.
Exec should points to the startup script created in previous step.

Now you get an item 'LXDE' in the list of available sessions in gdm.
NOTE: Restart of gdm might be needed. ( On Debian:  sudo /etc/init.d/gdm restart )


## Compilation flags ##
* "--enable-man" : Generate man pages
* "--enable-more-warnings" : Enable more compilation warning at build time
* "--enable-gtk3" : Compile with GTK3 when the component is compatible (incomplete)
* "--enable-buildin-clipboard" : Add a build-in support for clipboard functionalities, using GTK2
* "--enable-buildin-polkit" : Add a build-in support for a polkit agent (based on GTK)
* "--enable-debug" : Enable more debug
* "--enable-gtk" : Enable GTK+ programs and compilation. Pass --disable-gtk to build without any GTK+ component (useful if you want lxsession on a Qt environnement).

## Runtime arguments ##
* --session or -s : Specify the session name (use for configuration, settings, log files ...). Default to LXDE
* --de or -e : Specify the desktop environment name to use for desktop files (such as LXDE, GNOME, or XFCE).
* --reload or -r : Reload configurations (for Xsettings daemon).
* --noxsettings or -n : Disable Xsettings daemon support.
* --noautostart or -a : Disable the autostart of applications (window-manager mode only)
* --compatibility or -c : Specify a compatibility mode for settings (only razor-qt supported)

## Configuration files ##
The config files of LXSession are stored in
'''~/.config/lxsession/''<Profile Name>'''''

If the config files are missing, LXSession loads system-wide config in '''/etc/xdg/lxsession/''<Profile name>''''' instead.

Note: If no <code>-session</code> has been passed on the command line to lxsession, the default profile name is LXDE.

## Dbus interface ##
All settings are available via Dbus, using the Dbus interface org.lxde.SessionManager /org/lxde/SessionManager org.lxde.SessionManager
There are several group of methods, which reflect the groups of the keyfile. All settings have 2 keys (key1/key2), the first one (level1) is the main one, the second one (level2) is linked to the first one and can be empty, depending of the settings.
Example : composite_manager/command is the settings which contains the name of the executable to launch the composite manager. composite_manager/autostart is the one to manager the autostart of composite_manager

To retrieve all the settings, use the ***Support method, which retrieve the list of available options. To have the details of level2 settings available for a level1 setting, use ***SupportDetail method.

Type available for methods :
* Session
* Dbus
* Environment
* Keymap
* Proxy
* Security
* State
* Updates
* XRandr
* Xsettings
* a11y

Methods available for all type (replace *** by the type you want (such as Session, Dbus ...) :
* ***Get (key1, key2) : Retrieve the setting for key1/key2
* ***Set (key1, key2, value_to_set): Save the setting for key1/key2
* ***Support () : List all the options available
* ***SupportDetail (lvl1) : List all the level2 options for level1 setting lvl1.
* ***Activate () : Launch the option (available for all type of method except Session)

Special methods:
* SessionLaunch (command) : Launch the application (command is the key1 setting of the application to launch)

Session Manager methods:
* CanShutdown
* Logout
* RequestReboot
* RequestShutdown
* Shutdown
* ReloadSettingsDaemon

## Options and settings ##
All options are available on the desktop.conf.example : http://lxde.git.sourceforge.net/git/gitweb.cgi?p=lxde/lxsession;a=blob;f=data/desktop.conf.example;hb=HEAD

## Custom configuration files ##
You can use custom configuration files for some applications. LXsession will automatically copy them on the right place to be used by the applications. The configuration of those files are done in conffiles.conf, in /etc/xdg/lxsession/<profile>/ or ~/.config/lxsession/<profile>/.

## Applications and binaries ##
* lxclipboard : Application to enable a clipboard support, using GTK.
* lxlock : Application to lock the screen, using external applications
* lxpolkit : Polkit agent
* lxsession-default : Wrapper around Dbus method to launch applications defined in lxsession configuration file.
* lxsession-default-apps : Configuration application for lxsession (mostly for debugging purposes).
* lxsession-edit : Old configuration application for lxsession
* lxsession-utils : Misc utilities for lxsession
* lxsettings-daemon : Xsettings daemon

## Autostarted applications using lxsession ##
Lxsession manages the application which are started on login. It's handle by several elements

### Settings ###
You can enable, disable partly, or disable completely autostared application using the settings "disable_autostart", with different value :
* all : disable all applications (home, system, specify in this config file)
* config-only : disable applications from home and system (start only the ones in the desktop.conf config file)
* no : autostart all applications

Using "all" and "config-only" will disable autostared applications from the 2 above methods.

### autostart configuration file ###
This file stores the commands that will be executed at the beginning of the session.
It is not a shell script, but each line represents a different command to be executed.
If a line begins with @, the command following the @ will be automatically re-executed if
it crashes. Lines beginning with # are comments.

Commands globally executed are stored in the /etc/xdg/lxsession/<profile>/autostart file, and
in addition, other commands can be locally specified in the ~/.config/lxsession/<profile>/autostart
file. If both files are present, only the entries in the local file will be executed.

Exactly how autostart files are parsed, as of LXSession 0.4.9.2, is given by the following code in <code>autostart.vala</code>:

<pre>while ((line = dis.read_line (null)) != null)
{
    string first = line[0:1];

    switch (first)
    {
        case ("@"):
            var builder = new StringBuilder ();
            builder.append(line);
            builder.erase(0,1);
            string[] command = builder.str.split_set(" ",0);
            AppType app = { command[0], command, true, "" };
            app_list.add (app);
            break;
        case ("#"):
            /* Commented, skip */
            break;
        default:
            string[] command = line.split_set(" ",0);
            AppType app = { command[0], command, false, "" };
            app_list.add (app);
            break;
    }
 }</pre>

Notice that lines are split on space characters, but no form of escaping or quoting is supported, nor are multi-line commands. So if you need, e.g., a command with a space in one of its arguments, put it in a shell script and invoke the shell script from the autostart file.

### autostart directories ###
LXSession supports [http://www.freedesktop.org/ freedesktop.org] [http://www.freedesktop.org/wiki/Specifications/autostart-spec Autostart spec]. Put *.desktop files of those applications in ~/.config/autostart, and they will get executed when the session starts.

'''Important note:'''

Some gnome applications have the "OnlyShowIn=GNOME" key in their *.desktop files. That key means 'only load this application in GNOME' and it prevents the application from being loaded in other desktop environments. Actually, most of those applications can work well under other desktops, but sometimes they claim they are GNOME-only.

If you cannot get an application automatically started and you already have a .desktop file for it in the autostart directory, then check the setting of the 'OnlyShowIn' key. Try commenting it out or removing the key.
If the application still works ok then it's not really GNOME-specific - file a bug report for that application to its author and packager. As an example, the NetworkManager Applet (nm-applet) has the setting "OnlyShowIn=Gnome", but it works fine in LXDE. To make it autostart, just comment out or delete "OnlyShowIn=Gnome" in your ~/.config/autostart/nm-applet.desktop. If you are using different desktop environments on different sessions, and wish to use NetworkManager in LXDE, XFCE and Gnome, but not in KDE, you might want to add "OnlyShowIn=Gnome;XFCE;LXDE;" and/or "NotShowIn=KDE;"

## Log out ##

Simply executing this command:
``lxsession-logout``

This will give you a good-looking logout dialog.
If gdm is installed, lxsession can do shutdown/reboot/suspend via gdm.
(These options are not available if gdm is not running.)

If you want to customize this logout box further, try this:
``lxsession-logout --prompt "Your custom message" --banner "Your logo" \
--side "left | top | right | bottom (The position of the logo)"``

We create a script ``/usr/bin/lxde-logout`` to do this:

```sh
#!/bin/sh
/usr/bin/lxsession-logout --banner "/usr/share/lxde/images/logout-banner.png" --side top
```

You can put this logout script in the menu of your window manager or desktop panel.
Then, you can logout via clicking from the menu.

Have fun!
