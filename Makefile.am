cfgdir		 = $(datadir)/vyatta-cfg/templates

sbin_SCRIPTS = scripts/system/dhcpdv6-config.pl
sbin_SCRIPTS += scripts/system/dhcpdv6.init

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | cpio -0pd

all-local:
	./gen-templates.pl

clean-local:
	rm -rf generated-templates

install-exec-hook:
	mkdir -p $(DESTDIR)$(cfgdir)
	cd generated-templates; $(cpiop) $(DESTDIR)$(cfgdir) ; cd ..
