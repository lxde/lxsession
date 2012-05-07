NULL=

SUBDIRS= \
	ui \
	$(NULL)

desktopdir = $(datadir)/applications
desktop_in_files = \
	lxsession-edit.desktop.in \
	$(NULL)
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@
DISTCLEANFILES = \
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
	$(desktop_DATA) \
	$(image_DATA) \
	$(NULL)
