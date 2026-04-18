{% set usb_vm = salt['cmd.run']('/usr/bin/buskill-get-usb-qube') | trim %}
{% set guivm = salt['cmd.run']('qubes-prefs default_guivm') | trim %}

buskill-unset-on-{{ usb_vm }}:
  cmd.run:
    - name: qvm-service --unset {{ usb_vm }} buskill

{% if guivm == 'dom0' %}
buskill-remove-xfce-shortcut:
  cmd.run:
    - name: |
        USER_UID=$(id -u user 2>/dev/null)
        runuser -l user -c "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_UID}/bus \
            xfconf-query --reset -c xfce4-keyboard-shortcuts \
            -p '/commands/custom/<Primary><Shift>f'" 2>/dev/null || true

buskill-remove-kde-shortcut:
  cmd.run:
    - name: |
        for kwriteconfig in kwriteconfig6 kwriteconfig5; do
            if command -v "${kwriteconfig}" >/dev/null 2>&1; then
                runuser -l user -c "${kwriteconfig} --file kglobalshortcutsrc \
                    --group buskill-disarm.desktop \
                    --key _launch 'none,none,Disarm BusKill'" 2>/dev/null || true
                break
            fi
        done
{% else %}
buskill-remove-xfce-shortcut:
  cmd.run:
    - name: qvm-run --no-gui -u user {{ guivm }} 'USER_UID=$(id -u) && DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${USER_UID}/bus xfconf-query --reset -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Shift>f"' || true
{% endif %}
