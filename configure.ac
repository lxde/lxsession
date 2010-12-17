AC_PREREQ([2.57])
AC_INIT(lxsession,[0.4.5], [],lxsession)
AM_INIT_AUTOMAKE([1.11 -Wall -Werror foreign])

# Support silent build rules. Disable by either passing --disable-silent-rules
# to configure or passing V=1 to make
AM_SILENT_RULES([yes])
AC_PROG_INTLTOOL(, [no-xml])
AM_MAINTAINER_MODE

AM_CONFIG_HEADER(config.h)
AC_CONFIG_MACRO_DIR([m4])

AC_PROG_CC
AC_PROG_INSTALL
AM_PROG_CC_C_O
AC_PROG_CC_STDC

#Initialize libtool
LT_PREREQ([2.2])
LT_INIT

AC_CHECK_FUNC([mkstemp],
   AC_DEFINE(HAS_MKSTEMP,1,[Define to 1 if you have the 'mkstemp' function.]))

AC_ARG_ENABLE(man,
       [AC_HELP_STRING([--enable-man],
               [regenerate roff man pages from Docbook @<:@default=no@:>@])],
       [enable_man="${enableval}"],
       [enable_man=no]
)

#Don't use deprecated GTK and Glib functions 
DISABLE_DEPRECATED_FLAGS="-DG_DISABLE_DEPRECATED -DG_DISABLE_SINGLE_INCLUDES -DGDK_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_SINGLE_INCLUDES -DGTK_DISABLE_DEPRECATED -DGTK_DISABLE_SINGLE_INCLUDES -DGSEAL_ENABLE"
AC_SUBST(DISABLE_DEPRECATED_FLAGS)

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
        AC_MSG_ERROR([To build with DBUS support, you must have the development package for dbus-1, or you can use --disable-dbus to disable DBUS support.])
    fi
fi
AM_CONDITIONAL(USE_DBUS, test "$use_dbus" = "yes")
AC_SUBST(DBUS_CFLAGS)
AC_SUBST(DBUS_LIBS)

# Generate po/LINGUAS on the fly rather than relying on translators
# to maintain it manually. This also overcome the problem that Transifex
# cannot add a language to po/LINGUAS if a new po file is submitted.
rm -f $srcdir/po/LINGUAS
for po_file in `ls $srcdir/po/*.po | sort`;
do
    lang=`echo "$po_file" | sed "s|.*/po/\(.*\)\.po|\1|g"`
    echo $lang >> $srcdir/po/LINGUAS
done

GETTEXT_PACKAGE=lxsession
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [Gettext package.])

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
