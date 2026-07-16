#
# curlInterface: Simple Web Access
#
# This file is part of the build system of a GAP kernel extension.
# Requires GNU autoconf, GNU automake and GNU libtool.
#

dnl ##
dnl ## Setup autoconf
dnl ##
AC_PREREQ([2.68])
AC_INIT([curlInterface], [GAP package])
AC_CONFIG_SRCDIR([src/curl.c])
AC_CONFIG_HEADERS([gen/pkgconfig.h:src/pkgconfig.h.in])
AC_CONFIG_MACRO_DIR([m4])
m4_include([m4/find_gap.m4])
m4_include([m4/libcurl.m4])

dnl ##
dnl ## Set the language
dnl ##
AC_PROG_CC
AC_LANG([C])

dnl ##
dnl ## Locate the GAP root dir
dnl ##
FIND_GAP

dnl ##
dnl ## Check for libcurl
dnl ##
libcurl_default=yes

dnl ## on macOS with Homebrew, check if it has libcurl installed and if so,
dnl ## prefer that over the ancient version bundled with macOS
AS_IF([test "x`uname -s 2>/dev/null`" = xDarwin], [
  AS_IF([command -v brew >/dev/null 2>&1], [
    libcurl_homebrew_prefix=`brew --prefix curl 2>/dev/null`
    AS_IF([test -x "$libcurl_homebrew_prefix/bin/curl-config"], [
      libcurl_default=$libcurl_homebrew_prefix
    ])
  ])
])

LIBCURL_CHECK_CONFIG([$libcurl_default],[],[
  AS_IF([test "x$libcurl_default" != xyes &&
         test -z "$with_libcurl"], [
    AC_MSG_NOTICE([using Homebrew libcurl from $libcurl_default])
  ])
],[
  AC_MSG_ERROR([libcurl development files required])
])

dnl ##
dnl ## Output everything
dnl ##
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
