NULL=

SUBDIRS= \
	ui \
	$(NULL)

desktopdir = $(datadir)/applications
desktop_in_files = \
	lxsession-default-apps.desktop.in \
	lxsession-edit.desktop.in \
	$(NULL)
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@
DISTCLEANFILES = \
	lxsession-default-apps.desktop \
	lxsession-edit.desktop \
	$(NULL)

imagedir=$(datadir)/lxsession/images
image_DATA= \
	images/system-shutdown.png \
	images/system-log-out.png \
	images/gnome-session-hibernate.png \
	images/gnome-session-reboot.png \
	images/gnome-session-suspend.png \
	images/gnome-session-switch.png

EXTRA_DIST= \
	desktop.conf.example \
	conffiles.conf.example \
	$(desktop_DATA) \
	$(desktop_in_files) \
	$(image_DATA) \
	$(NULL)
