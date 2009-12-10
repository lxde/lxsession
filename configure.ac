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
    [hal],
    AS_HELP_STRING([--enable-hal],
                   [Build with Linux HAL support for shutdown/reboot/suspend (default: yes)]),
    use_hal=$enableval, use_hal="yes")

if test x"$use_hal" = x"yes"; then
dnl Check HAL support
    hal_modules="dbus-1"
    PKG_CHECK_MODULES(HAL, [$hal_modules], [have_hal=yes], [have_hal=no])

    if test x"$have_hal" = x"yes"; then
        AC_DEFINE([HAVE_HAL], [1], [Define to 1 if you have HAL.])
    else
        AC_MSG_ERROR([To use HAL support, you must have developing packages of dbus-glib-1 (>=0.31), or you can use --disable-hal to disable HAL support.])
    fi
fi
AM_CONDITIONAL(USE_HAL, test "$use_hal" = "yes")
AC_SUBST(HAL_CFLAGS)
AC_SUBST(HAL_LIBS)

GETTEXT_PACKAGE=lxsession
#AM_GNU_GETTEXT([external])
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
echo Linux HAL support............................ : $use_hal
echo
echo The binary will be installed in $prefix/bin
echo
echo http://lxde.org/
echo
echo Have fun!
echo
