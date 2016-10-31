SRCS		+= $(NAME).c
OBJS		+= $(NAME).o $(WIN32RES)

rpath =

all: all-static-lib

include $(top_srcdir)/src/Makefile.shlib

install: all installdirs install-lib-static

installdirs: installdirs-lib

uninstall: uninstall-lib

clean distclean maintainer-clean: clean-lib
	rm -f $(OBJS)
