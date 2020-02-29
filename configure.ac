AC_INIT([lxsession],[0.5.5],[],[lxsession])

# Autotols programs
AM_INIT_AUTOMAKE([1.11.1 -Wall -Werror foreign no-dist-gzip dist-xz])
AC_PREREQ([2.68])
IT_PROG_INTLTOOL([0.40.0],[no-xml])

# Support silent build rules. Disable by either passing --disable-silent-rules
# to configure or passing V=1 to make
AM_SILENT_RULES([yes])

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

# C compiler
AC_PROG_CC
AC_PROG_INSTALL
AM_PROG_CC_C_O
AC_PROG_CC_STDC


AC_CHECK_FUNC([mkstemp],
   AC_DEFINE(HAS_MKSTEMP,1,[Define to 1 if you have the 'mkstemp' function.]))

AC_ARG_ENABLE(man,
       [AS_HELP_STRING([--enable-man],
               [regenerate roff man pages from Docbook @<:@default=yes@:>@])],
       [enable_man="${enableval}"],
       [enable_man=yes]
)

AC_ARG_ENABLE(more_warnings,
       [AS_HELP_STRING([--enable-more-warnings],
               [Add more warnings @<:@default=no@:>@])],
       [enable_more_warnings="${enableval}"],
       [enable_more_warnings=no]
)

if test x"$enable_more_warnings" = x"yes"; then
  ADDITIONAL_FLAGS="-Wall -Werror=all -Werror=format -Werror=implicit-function-declaration -Werror=implicit-int -Werror=missing-braces -Werror=parentheses -Werror=return-type -Werror=strict-aliasing -Werror=switch -Wuninitialized -Werror=unused-label -Werror=unused-value -Wextra -Wno-missing-field-initializers -Wno-unused-parameter -Werror=missing-declarations -Wredundant-decls -Wmissing-noreturn -Wpointer-arith -Wcast-align -Wwrite-strings -Werror=inline -Werror=format-nonliteral -Wformat-nonliteral -Werror=format-security -Wformat-security -Winit-self -Werror=missing-include-dirs -Werror=undef -Werror=aggregate-return -Wmissing-format-attribute -Werror=nested-externs -fno-strict-aliasing -fmessage-length=0 -Wp,-D_FORTIFY_SOURCE=2 -DG_DISABLE_DEPRECATED -DG_DISABLE_SINGLE_INCLUDES -DGDK_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_SINGLE_INCLUDES -DGTK_DISABLE_DEPRECATED -DGTK_DISABLE_SINGLE_INCLUDES"
fi
AC_SUBST(ADDITIONAL_FLAGS)

PKG_CHECK_MODULES(X11, [x11])
AC_SUBST(X11_CFLAGS)
AC_SUBST(X11_LIBS)

PKG_CHECK_MODULES(GLIB, [glib-2.0 >= 2.28.0])
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(GIO, [gio-unix-2.0])
AC_SUBST(GIO_CFLAGS)
AC_SUBST(GIO_LIBS)

AC_ARG_ENABLE(
    [gtk],
    AS_HELP_STRING([--enable-gtk],
                   [Build with gtk support (default: yes)]),
    use_gtk=$enableval, use_gtk="yes")

AM_CONDITIONAL(USE_GTK, test "$use_gtk" = "yes")

if test "x$use_gtk" = "xno" ; then
  enable_gtk3="no"
  use_buildin_clipboard="no"
  use_buildin_polkit="no"
else
  AC_ARG_ENABLE([gtk3],
      AS_HELP_STRING([--enable-gtk3],
                     [enable to use gtk-3.0 instead of gtk-2.0]),
      enable_gtk3=$enableval, enable_gtk3="no")

  if test "x$enable_gtk3" = "xyes" ; then
    CFLAGS="$CFLAGS -D USE_GTK3"
    gtk_modules="gtk+-3.0 >= 3.0.0"
    VALA_GTK_LIBS="gtk+-3.0"
  else
    CFLAGS="$CFLAGS -D USE_GTK2"
    gtk_modules="gtk+-2.0 >= 2.6.0"
    VALA_GTK_LIBS="gtk+-2.0"
  fi
  PKG_CHECK_MODULES(GTK, [$gtk_modules])
  AC_SUBST(GTK_CFLAGS)
  AC_SUBST(GTK_LIBS)

  AC_SUBST(VALA_GTK_LIBS)

  polkit_modules="polkit-agent-1"
  PKG_CHECK_MODULES(POLKIT, [$polkit_modules])
  AC_SUBST(POLKIT_CFLAGS)
  AC_SUBST(POLKIT_LIBS)

  AC_ARG_ENABLE(
      [buildin-clipboard],
      AS_HELP_STRING([--enable-buildin-clipboard],
                     [Build with build-in clipboard support (default: no)]),
      use_buildin_clipboard=$enableval, use_buildin_clipboard="no")

  AC_ARG_ENABLE(
      [buildin-polkit],
      AS_HELP_STRING([--enable-buildin-polkit],
                     [Build with build-in polkit-agent support (default: no)]),
      use_buildin_polkit=$enableval, use_buildin_polkit="no")

  AC_ARG_ENABLE(
      [advanced-notifications],
      AS_HELP_STRING([--enable-advanced-notifications],
                     [Build with advanced notification using indicators and libnotify (default: no)]),
      use_advanced_notifications=$enableval, use_advanced_notifications="no")

fi

AM_CONDITIONAL(USE_BUILDIN_CLIPBOARD, test "$use_buildin_clipboard" = "yes")
AM_CONDITIONAL(USE_BUILDIN_POLKIT, test "$use_buildin_polkit" = "yes")
AM_CONDITIONAL(USE_GTK3, test "$enable_gtk3" = "yes")
AM_CONDITIONAL(USE_ADVANCED_NOTIFICATIONS, test "$use_advanced_notifications" = "yes")

if test "$use_advanced_notifications" = "yes"; then
  PKG_CHECK_MODULES(INDICATORS, [indicator-0.4 >= 0.4.93 appindicator-0.1])
  AC_SUBST(INDICATORS_CFLAGS)
  AC_SUBST(INDICATORS_LIBS)

  PKG_CHECK_MODULES(LIBNOTIFY, [libnotify])
  AC_SUBST(LIBNOTIFY_CFLAGS)
  AC_SUBST(LIBNOTIFY_LIBS)
fi

if test "$use_buildin_polkit" = "yes"; then
  HIDE_LXPOLKIT_AUTOSTART=true
else
  HIDE_LXPOLKIT_AUTOSTART=false
fi
AC_SUBST(HIDE_LXPOLKIT_AUTOSTART)

AM_PROG_VALAC([0.16.0])
if test "x$VALAC" = "x"; then
  AC_MSG_ERROR([You need Vala compiler])
fi

# debug flags
AC_ARG_ENABLE(debug,
    [AS_HELP_STRING([--enable-debug],[build libfm with debug support @<:@default=no@:>@])],
    [enable_debug="${enableval}"],
    [enable_debug=no]
)
if test "$enable_debug" = "yes"; then
    # turn on debug and disable optimization
    CPPFLAGS="$CPPFLAGS -DG_ENABLE_DEBUG -O0 -g"
else
    # turn off glib debug checks
    CPPFLAGS="$CPPFLAGS -DG_DISABLE_ASSERT -DG_DISABLE_CHECKS -DG_DISABLE_CAST_CHECKS"
fi

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

dnl Fix invalid sysconfdir when --prefix=/usr
if test `eval "echo $sysconfdir"` = /usr/etc
then
    sysconfdir=/etc
fi

AC_CONFIG_FILES([
  Makefile
  data/Makefile
  data/ui/Makefile
  data/lxpolkit.desktop.in
  man/Makefile
  po/Makefile.in
])
AC_OUTPUT

echo
echo LXSession.................................... : Version $VERSION
echo
echo Prefix....................................... : $prefix
echo Sysconfdir................................... : $sysconfdir
echo GTK support.................................. : $use_gtk
echo GTK Cliboard build-in suport................. : $use_buildin_clipboard
echo GTK Polkit-agent build-in suport............. : $use_buildin_polkit
echo Enable GTK3 support.......................... : $enable_gtk3
echo Enable debug................................. : $enable_debug
echo Man pages generation support................. : $enable_man
echo
echo The binary will be installed in $prefix/bin
echo
echo http://lxde.org/
echo
echo Have fun!
echo
