{% if grains['os_family'] in ['Debian', 'RedHat'] %}
remove-qubes-buskill-vm:
  pkg.removed:
    - pkgs:
      - qubes-buskill-vm
{% endif %}
