#
# curlInterface: Simple Web Access
#
# This file is part of the build system of a GAP kernel extension.
# Requires automake.
#
ACLOCAL_AMFLAGS = -I m4

BINARCHDIR = bin/$(GAPARCH)
GAPINSTALLLIB = $(BINARCHDIR)/curl.so

lib_LTLIBRARIES = curl.la

curl_la_SOURCES = src/curl.c
curl_la_CPPFLAGS = $(GAP_CPPFLAGS)
curl_la_CFLAGS = $(GAP_CFLAGS)
curl_la_LDFLAGS = $(GAP_LDFLAGS) -module -avoid-version
if SYS_IS_CYGWIN
curl_la_LDFLAGS += -no-undefined -version-info 0:0:0 
curl_la_LDFLAGS += -Wl,$(GAPROOT)/bin/$(GAPARCH)/gap.dll
endif

all-local: $(GAPINSTALLLIB)

$(GAPINSTALLLIB): curl.la
	$(mkdir_p) $(BINARCHDIR)
if SYS_IS_CYGWIN
	cp .libs/curl.dll $(GAPINSTALLLIB)
else
	cp .libs/curl.so $(GAPINSTALLLIB)
endif

clean-local:
	rm -f $(GAPINSTALLLIB)

distclean-local:
	rm -rf bin/*

doc:
	($(GAPROOT)/bin/gap.sh -A makedoc.g)
