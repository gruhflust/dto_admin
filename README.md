# dto_admin

This repository collects Ansible playbooks that can manipulate a remote client.
Currently it provides a playbook to update a client and create the user "ironscope".
The playbook works across common Linux distributions such as Debian/Ubuntu/Mint,
RedHat-based systems, SUSE variants and Alpine, automatically detecting the
target system and its display manager before applying changes.

## Usage

The inventory `inventory/hosts.ini` contains the Debian host `192.168.188.121` and the Proxmox host `192.168.188.150`. Both use
the user `root` for the connection.

### User management

The playbook `dto_user.yml` ensures that the user `ironscope` exists, creates a home directory,
adds the user to the appropriate admin group for the detected distribution and forces a
password change at the first login.
It then updates the target host system using the correct package manager, installs the
package `rclone`, creates the directory `onedrive` in the home directory and sets `/bin/bash`
as the default shell. Finally, it installs a colorful prompt that displays IP address,
username and current directory in different colors.

### Proxmox playbooks

The playbook `dto_proxstat.yml` displays storage status, network configuration, IP addresses,
block devices, hardware details, the system uptime and the Proxmox version. It also lists
virtual machines and generates `proxmox-summary.pdf` which summarises this information for
each queried server on its own page and includes the report creation date.
It ensures the `lshw` package is installed so hardware details can be collected.


The playbook `dto_proxcomfort.yml` disables the subscription warning on a Proxmox host by
patching `/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js` and restarting the
`pveproxy` service. It also installs a colourful prompt for the root user.

The playbook `dto_proxstor.yml` prepares additional LVM storage on a Proxmox host. It locates
the first unused block device, creates a volume group and a thin pool that spans the entire
device and provisions several thin volumes. Parameters such as the volume group name, thin
pool and thin volume sizes are defined in host-specific Jinja files under `templates/proxstor`
and can be adjusted per target host. After execution the playbook prints a summary of the
available Proxmox storages. Running the playbook again will recognise an existing volume group
and simply report the current status without failing.

The playbook also writes a matching entry to `/etc/pve/storage.cfg` and restarts the
`pvedaemon` and `pveproxy` services so that Proxmox recognises the new storage.

The complementary playbook `dto_proxdestroystor.yml` removes the storage entry, the thin
volumes, the thin pool and the volume group again, undoing the changes made by
`dto_proxstor.yml`.

Run the playbooks either directly or via the convenience aliases defined in `.bashrc`:

```bash
# direct commands
ansible-playbook -i inventory/hosts.ini dto_user.yml            # alias: admin

# Proxmox
ansible-playbook -i inventory/hosts.ini dto_proxstat.yml        # alias: proxstat
ansible-playbook -i inventory/hosts.ini dto_proxcomfort.yml     # alias: proxcomfort
ansible-playbook -i inventory/hosts.ini dto_proxstor.yml        # alias: proxstor
ansible-playbook -i inventory/hosts.ini dto_proxdestroystor.yml # alias: proxdestroystor

# using aliases
admin
proxstat
proxcomfort
proxstor
proxdestroystor
```

## Versioning

Current version: 0.1.0-beta. A stable 1.0.0 release will be defined in the future.
