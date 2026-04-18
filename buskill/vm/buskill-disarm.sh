#!/usr/bin/env bash

################################################################################
# File:    @USB_VM@:/usr/bin/buskill-disarm.sh
# Purpose: Temp disarm BusKill. For more info, see: https://buskill.in/qubes-os/
# Authors: Tom <humandecoded.io>
# Co-Auth: Michael Altfield <michael@buskill.in>
# Created: 2023-05-10
# License: GNU GPLv3
################################################################################

export XDG_RUNTIME_DIR="/run/user/$(id user -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# replace the 'shutdown' trigger with the 'lock' trigger
rm /etc/udev/rules.d/buskill.rules
ln -s /etc/buskill/buskill.lock.rules /etc/udev/rules.d/buskill.rules
udevadm control --reload

# let the user know that BusKill is now temporarily disarmed
sudo -E -u user notify-send -t 21000 "BusKill" "Disarmed for 30 seconds" -i changes-allow

# wait 30 seconds
sleep 30

# replace the 'lock' trigger with the 'shutdown' trigger
rm /etc/udev/rules.d/buskill.rules
ln -s /etc/buskill/buskill.rules /etc/udev/rules.d/buskill.rules
udevadm control --reload
sudo -E -u user notify-send -t 5000 "BusKill" "BusKill is Armed" -i changes-prevent
