cfgdir		 = $(datadir)/vyatta-cfg/templates

bin_SCRIPTS =
sbin_SCRIPTS =
sysconf_DATA =

sbin_SCRIPTS += scripts/system/dhcpd-config.pl
sbin_SCRIPTS += scripts/system/dhcpd.init


cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(cfgdir)
	cd templates; $(cpiop) $(DESTDIR)$(cfgdir)

