#created by toplevel Makefile
SUBDIRS = messages
AUTOMAKE_OPTIONS = foreign
EXTRA_DIST = configure.in.in
$(srcdir)/configure.in.in: $(srcdir)/../Makefile.am
	cd $(srcdir) && make -f ../Makefile.am langsubdir SUBDIRLANG=eo
$(srcdir)/configure.in: $(srcdir)/configure.in.in
	cd $(srcdir) && make -f ../admin/Makefile.common configure.in
$(srcdir)/acinclude.m4: $(srcdir)/../acinclude.m4
	cd $(srcdir) && cp ../acinclude.m4 .
dist-hook:
	for i in am_edit install-sh ltmain.sh ltconfig config.sub config.guess mkinstalldirs missing; do cp $(top_srcdir)/../admin/$$i $(top_distdir)/$$i ; done && \
	(cd $(top_distdir) && \
	grep -v AC_CONFIG_AUX_DIR configure.in.in > tmp && mv tmp configure.in.in && \
	grep -v AC_CONFIG_AUX_DIR configure.in > tmp && mv tmp configure.in && \
	echo '#created by toplevel Makefile' > Makefile.am ;\
	echo 'SUBDIRS = messages' >> Makefile.am ;\
	echo 'AUTOMAKE_OPTIONS = foreign' >> /Makefile.am ; \
	aclocal && \
	automake --foreign --include-deps && \
	perl am_edit && \
	autoheader && autoconf)
.SILENT:

