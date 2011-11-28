ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

NULL=

SUBDIRS= lxsession-logout \
         man \
         po \
         src \
         tests


imagedir=$(datadir)/lxsession/images
image_DATA= \
	images/system-shutdown.png \
	images/system-log-out.png \
	images/gnome-session-hibernate.png \
	images/gnome-session-reboot.png \
	images/gnome-session-suspend.png \
	images/gnome-session-switch.png

scripts=     lxlock
bin_SCRIPTS= $(scripts)

EXTRA_DIST = \
	desktop.conf.example \
	$(scripts) \
	$(image_DATA) \
	$(NULL)
