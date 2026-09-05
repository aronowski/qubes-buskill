{% set usb_vm = pillar.get('usb_vm') or salt['cmd.run']('/usr/bin/buskill-get-usb-qube') | trim %}
{% set guivm = salt['cmd.run']('qubes-prefs default_guivm') | trim %}

buskill-enable-on-{{ usb_vm }}:
  cmd.run:
    - name: qvm-service {{ usb_vm }} buskill on

buskill-set-default-trigger-on-{{ usb_vm }}:
  cmd.run:
    - name: qvm-features {{ usb_vm }} vm-config.buskill-trigger lock-screen
    - unless: qvm-features {{ usb_vm }} vm-config.buskill-trigger

{% if guivm == 'dom0' %}
buskill-setup-xfce-shortcut:
  cmd.run:
    - name: |
        USER_UID=$(id -u user 2>/dev/null)
        runuser -l user -c "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_UID}/bus \
            xfconf-query --create -c xfce4-keyboard-shortcuts -t string \
            -p '/commands/custom/<Primary><Shift>f' \
            -s 'gtk-launch buskill-disarm'" 2>/dev/null || true

buskill-setup-kde-shortcut:
  cmd.run:
    - name: |
        USER_UID=$(id -u user 2>/dev/null)
        for kwriteconfig in kwriteconfig6 kwriteconfig5; do
            if command -v "${kwriteconfig}" >/dev/null 2>&1; then
                runuser -l user -c "${kwriteconfig} --file kglobalshortcutsrc \
                    --group buskill-disarm.desktop \
                    --key _launch 'Ctrl+Shift+F,none,Disarm BusKill'" 2>/dev/null || true
                break
            fi
        done

buskill-setup-i3-shortcut:
  cmd.run:
    - name: |
        USER_UID=$(id -u user 2>/dev/null)
        I3_CONF="/home/user/.config/i3/config"
        if [ -f "${I3_CONF}" ] && ! grep -qF "include /etc/i3/config.d/" "${I3_CONF}"; then
            printf '\ninclude /etc/i3/config.d/*.conf\n' >> "${I3_CONF}"
        fi
{% else %}
buskill-setup-xfce-shortcut:
  cmd.run:
    - name: qvm-run --no-gui --pass-io {{ guivm }} 'USER_UID=$(id -u $(qubesdb-read /default-user)) && DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_UID}/bus xfconf-query --create -c xfce4-keyboard-shortcuts -t string -p "/commands/custom/<Primary><Shift>f" -s "gtk-launch buskill-disarm"' || true
{% endif %}
