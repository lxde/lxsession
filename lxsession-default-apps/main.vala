/* 
    Copyright 2012 Julien Lavergne <gilir@ubuntu.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using Posix;

const string GETTEXT_PACKAGE = "lxsession";

namespace LDefaultApps
{
    public class UpdateWindows : Gtk.Window
    {
        public Pid pid;
        public KeyFile kf;

	    public UpdateWindows ()
        {
	        this.title = _("Update lxsession database");
	        this.window_position = Gtk.WindowPosition.CENTER;
            try
            {
                this.icon = IconTheme.get_default ().load_icon ("preferences-desktop", 48, 0);
            }
            catch (Error e)
            {
                message ("Could not load application icon: %s\n", e.message);
            }
	        this.set_default_size (300, 70);

	        // Widget content:
	        this.add (new Gtk.Label (_("The database is updating, please wait")));

            kf = get_keyfile();
            update_database();
        }

        public void update_database()
        {
            try
            {
                string[] command = "lxsession-db -m write".split_set(" ",0); 
                Process.spawn_async (
                             null,
                             command,
                             null,
                             SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                             null,
                             out pid);
                ChildWatch.add(pid, callback_pid);
            }
            catch (SpawnError err)
            {
                warning ("Error updating the database: %s\n", err.message);
            }
        }

        private void callback_pid(Pid pid, int status)
        {
            Process.close_pid (pid);
            MainWindows win = new MainWindows(kf);
            win.show_all();
#if USE_GTK2
            this.hide_all();
#endif
#if USE_GTK3
            this.hide();
#endif
        }

        public KeyFile get_keyfile()
        {
        /* Configuration file */
            string config_path_directory = Path.build_filename(Environment.get_user_config_dir (),"lxsession-default-apps");
            
            KeyFile kf = load_key_conf(config_path_directory, "settings.conf");

            return kf;
        }
    }

    public class MainWindows : Gtk.Window
    { 
	    public MainWindows (KeyFile kf)
        {
		    this.title = _("LXSession configuration");
		    this.window_position = Gtk.WindowPosition.CENTER;
            try
            {
                this.icon = IconTheme.get_default ().load_icon ("preferences-desktop", 48, 0);
            }
            catch (Error e)
            {
                message ("Could not load application icon: %s\n", e.message);
            }
		    this.set_default_size (600, 400);
            this.destroy.connect (Gtk.main_quit);

            var builder = new Builder ();
            try
            {
                // If the UI contains custom widgets, their types must've been instantiated once
                // Type type = typeof(Foo.BarEntry);
                // assert(type != 0);

                var builder_file_path = Path.build_filename("data","ui","lxsession-default-apps.ui");
                var builder_file = File.new_for_path(builder_file_path);

                if (builder_file.query_exists())
                {
                    builder.add_from_file (builder_file_path);
                }
                else
                {
                    /* TODO Make it smart with prefix */
                    builder_file_path = Path.build_filename("/usr","share","lxsession","ui","lxsession-default-apps.ui");
                    builder.add_from_file (builder_file_path);
                }
            } 
            catch (GLib.Error e)
            {
                critical ("Could not load UI: %s\n", e.message);
            } 
            builder.connect_signals (null);
            var main_vbox = builder.get_object ("main_vbox") as VBox;
            main_vbox.show_all();
            this.add(main_vbox);
            main_vbox.reparent(this);

            try
            {
                this.icon = IconTheme.get_default ().load_icon ("xfwm4", 48, 0);
            }
            catch (Error e)
            {
                message ("Could not load application icon: %s\n", e.message);
            }

            var dbus_backend = new DbusBackend("session");

            /* Autostart list */
            manual_autostart_init(builder);
            autostart_core_applications(builder, dbus_backend);

            /* Common string */
            string manual_setting_help = _("Manual Settings: Manually sets the command (you need to restart lxsession-default-apps to see the change)\n");
            string session_string_help = _("Session : specify the session\n");
            string extra_string_help = _("Extra: Add an extra parameter to the launch option\n");
            string mime_association_help = _("Mime association: Automatically associates mime types to this application ?\n");
            string mime_available_help = _("Available applications : Applications of this type available on your repositories\n");
            string handle_desktop_help = _("Handle Desktop: Draw the desktop using the file manager ?\n");
            string autostart_help = _("Autostart the application ?\n");
            string debian_default_help = _("Set default program for Debian system (using update-alternatives, need root password)\n");

            /* New inits */
            string windows_manager_help_message = _("Windows manager draws and manage the windows. \nYou can choose openbox, openbox-custom (for a custom openbox configuration, see \"More\"), kwin, compiz ...");
            string[] windows_manager_more = {"session", "extras"};
            string windows_manager_more_help_message = session_string_help + extra_string_help;
            init_application(builder, kf, dbus_backend, "windows_manager", "", windows_manager_help_message, windows_manager_more, windows_manager_more_help_message, null);

            string panel_help_message = _("Panel is the component usually at the bottom of the screen which manages a list of opened windows, shortcuts, notification area ...");
            string[] panel_more = {"session"};
            string panel_more_help_message = session_string_help;
            init_application(builder, kf, dbus_backend, "panel", "", panel_help_message, panel_more, panel_more_help_message, null);

            string dock_help_message = _("Dock is a second panel. It's used to launch a different program to handle a second type of panel.");
            string[] dock_more = {"session"};
            string dock_more_help_message = session_string_help;
            init_application(builder, kf, dbus_backend, "dock", "", dock_help_message, dock_more, dock_more_help_message, null);

            string file_manager_help_message = _("File manager is the component which open the files.\nSee \"More\" to add options to handle the desktop, or opening files ");
            string[] file_manager_more = {"combobox_manual", "session", "extra", "handle_desktop", "mime_association", "mime_available"};
            string file_manager_more_help_message = manual_setting_help + session_string_help + extra_string_help + handle_desktop_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "file_manager", "", file_manager_help_message, file_manager_more, file_manager_more_help_message, null);

            string composite_manager_help_message = _("Composite manager enables graphics effects, like transpacency and shadows, if the windows manager doesn't handle it. \nExample: compton");
            string[] composite_manager_more = {""};
            string composite_manager_more_help_message = "";
            init_application(builder, kf, dbus_backend, "composite_manager", "", composite_manager_help_message, composite_manager_more, composite_manager_more_help_message, null);

            string desktop_manager_help_message = _("Desktop manager draws the desktop and manages the icons inside it.\nYou can manage it with the file manager by setting \"filemanager\"");
            string[] desktop_manager_more = {"wallpaper", "handle_desktop"};
            string desktop_manager_more_help_message = _("Wallpaper: Set an image path to draw the wallpaper");
            init_application(builder, kf, dbus_backend, "desktop_manager", "", desktop_manager_help_message, desktop_manager_more, desktop_manager_more_help_message, null);

            string screensaver_help_message = _("Screensaver is a program which displays animations when your computer is idle");
            string[] screensaver_more = {""};
            string screensaver_more_help_message = "";
            init_application(builder, kf, dbus_backend, "screensaver", "", screensaver_help_message, screensaver_more, screensaver_more_help_message, null);

            string power_manager_help_message = _("Power Manager helps you to reduce the usage of batteries. You probably don't need one if you have a desktop computer.\nAuto option will set it automatically, depending of the laptop mode option.");
            string[] power_manager_more = {""};
            string power_manager_more_help_message = "";
            init_application(builder, kf, dbus_backend, "power_manager", "", power_manager_help_message, power_manager_more, power_manager_more_help_message, null);

            string polkit_help_message = _("Polkit agent provides authorisations to use some actions, like suspend, hibernate, using Consolekit ... It's not advised to make it blank.");
            string[] polkit_more = {""};
            string polkit_more_help_message = "";
            init_application(builder, kf, dbus_backend, "polkit", "", polkit_help_message, polkit_more, polkit_more_help_message, null);

            string network_gui_help_message = _("Set an utility to manager connections, such as nm-applet");
            string[] network_gui_more = {""};
            string network_gui_more_help_message = "";
            init_application(builder, kf, dbus_backend, "network_gui", "", network_gui_help_message, network_gui_more, network_gui_more_help_message, null);

            string im1_help_message = _("Use a communication software (an IRC client, an IM client ...)");
            string[] im1_more = {"combobox_manual", "autostart", "mime_association", "mime_available"};
            string im1_more_help_message = manual_setting_help + autostart_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "im1", "", im1_help_message, im1_more, im1_more_help_message, "im");

            string im2_help_message = _("Use another communication software (an IRC client, an IM client ...)");
            string[] im2_more = {"combobox_manual", "autostart", "mime_association", "mime_available"};
            string im2_more_help_message = manual_setting_help + autostart_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "im2", "", im2_help_message, im2_more, im2_more_help_message, "im");

            string terminal_manager_help_message = _("Terminal by default to launch command line.");
            string[] terminal_manager_more = {"combobox_manual", "debian_default", "mime_association", "mime_available"};
            string terminal_manager_more_help_message = manual_setting_help + debian_default_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "terminal_manager", "", terminal_manager_help_message, terminal_manager_more, terminal_manager_more_help_message, null);

            string webbrowser_help_message = _("Application to go to Internet, Google, Facebook, debian.org ...");
            string[] webbrowser_more = {"combobox_manual", "debian_default", "mime_association", "mime_available"};
            string webbrowser_more_help_message = manual_setting_help + debian_default_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "webbrowser", "", webbrowser_help_message, webbrowser_more, webbrowser_more_help_message, null);

            string email_help_message = _("Application to send mails");
            string[] email_more = {"combobox_manual", "mime_association", "mime_available"};
            string email_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "email", "", email_help_message, email_more, email_more_help_message, null);

            string widget_help_message = _("Utility to launch gadgets, like conky, screenlets ...");
            string[] widget_more = {"autostart"};
            string widget_more_help_message = autostart_help;
            init_application(builder, kf, dbus_backend, "widget1", "", widget_help_message, widget_more, widget_more_help_message, "widget");

            string launcher_manager_help_message = _("Utility to launch application, like synapse, kupfer ... \nFor using lxpanel or lxde default utility, use \"lxpanelctl\" ");
            string[] launcher_manager_more = {"autostart"};
            string launcher_manager_more_help_message = autostart_help;
            init_application(builder, kf, dbus_backend, "launcher_manager", "", launcher_manager_help_message, launcher_manager_more, launcher_manager_more_help_message, null);

            string screenshot_manager_help_message = _("Application for taking screeshot of your desktop, like scrot ...");
            string[] screenshot_manager_more = {""};
            string screenshot_manager_more_help_message = autostart_help;
            init_application(builder, kf, dbus_backend, "screenshot_manager", "", screenshot_manager_help_message, screenshot_manager_more, screenshot_manager_more_help_message, null);

            string pdf_reader_help_message = "Viewer for PDF, like evince";
            string[] pdf_reader_more = {"combobox_manual", "mime_association", "mime_available"};
            string pdf_reader_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "pdf_reader", "", pdf_reader_help_message, pdf_reader_more, pdf_reader_more_help_message, null);

            string video_player_help_message = _("Video application");
            string[] video_player_more = {"combobox_manual", "mime_association", "mime_available"};
            string video_player_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "video_player", "", video_player_help_message, video_player_more, video_player_more_help_message, null);

            string audio_player_help_message = _("Audio application");
            string[] audio_player_more = {"combobox_manual", "mime_association", "mime_available"};
            string audio_player_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "audio_player", "", audio_player_help_message, audio_player_more, audio_player_more_help_message, null);

            string image_display_help_message = _("Application to display images");
            string[] image_display_more = {"combobox_manual", "mime_association", "mime_available"};
            string image_display_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "image_display", "", image_display_help_message, image_display_more, image_display_more_help_message, "image_display");

            string text_editor_help_message = _("Application to edit text");
            string[] text_editor_more = {"combobox_manual", "mime_association", "mime_available", "debian_default"};
            string text_editor_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "text_editor", "", text_editor_help_message, text_editor_more, text_editor_more_help_message, "text_editor");

            string archive_help_message = _("Application to create archives, like file-roller");
            string[] archive_more = {"combobox_manual", "mime_association", "mime_available"};
            string archive_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "archive", "", archive_help_message, archive_more, archive_more_help_message, null);

            string charmap_help_message = _("Charmap application");
            string[] charmap_more = {""};
            string charmap_more_help_message = "";
            init_application(builder, kf, dbus_backend, "charmap", "", charmap_help_message, charmap_more, charmap_more_help_message, null);

            string calculator_help_message = _("Calculator application");
            string[] calculator_more = {""};
            string calculator_more_help_message = "";
            init_application(builder, kf, dbus_backend, "calculator", "", calculator_help_message, calculator_more, calculator_more_help_message, null);

            string spreadsheet_help_message = _("Application to create spreedsheet, like gnumeric");
            string[] spreadsheet_more = {"combobox_manual", "mime_association", "mime_available"};
            string spreadsheet_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "spreadsheet", "", spreadsheet_help_message, spreadsheet_more, spreadsheet_more_help_message, null);

            string bittorent_help_message = _("Application to manage bittorent, like transmission");
            string[] bittorent_more = {"combobox_manual", "mime_association", "mime_available"};
            string bittorent_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "bittorent", "", bittorent_help_message, bittorent_more, bittorent_more_help_message, null);

            string document_help_message = _("Application to manage office text, like abiword");
            string[] document_more = {"combobox_manual", "mime_association", "mime_available"};
            string document_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "document", "", document_help_message, document_more, document_more_help_message, null);

            string webcam_help_message = _("Application to manage webcam");
            string[] webcam_more = {""};
            string webcam_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "webcam", "", webcam_help_message, webcam_more, webcam_more_help_message, null);

            string burn_help_message = _("Application to manage burning CD/DVD utilty ");
            string[] burn_more = {"combobox_manual", "mime_association", "mime_available"};
            string burn_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "burn", "", burn_help_message, burn_more, burn_more_help_message, null);

            string notes_help_message = _("Application to manage notes utility");
            string[] notes_more = {""};
            string notes_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "notes", "", notes_help_message, notes_more, notes_more_help_message, null);

            string disk_utility_help_message = _("Application to manage disks");
            string[] disk_utility_more = {""};
            string disk_utility_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "disk_utility", "", disk_utility_help_message, disk_utility_more, disk_utility_more_help_message, null);

            string tasks_help_message = _("Application to monitor tasks running on your system");
            string[] tasks_more = {"combobox_manual", "mime_association", "mime_available"};
            string tasks_more_help_message = manual_setting_help + mime_association_help + mime_available_help;
            init_application_combobox (builder, kf, dbus_backend, "tasks", "", tasks_help_message, tasks_more, tasks_more_help_message, null);

            string lock_manager_help_message = _("Application to lock your screen");
            string[] lock_manager_more = {""};
            string lock_manager_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "lock_manager", "", lock_manager_help_message, lock_manager_more, lock_manager_more_help_message, null);

            string audio_manager_help_message = _("Managing your audio configuration");
            string[] audio_manager_more = {""};
            string audio_manager_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "audio_manager", "", audio_manager_help_message, audio_manager_more, audio_manager_more_help_message, null);

            string workspace_manager_help_message = _("Managing your workspace configuration");
            string[] workspace_manager_more = {""};
            string workspace_manager_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "workspace_manager", "", workspace_manager_help_message, workspace_manager_more, workspace_manager_more_help_message, null);

            string quit_manager_help_message = _("Managing the application to quit your session");
            string[] quit_manager_more = {""};
            string quit_manager_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "quit_manager", "", quit_manager_help_message, quit_manager_more, quit_manager_more_help_message, null);

            string upgrade_manager_help_message = _("Managing the application to update and upgrade your system");
            string[] upgrade_manager_more = {""};
            string upgrade_manager_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "upgrade_manager", "", upgrade_manager_help_message, upgrade_manager_more, upgrade_manager_more_help_message, null);

            string clipboard_help_message = _("Managing clipboard support");
            string[] clipboard_more = {""};
            string clipboard_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "clipboard", "", clipboard_help_message, clipboard_more, clipboard_more_help_message, null);

            string security_help_message = _("Managing keyring support.\nStandard options available \"gnome\" for gnome-keyring support  or \"ssh-agent\" for ssh-agent support");
            string[] security_more = {""};
            string security_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "keyring", "", security_help_message, security_more, security_more_help_message, null);

            string a11y_help_message = _("Managing support for accessibility.\nStardart option are gnome, for stardart gnome support.");
            string[] a11y_more = {""};
            string a11y_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "a11y", "", a11y_help_message, a11y_more, a11y_more_help_message, null);

            string proxy_manager_help_message = _("Managing proxy support");
            string[] proxy_manager_more = {""};
            string proxy_manager_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "proxy_manager", "", proxy_manager_help_message, proxy_manager_more, proxy_manager_more_help_message, null);

            string xrandr_help_message = _("Managing XRandr parameters. Use a command like xrandr --something");
            string[] xrandr_more = {""};
            string xrandr_more_help_message = manual_setting_help;
            init_application(builder, kf, dbus_backend, "xrandr", "", xrandr_help_message, xrandr_more, xrandr_more_help_message, null);

            /* TODO Adapat to be generic ? A bit too complex for now */
            var disable_autostart_combobox = new Gtk.ComboBox();
            string[] disable_autostart_commands = { "no", "config-only", "all"};
            string disable_autostart_default = dbus_backend.Get("disable_autostart", "");
            disable_autostart_combobox = ui_combobox_init(  builder,
                                                            "disable_autostart_combobox",
                                                            disable_autostart_commands,
                                                            null,
                                                            disable_autostart_default);

            dbus_backend.Set("disable_autostart", "", return_combobox_text(disable_autostart_combobox));
            var auto_vbox = builder.get_object("manual_autostart_vbox") as Gtk.VBox;
            var running_apps = builder.get_object("running_apps_vbox") as Gtk.VBox;

            var known_apps_box = builder.get_object("autostart_known_box") as Gtk.HBox;
            var known_apps =  builder.get_object("autostart_treeview") as Gtk.TreeView;

            init_list_view(known_apps);
            load_autostart(Environment.get_variable("XDG_CURRENT_DESKTOP"));
            known_apps.set_model (get_autostart_list ());
#if USE_GTK2
            known_apps_box.hide_all();
#endif
#if USE_GTK3
            known_apps_box.hide();
#endif

            disable_autostart_combobox.changed.connect (() => {
                if (return_combobox_text(disable_autostart_combobox) == "all")
                {
#if USE_GTK2
                    auto_vbox.hide_all();
                    running_apps.hide_all();
#endif
#if USE_GTK3
                    auto_vbox.hide();
                    running_apps.hide();
#endif
                }
                else
                {
                    running_apps.show_all();
                    auto_vbox.show_all();
                }

                if (return_combobox_text(disable_autostart_combobox) == "no")
                {
                    known_apps_box.show_all();
                }
                else
                {
#if USE_GTK2
                    known_apps_box.hide_all();
#endif
#if USE_GTK3
                    known_apps_box.hide();
#endif
                }
                dbus_backend.Set("disable_autostart", "", return_combobox_text(disable_autostart_combobox));
            });

            /* TODO Make this generic */
            /* Note using glade + Vala for checkbutton doesnt work, so we have to create it in the code */
            var upstart_session_checkbutton = new Gtk.CheckButton.with_label ("Upstart ");
            var upstart_session_hbox = builder.get_object ("upstart_session_hbox") as Gtk.HBox;
            upstart_session_hbox.add(upstart_session_checkbutton);

            if (dbus_backend.Get("upstart_user_session", "") == "true")
            {
                upstart_session_checkbutton.set_active(true);
            }
            else
            {
                upstart_session_checkbutton.set_active(false);
            }

            upstart_session_checkbutton.toggled.connect (() => {
                if (upstart_session_checkbutton.get_active())
                {
                    dbus_backend.Set("upstart_user_session", "", "true");
                }
                else
                {
                    dbus_backend.Set("upstart_user_session", "", "false");
                }
            });

            /* Keymap init */
            var keymap_mode_combobox = new Gtk.ComboBox();
            string[] keymap_mode_commands = { "", "user"};
            string keymap_mode_default = dbus_backend.KeymapGet("mode", null);
            keymap_mode_combobox = ui_combobox_init(    builder,
                                                        "keymap_mode_combobox",
                                                        keymap_mode_commands,
                                                        null,
                                                        keymap_mode_default);

            var keymap_model_entry = builder.get_object("keymap_model_entry") as Gtk.Entry;
            keymap_model_entry.set_text(dbus_backend.KeymapGet("model", null));

            var keymap_layout_entry = builder.get_object("keymap_layout_entry") as Gtk.Entry;
            keymap_layout_entry.set_text(dbus_backend.KeymapGet("layout", null));

            var keymap_variant_entry = builder.get_object("keymap_variant_entry") as Gtk.Entry;
            keymap_variant_entry.set_text(dbus_backend.KeymapGet("variant", null));

            var keymap_options_entry = builder.get_object("keymap_options_entry") as Gtk.Entry;
            keymap_options_entry.set_text(dbus_backend.KeymapGet("options", null));

            var keymap_apply_button = builder.get_object("keymap_apply") as Gtk.Button;
            keymap_apply_button.clicked.connect (() => {
                message ("Click !");
                dbus_backend.KeymapSet("mode", null, return_combobox_text(keymap_mode_combobox));
                dbus_backend.KeymapSet("model", null, keymap_model_entry.get_text());
                dbus_backend.KeymapSet("layout", null, keymap_layout_entry.get_text());
                dbus_backend.KeymapSet("variant", null, keymap_variant_entry.get_text());
                dbus_backend.KeymapSet("options", null, keymap_options_entry.get_text());
            });

            var keymap_reload_button = builder.get_object("keymap_reload") as Gtk.Button;
            keymap_reload_button.clicked.connect (() => {
                dbus_backend.KeymapActivate();
            });

            /* Laptop mode */
            var laptop_mode_combobox = new Gtk.ComboBox();
            string[] laptop_mode_commands = { "no", "yes", "unknown"};
            string laptop_mode_default = dbus_backend.StateGet("laptop_mode", null);
            laptop_mode_combobox = ui_combobox_init(  builder,
                                                      "laptop_mode_combobox",
                                                      laptop_mode_commands,
                                                      null,
                                                      laptop_mode_default);

            laptop_mode_combobox.changed.connect (() => {
                dbus_backend.StateSet("laptop_mode", null, return_combobox_text(laptop_mode_combobox));
            });

            /* Dbus */
            var dbus_gnome_checkbutton = new Gtk.CheckButton.with_label ("Gnome");
            var dbus_vbox = builder.get_object ("dbus_vbox") as Gtk.VBox;

            dbus_vbox.add(dbus_gnome_checkbutton);

            if (dbus_backend.DbusGet("gnome", null) == "true")
            {
                dbus_gnome_checkbutton.set_active(true);
            }
            else
            {
                dbus_gnome_checkbutton.set_active(false);
            }

            dbus_gnome_checkbutton.toggled.connect (() => {
                message ("Click !");
                if (dbus_gnome_checkbutton.get_active())
                {
                    dbus_backend.DbusSet("gnome", null, "true");
                }
                else
                {
                    dbus_backend.DbusSet("gnome", null, "false");
                }
            });

            /* Environment */
            var environment_type_combobox = new Gtk.ComboBox();
            string[] environment_type_commands = { "", "lubuntu"};
            string environment_type_default = dbus_backend.EnvironmentGet("type", null);
            environment_type_combobox = ui_combobox_init(   builder,
                                                            "environment_type_combobox",
                                                            environment_type_commands,
                                                            null,
                                                            environment_type_default);

            environment_type_combobox.changed.connect (() => {
                dbus_backend.EnvironmentSet("type", null, return_combobox_text(environment_type_combobox));
            });

            var enviroment_menu_prefix_entry = builder.get_object("environment_menu_prefix_entry") as Gtk.Entry;
            enviroment_menu_prefix_entry.set_text(dbus_backend.EnvironmentGet("menu_prefix", null));

            var env_apply_button = builder.get_object("env_apply") as Gtk.Button;
            env_apply_button.clicked.connect (() => {
                message ("Click !");
                dbus_backend.EnvironmentSet("menu_prefix", null, enviroment_menu_prefix_entry.get_text());
            });
        }
    }

    public static int main(string[] args)
    {
        Intl.textdomain(GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
        /* Init GTK */
        Gtk.init (ref args);


        /* Log on .log file */
        string log_directory = Path.build_filename(Environment.get_user_cache_dir(), "lxsession-default-apps");
        var dir_log = File.new_for_path (log_directory);

        string log_path = Path.build_filename(log_directory, "run.log");

        message ("log directory: %s",log_directory);
        message ("log path: %s",log_path);

        if (!dir_log.query_exists ())
        {
            try
            {
                dir_log.make_directory_with_parents();
            }
            catch (GLib.Error e)
            {
                GLib.stderr.printf ("Could not write log: %s\n", e.message);
            }
        }

        int fint;
        fint = open (log_path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
        dup2 (fint, STDOUT_FILENO);
        dup2 (fint, STDERR_FILENO);
        close(fint);

        /* Update the database before anything */
		UpdateWindows app = new UpdateWindows ();
		app.show_all ();

        /* start main loop */
        Gtk.main ();


        return 0;
    }
}
