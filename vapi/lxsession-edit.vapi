[CCode (cprefix = "LxsessionEdit", cheader_filename = "lxsession-edit/lxsession-edit-common.h")]

    public static void init_list_view( Gtk.TreeView *view );
    public static void load_autostart(string *session_name);
    public Gtk.ListStore get_autostart_list ();
