SYSLIBDIR ?= /lib
export SYSLIBDIR

install-meta:
	install -m 664 -D README.md $(DESTDIR)/usr/share/doc/buskill/README.md

install-dom0:
	install -m 644 -D buskill/dom0/buskill-disarm.desktop $(DESTDIR)/usr/share/applications/buskill-disarm.desktop
	install -m 644 -D buskill/dom0/i3/buskill.conf $(DESTDIR)/etc/i3/config.d/buskill.conf
	install -m 664 -D buskill/dom0/policy/80-buskill.policy $(DESTDIR)/etc/qubes/policy.d/80-buskill.policy
	install -m 775 -D buskill/dom0/rpc/qubes.HostState.Set $(DESTDIR)/etc/qubes-rpc/qubes.HostState.Set
	install -m 775 -D buskill/dom0/rpc/buskill.selfDestruct $(DESTDIR)/etc/qubes-rpc/buskill.selfDestruct
	install -m 775 -D buskill/dom0/rpc/buskill.setTriggerTo $(DESTDIR)/etc/qubes-rpc/buskill.setTriggerTo
	install -m 775 -D buskill/dom0/buskill-get-usb-qube $(DESTDIR)/usr/bin/buskill-get-usb-qube
	install -m 775 -D buskill/dom0/buskill-selfdestruct $(DESTDIR)/usr/bin/buskill-selfdestruct
	install -m 644 -D buskill/dom0/salt/buskill.sls $(DESTDIR)/srv/salt/buskill.sls
	install -m 644 -D buskill/dom0/salt/buskill-uninstall.sls $(DESTDIR)/srv/salt/buskill-uninstall.sls
	install -m 644 -D buskill/dom0/salt/buskill-dom0.sls $(DESTDIR)/srv/salt/buskill-dom0.sls
	install -m 644 -D buskill/dom0/salt/buskill-dom0-uninstall.sls $(DESTDIR)/srv/salt/buskill-dom0-uninstall.sls
	install -m 644 -D buskill/dom0/salt/buskill.top $(DESTDIR)/srv/salt/buskill.top
	install -m 775 -D contrib/buskill-selfdestruct-diag $(DESTDIR)/usr/bin/buskill-selfdestruct-diag
	install -m 775 -D buskill/dom0/buskill-set-trigger-to $(DESTDIR)/usr/bin/buskill-set-trigger-to

install-vm:
	install -m 775 -D buskill/vm/buskill-disarm.sh $(DESTDIR)/usr/bin/buskill-disarm.sh
	install -m 775 -D buskill/vm/buskill-lock-interface-qubes.sh $(DESTDIR)/usr/bin/buskill-lock-interface-qubes.sh
	install -m 664 -D buskill/vm/udev-rules/buskill.rules $(DESTDIR)/etc/buskill/buskill.rules
	install -m 664 -D buskill/vm/udev-rules/buskill.lock.rules $(DESTDIR)/etc/buskill/buskill.lock.rules
	install -m 664 -D buskill/vm/buskill.service $(DESTDIR)$(SYSLIBDIR)/systemd/system/buskill.service
	install -m 664 -D buskill/vm/80-buskill.preset $(DESTDIR)$(SYSLIBDIR)/systemd/system-preset/80-buskill.preset
	install -m 775 -D buskill/vm/rpc/qubes.LockScreen $(DESTDIR)/etc/qubes-rpc/qubes.LockScreen
	install -m 775 -D buskill/vm/rpc/buskill.Disarm $(DESTDIR)/etc/qubes-rpc/buskill.Disarm
	install -m 775 -D buskill/vm/rpc/buskill.Disarm.config $(DESTDIR)/etc/qubes/rpc-config/buskill.Disarm
	install -m 644 -D buskill/vm/buskill-disarm.desktop $(DESTDIR)/usr/share/applications/buskill-disarm.desktop
	install -m 775 -D buskill/vm/buskill-update-udev-rules $(DESTDIR)/usr/bin/buskill-update-udev-rules
	install -m 775 -D buskill/vm/buskill-set-trigger-to $(DESTDIR)/usr/bin/buskill-set-trigger-to

clean:
	rm -rf pkgs
