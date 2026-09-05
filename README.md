# BusKill for Qubes OS

## What is BusKill?

BusKill is a dead man's switch designed to protect your computer if it is
physically seized. You connect one end of a USB cable to your laptop and attach
the other end to your body (e.g. a belt loop). If someone snatches your laptop
and runs, the cable disconnects and BusKill automatically triggers a security
response: locking the screen, rebooting, or destroying encryption keys, before
an attacker can access your data.

For more information about BusKill, visit https://www.buskill.in/.

## What is this repository?

This repository provides files to build the Qubes OS packages that integrate
BusKill into the Qubes security model. BusKill runs inside the USB qube
(detected during the installation phase) so that udev events generated when the
cable disconnects are handled in an isolated domain. The trigger communicates
back to dom0 via Qubes RPC to take the configured action.

The following packages are built:

- `qubes-buskill-dom0`: files for dom0: Salt formulas, RPC endpoints, udev
  rules, desktop shortcuts, and keyboard bindings for disarming BusKill, as
  well as orchestration of the installation across dom0, TemplateVMs, and
  setting up the USB qube via Salt.
- `qubes-buskill-vm`: files for TemplateVMs (the USB qube and interface qubes):
  the BusKill service, udev rules, and trigger scripts,
- `buskill`: metapackage that depends on `qubes-buskill-dom0`

## Installation

### 1. Enable the Qubes OS contrib repository

BusKill is available through the Qubes OS contrib repository. Follow the
documentation at
https://doc.qubes-os.org/en/latest/user/advanced-topics/installing-contributed-packages.html
to enable it in dom0 before proceeding.

### 2. Install the metapackage

Run the command:

```shell
sudo qubes-dom0-update buskill
```

The post-install script will:

1. Enable the BusKill Salt top file and apply the dom0 Salt state, which
   enables the BusKill service on the USB qube.
2. Apply the VM Salt state inside TemplateVMs, which installs
   `qubes-buskill-vm`.
3. Print a notice when complete, reminding you to restart the USB qube (or
   reboot) so the changes take effect.

After installation, restart the USB qube or reboot your computer.

## Disarming BusKill temporarily

A keyboard shortcut (`Ctrl+Shift+F`) is registered in dom0 to temporarily
disarm BusKill for 30 seconds - for example, when you need to unplug and replug
a USB device intentionally. The shortcut is configured for XFCE, KDE Plasma,
and i3wm during package installation.

## Configuring the trigger

By default, BusKill locks the screen when the cable is disconnected. You can
change this by running the `buskill-set-trigger-to` script in your interface
qube (including dom0).

To switch triggers, run it with one of the triggers as an argument:

| Trigger         | Effect                               |
|-----------------|--------------------------------------|
| `lock-screen`   | Lock screen (default)                |
| `soft-shutdown` | Graceful shutdown                    |
| `hard-reboot`   | Immediate hard reboot                |
| `self-destruct` | **Wipe LUKS keys - more info below** |

Example:

```shell
buskill-set-trigger-to soft-shutdown
```

The change is applied immediately\* and persists across your USB qube reboots,
even if it's a named disposable, [like sys-usb is by
default](https://doc.qubes-os.org/en/r4.3/user/downloading-installing-upgrading/installation-guide.html#main-configuration).
There's no need to reconfigure anything manually. The selected trigger persists
after BusKill is uninstalled - this is intentional, so a reinstallation to
reconfigure BusKill to use a different interface qube, doesn't unintentionally
reset the trigger.

\* Exception: if your USB qube is shut down when running the command, it will
start automatically, which will take a few seconds.

**Warning**: The `buskill.rules` file is the *active* trigger configuration.
The `buskill.lock.rules` file is swapped in temporarily during the 30-second
disarm window and always uses the lock-screen trigger regardless of your
permanent configuration.

**Warning**: BusKill will trigger on the removal of **any** USB device, e.g. a
flash drive, mouse or keyboard. It's recommended that:
- The [keyboard shortcut to disarm BusKill](#disarming-busKill-temporarily) be
  used for a 30-second possibility to unplug a USB device without triggering
  the security response, especially if any other response than the lock-screen
  trigger is used,
- Advanced users configure the rules to trigger only when a specific USB device
  is removed, by following [this
  guide](https://www.buskill.in/buskill-laptop-kill-cord-dead-man-switch/#software).

## Self-destruct disclaimer

**⚠ WARNING: THE SELF-DESTRUCT TRIGGER CAUSES PERMANENT, COMPLETE, AND
IRREVERSIBLE DATA LOSS.**

The self-destruct trigger (`buskill.selfDestruct`) is designed to make
encrypted data permanently unrecoverable. **There is no undo.** Once the LUKS
keyslots are overwritten, **no passphrase, recovery key, or forensic technique
can recover the encrypted data.** This includes all your qubes, and personal
files stored on that disk.

Before enabling the self-destruct trigger:

- Make sure you have current, tested backups of everything you cannot afford to
  lose, stored on a separate device,
- Test that the trigger configuration is syntactically correct by inspecting
  the rules file carefully before relying on it,
- Understand that any accidental disconnection of the BusKill cable (e.g. a
  loose connector, a bump, or pulling on the cable by mistake) will destroy all
  of your data in about 5 seconds,
- We strongly recommend that you first fully test the self-destruct trigger on
  a disposable machine containing no valuable data before relying on it.

This trigger is intended for high-threat environments where the risk of
unrecoverable data loss is preferable to the risk of an adversary accessing
your plaintext data. Do not enable it unless you have fully evaluated this
trade-off.

Please note that the self-destruct mechanism is meant to overwrite the LUKS
keyslots. This option will **not** wipe anything (and **all of your laptop's
data will remain intact, entirely exposed to an attacker that steals your
laptop**) if your laptop is configured without LUKS FDE.

## Additional disclaimers and warnings

### "Denied" notifications

Various notifications may pop-up about denied RPCs:
- `Denied admin.vm.List from fedora-43-xfce to dom0`: during the installation
  process,
- `Denied qubes.Lockscreen+lock-screen from sys-usb to sys-gui`: during the
  dead man's switch disconnecting

These are typically harmless, and appear due to not granting the permission to
list running qubes, and as a natural consequence, trying to lock all interface
qubes, even those that do not exist (listing them is not permitted to reduce
the USB qube's attack surface).

### X11 exclusive lock

The screen may not lock when the dead man's switch disconnects if a menu is
active from right-clicking on a window decoration or on the desktop, or if any
other X11 window holding an X11 exclusive lock is present.

### Desktop environment or interface qube installed after BusKill

When the BusKill packaging is installed first, then a new desktop environment
is installed, and its initial configuration is created, that initial
configuration may override the disarm hotkey. For example:

- XFCE is preinstalled
- BusKill packaging is installed, hotkeys are created for XFCE, KDE Plasma and
  i3wm
- i3wm is being installed
- the user logs out of XFCE, logs into the i3wm session and creates the i3wm
  initial configuration
- the BusKill configuration has been overwritten and disarm hotkey isn't
  present

If this happens, either reinstall the `buskill` package or setup the hotkey
manually.

The same is applicable when a new interface qube is provisioned, e.g. switching
from dom0 to sys-gui after the BusKill configuration has been deplyed.

### USB qube unresponsive or terminated

The way BusKill operates is that when the cable is disconnected, the USB qube
sends a request to dom0 to lock the screen, reboot, shut down or destroy the
LUKS header. This is **not** implemented as a heartbeat, which when stopped,
performs the security response. On the contrary, the USB qube must be
operational for the request to be sent. This may result in the following:

- If the USB qube is slow to respond, the security operation will be performed
  with a delay,
- If it's completely unresponsive or shuts down, the operation will never be
  triggered.

It's recommended to ensure that the USB qube has enough resources (assigned
memory and VCPUs) to partially mitigate the issue.

## Uninstallation

Run in dom0:

```shell
sudo dnf remove -y buskill
```

The pre-uninstall script disables the BusKill Salt top file, applies the
uninstall Salt states to remove BusKill from dom0 and the USB qube
TemplateVM, and stops any running BusKill services.

There's no need to restart the USB qube to complete the uninstallation process.

## Further Reading

- The [BusKill website](https://buskill.in) and
  [documentation](https://docs.buskill.in),
- [Using BusKill in Qubes OS](https://www.buskill.in/qubes-os/)
- [Disarming BusKill in Qubes OS and how to setup the disarm hotkey
  manually](https://www.buskill.in/qubes-disarm/)
- [Bounty to provide an official Qubes OS contrib
  package](https://www.buskill.in/qubes-package-bounty/), along with this
  README,
- [A deep dive into how the destruction of the LUKS keyslots
  works](https://www.buskill.in/luks-self-destruct/),
- [Qubes OS documentation](https://doc.qubes-os.org/), in particular:
  - [Salt in Qubes
    OS](https://doc.qubes-os.org/en/latest/user/advanced-topics/salt.html),
  - [Interface
    qubes](https://doc.qubes-os.org/en/latest/user/advanced-topics/gui-domain.html),
  - [USB
    qubes](https://doc.qubes-os.org/en/latest/user/advanced-topics/usb-qubes.html),
  - [qrexec](https://doc.qubes-os.org/en/latest/developer/services/qrexec.html)
    and [RPC
    policies](https://doc.qubes-os.org/en/latest/user/advanced-topics/rpc-policy.html),
  - [Installing contributed
    packages](https://doc.qubes-os.org/en/latest/user/advanced-topics/installing-contributed-packages.html),
  - [brief introduction to Qubes Builder
    v2](https://doc.qubes-os.org/en/latest/developer/building/qubes-builder-v2.html).

## License

Copyright (C) 2020-2026 Michael Altfield, Kamil Aronowski and the BusKill Team

The contents of this repo are under the GPL version 3 or later.
In addition, any content other than code can also be used, at your
choice, under CC-BY-SA version 4.0.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
