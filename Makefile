
#---------------------------
# GNU Makefile for Krokit
#---------------------------

TARGET   :=  krokit

SRCDIR   :=  src
DISTDIR  :=  dist
BUILDDIR :=  build
KTAGDIR  :=  __ktags
INSTALL  ?=  install
PREFIX   ?=  /usr/local
BINDIR   :=  $(PREFIX)/bin
PKGBUILDDIR := $(BUILDDIR)/$(TARGET)-build

all: sanity

sanity:
	bash -n $(SRCDIR)/krokit.sh

install:
	$(INSTALL) -D $(SRCDIR)/krokit.sh $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(TARGET)

dist:
	@kdebuild --dpkg

build:
	@eval build/scripts/buildenv.sh

clean:

cfgclean distclean:
	rm -rf $(PKGBUILDDIR) $(DISTDIR)/* $(KTAGDIR)

.PHONY: all sanity build clean dist install uninstall

