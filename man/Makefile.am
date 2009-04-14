
dist_man_MANS = lxsession.1 lxsession-logout.1

EXTRA_DIST = lxsession.sgml lxsession-logout.sgml

dist-hook: lxsession.1 lxsession-logout.1

lxsession.1: lxsession.sgml
	(test -f "`which docbook-to-man`" && docbook-to-man $< > $@) || \
	(test -f "`which db2man`" && db2man $< > $@) || \
	(test -f "`which docbook2man`" && docbook2man $< > $@)

lxsession-logout.1: lxsession-logout.sgml
	(test -f "`which docbook-to-man`" && docbook-to-man $< > $@) || \
	(test -f "`which db2man`" && db2man $< > $@) || \
	(test -f "`which docbook2man`" && docbook2man $< > $@)
