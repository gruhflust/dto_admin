# dto_admin

This repository collects Ansible playbooks that can manipulate a remote client.
Currently it provides a playbook to update a client and create the user "ironscope".
The playbook works across common Linux distributions such as Debian/Ubuntu/Mint,
RedHat-based systems, SUSE variants and Alpine, automatically detecting the
target system and its display manager before applying changes.

## Usage

The inventory `inventory/hosts.ini` contains the Debian host `192.168.188.121` and the Proxmox host `192.168.188.150`. Both use the user `root` for the connection.

The playbook `dto_user.yml` ensures that the user `ironscope` exists, creates a home directory,
adds the user to the appropriate admin group for the detected distribution and forces a
password change at the first login.
It then updates the target host system using the correct package manager, installs the
package `rclone`, creates the directory `onedrive` in the home directory and sets `/bin/bash`
as the default shell. Finally, it installs a colorful prompt that displays IP address,
username and current directory in different colors.

The playbook `dto_proxmox.yml` disables the subscription warning on a Proxmox host by patching `/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js` and restarting the `pveproxy` service.

Run the playbook:

```bash
ansible-playbook -i inventory/hosts.ini dto_user.yml
ansible-playbook -i inventory/hosts.ini dto_proxmox.yml
```

## Versioning

Current version: 0.1.0-beta. A stable 1.0.0 release will be defined in the future.
