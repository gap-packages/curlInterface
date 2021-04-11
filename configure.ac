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
AC_CONFIG_HEADERS([gen/pkgconfig.h])
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
LIBCURL_CHECK_CONFIG([yes],[],[],[AC_MSG_ERROR([libcurl development files required])])

dnl ##
dnl ## Output everything
dnl ##
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
