# Radio controls

The shell exposes `qs ipc call wifi toggle` and `qs ipc call bluetooth toggle`.
Both panels drop down below the bar's system controls without dimming the desktop.
They share the shell's menu state and close with Escape or an outside click.
The bar's middle-click radio shortcuts remain available.

`radioctl` uses Python GObject/Gio with the system iwd and BlueZ D-Bus services.
Keep iwd and bluetooth services enabled on the host; the panel reports unavailable
services and adapter errors. It does not change the host's IP/DNS setup.
Passwords and pairing replies use the helper's stdin, never command arguments.
Closing the panel terminates its helper and releases its agents/discovery session.

Supported actions: adapter power, scanning, connect/disconnect, Bluetooth pairing
with PIN/passkey confirmation, and forgetting saved networks or paired devices.
Enterprise Wi-Fi must first be provisioned in iwd; hidden SSID provisioning is not
currently exposed. Scan again to refresh discovery results.

API references:
- https://kernel.googlesource.com/pub/scm/network/wireless/iwd/+/master/doc/
- https://bluez.readthedocs.io/en/latest/agent-api/

Run `python3 tests/radio-backend.py` from the repository for mocked backend tests.
