
dist_man_MANS = lxsession.1 lxsession-logout.1

EXTRA_DIST = lxsession.sgml lxsession-logout.sgml

dist-hook: lxsession.1 lxsession-logout.1

lxsession.1: lxsession.sgml
	docbook-to-man $< > $@
lxsession-logout.1: lxsession-logout.sgml
	docbook-to-man $< > $@
        