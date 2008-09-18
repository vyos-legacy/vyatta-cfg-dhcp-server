cfgdir		 = $(datadir)/vyatta-cfg/templates

sbin_SCRIPTS =

sbin_SCRIPTS += scripts/system/dhcpd-config.pl
sbin_SCRIPTS += scripts/system/dhcpd.init

curverdir = $(sysconfdir)/config-migrate/current
curver_DATA = cfg-version/dhcp-server@4


cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(cfgdir)
	cd templates; $(cpiop) $(DESTDIR)$(cfgdir)
