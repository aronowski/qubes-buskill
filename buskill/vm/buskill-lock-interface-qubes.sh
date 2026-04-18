#!/usr/bin/env bash

set -euo pipefail

/usr/bin/qrexec-client-vm @default qubes.HostState.Set+lock-screen

POSSIBLE_GUIVMS=("sys-gui" "sys-gui-vnc" "sys-gui-gpu")
set +e
for guivm in "${POSSIBLE_GUIVMS[@]}"; do
    /usr/bin/qrexec-client-vm "$guivm" qubes.LockScreen+lock-screen
done
set -e
