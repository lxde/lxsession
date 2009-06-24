man_MANS = \
	lxsession.1 \
	lxsession-logout.1

man_XMANS = \
	lxsession.xml \
	lxsession-logout.xml

EXTRA_DIST = \
	$(man_MANS) \
	$(man_XMANS)


if ENABLE_REGENERATE_MAN

lxsession.1: lxsession.xml
	$(XSLTPROC) -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl $<

lxsession-logout.1: lxsession-logout.xml
	$(XSLTPROC) -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl $<        

CLEANFILES = $(man_MANS) 
else

$(man_MANS):
	@echo ""
	@echo "Error: you need to run configure with '--enable-man'"
	@echo "       in order to regenerate man pages."
	@echo ""
	@false
endif


