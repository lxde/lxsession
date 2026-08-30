NULL=

# GtkBuilder UI definition files
uidir=$(datadir)/lxsession/ui
ui_DATA= \
	lxsession-default-apps.ui \
	lxsession-edit.ui \
	$(NULL)

if HAVE_POLKIT
ui_DATA += \
	lxpolkit.ui
endif

EXTRA_DIST= \
	$(ui_DATA) \
	$(NULL)
