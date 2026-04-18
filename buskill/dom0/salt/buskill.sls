{% set usb_vm = pillar.get('usb_vm', '') %}

# No need to check for os_family here, because the logic responsible for
# installing in supported TemplateVMs (Debian and Fedora) is in
# buskill-dom0.spec.in.
install-qubes-buskill-vm:
  pkg.installed:
    - pkgs:
      - qubes-buskill-vm

{% if usb_vm %}
{% for path in [
    '/usr/share/applications/buskill-disarm.desktop',
    '/usr/bin/buskill-disarm.sh',
    '/etc/buskill/buskill.rules',
    '/etc/buskill/buskill.lock.rules',
] %}
buskill-fix-{{ path }}:
  file.replace:
    - name: {{ path }}
    - pattern: '@USB_VM@'
    - repl: '{{ usb_vm }}'
    - require:
      - pkg: install-qubes-buskill-vm
{% endfor %}
{% endif %}
