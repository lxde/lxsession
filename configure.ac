AC_PREREQ([2.57])
AC_INIT(lxsession,[0.4.1], [],lxsession)
AM_INIT_AUTOMAKE()
AC_PROG_INTLTOOL(, [no-xml])
AM_MAINTAINER_MODE

AM_CONFIG_HEADER(config.h)

AC_PROG_CC
AC_PROG_INSTALL
AM_PROG_CC_C_O

AC_CHECK_FUNC([mkstemp],
   AC_DEFINE(HAS_MKSTEMP,1,[Define to 1 if you have the 'mkstemp' function.]))

AC_ARG_ENABLE(man,
       [AC_HELP_STRING([--enable-man],
               [regenerate roff man pages from Docbook @<:@default=no@:>@])],
       [enable_man="${enableval}"],
       [enable_man=no]
)

PKG_CHECK_MODULES(GTK, [gtk+-2.0 >= 2.6.0])
AC_SUBST(GTK_CFLAGS)
AC_SUBST(GTK_LIBS)

PKG_CHECK_MODULES(GLIB, [glib-2.0 >= 2.6.0])
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

AC_ARG_ENABLE(
    [dbus],
    AS_HELP_STRING([--enable-dbus],
                   [Build with Linux D-Bus support for shutdown/reboot/suspend (default: yes)]),
    use_dbus=$enableval, use_dbus="yes")

if test x"$use_dbus" = x"yes"; then
dnl Check DBUS support
    dbus_modules="dbus-1"
    PKG_CHECK_MODULES(DBUS, [$dbus_modules], [have_dbus=yes], [have_dbus=no])

    if test x"$have_dbus" = x"yes"; then
        AC_DEFINE([HAVE_DBUS], [1], [Define to 1 if you have DBUS.])
    else
        AC_MSG_ERROR([To use DBUS support, you must have developing packages of dbus-glib-1 (>=0.31), or you can use --disable-dbus to disable DBUS support.])
    fi
fi
AM_CONDITIONAL(USE_DBUS, test "$use_dbus" = "yes")
AC_SUBST(DBUS_CFLAGS)
AC_SUBST(DBUS_LIBS)

GETTEXT_PACKAGE=lxsession
AM_GNU_GETTEXT_VERSION(0.14.1)
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [Gettext package.])

ALL_LINGUAS="af ar cs da de es et eu fa fi fr gl hr hu id it ja ko lt ml ms nb nl nn pl ps pt pt_BR ru sk sl sv tr uk ur ur_PK vi zh_CN zh_TW"
AM_GLIB_GNU_GETTEXT

if test x"$enable_man" = x"yes"; then
	AC_PATH_PROG([XSLTPROC], [xsltproc])
	if test -z "$XSLTPROC"; then
		enable_man=no
	fi

	dnl check for DocBook DTD and stylesheets in the local catalog.
	JH_CHECK_XML_CATALOG([-//OASIS//DTD DocBook XML V4.1.2//EN],
		[DocBook XML DTD V4.1.2], [], enable_man=no)
	JH_CHECK_XML_CATALOG([http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl],
		[DocBook XSL Stylesheets >= 1.70.1], [], enable_man=no)
fi

AM_CONDITIONAL(ENABLE_REGENERATE_MAN, test "x$enable_man" != "xno")

AC_OUTPUT([
  Makefile
  lxsession/Makefile
  lxsession-logout/Makefile
  po/Makefile.in
  man/Makefile
])

echo
echo LXSession.................................... : Version $VERSION
echo
echo Prefix....................................... : $prefix
echo Linux DBUS support........................... : $use_dbus
echo
echo The binary will be installed in $prefix/bin
echo
echo http://lxde.org/
echo
echo Have fun!
echo
