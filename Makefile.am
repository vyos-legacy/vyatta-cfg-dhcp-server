cfgdir		 = $(datadir)/vyatta-cfg/templates

sbin_SCRIPTS =

sbin_SCRIPTS += scripts/system/dhcpd-config.pl
sbin_SCRIPTS += scripts/system/dhcpdv6-config.pl
sbin_SCRIPTS += scripts/system/dhcpd.init
sbin_SCRIPTS += scripts/system/dhcpdv6.init
sbin_SCRIPTS += scripts/system/on-dhcp-event.sh

curverdir = $(sysconfdir)/config-migrate/current
curver_DATA = cfg-version/dhcp-server@4


cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | cpio -0pd

all-local:
	./gen-templates.pl

clean-local:
	rm -rf generated-templates

install-exec-hook:
	mkdir -p $(DESTDIR)$(cfgdir)
	cd templates; $(cpiop) $(DESTDIR)$(cfgdir) ; cd ..
	cd generated-templates; $(cpiop) $(DESTDIR)$(cfgdir) ; cd ..
