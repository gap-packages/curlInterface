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
AC_CONFIG_HEADER([src/pkgconfig.h:cnf/pkgconfig.h.in])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([cnf])
m4_include([m4/ac_find_gap.m4])
m4_include([m4/libcurl.m4])


dnl ##
dnl ## Get canonical host info
dnl ##
AC_CANONICAL_HOST

dnl ##
dnl ## Setup automake
dnl ##
AM_INIT_AUTOMAKE([1.11 -Wall foreign subdir-objects])
AM_SILENT_RULES([yes])
AM_PROG_AR

dnl ##
dnl ## Set the language
dnl ##
AC_PROG_CC
AC_LANG([C])

dnl ##
dnl ## Setup libtool (for building the GAP kernel extension)
dnl ##
LT_PREREQ([2.4.2])
LT_INIT([disable-static dlopen win32-dll])

dnl ##
dnl ## Locate the GAP root dir
dnl ##
AC_FIND_GAP

dnl ##
dnl ## Detect Windows resp. Cygwin
dnl ##
case $host_os in
  *cygwin* ) CYGWIN=yes;;
         * ) CYGWIN=no;;
esac
AM_CONDITIONAL([SYS_IS_CYGWIN], [test "$CYGWIN" = "yes"])
if test "$CYGWIN" = "yes"; then
  AC_DEFINE(SYS_IS_CYGWIN32, 1, are we on CYGWIN?)
else
  AC_DEFINE(SYS_IS_CYGWIN32, 0, are we on CYGWIN?)
fi

dnl ##
dnl ## Check for libcurl
dnl ##
LIBCURL_CHECK_CONFIG([yes],[],[],[AC_MSG_ERROR([libcurl development files required])])

 AC_PATH_PROG(CURL_CONFIG, curl-config, no)
    if test "$CURL_CONFIG" = "no" ; then
        AC_MSG_ERROR([*** The curl-config script installed by curl could not be found])
    else
    echo "curl found - remote install options available"
    CURL_AM_CFLAGS=`$CURL_CONFIG --cflags`
    CURL_LIBS=`$CURL_CONFIG --libs`
    AM_CXXFLAGS="$AM_CXXFLAGS $CURL_AM_CFLAGS"
    AM_CFLAGS="$AM_CFLAGS $CURL_AM_CFLAGS"
    LIBS="$LIBS $CURL_LIBS"
    if test x$with_curl_sftp = xyes; then
        if test x`$CURL_CONFIG --protocols|grep SFTP|wc -l` = x1; then
            AM_CXXFLAGS="$AM_CXXFLAGS -DCURLSFTPAVAILABLE"
            AM_CFLAGS="$AM_CFLAGS -DCURLSFTPAVAILABLE"
        else
            with_curl_sftp=no;
        fi
	fi
    fi

dnl ##
dnl ## Output everything
dnl ##
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
