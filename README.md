# dto_admin

This repository collects Ansible playbooks that can manipulate a remote client.
Currently it provides a playbook to update a client and create the user "ironscope".

## Usage

The inventory `inventory/hosts.ini` contains the target host `192.168.188.121` and uses the user `root` for the connection.

The playbook `dto_user.yml` ensures that the user `ironscope` exists, creates a home directory,
adds the user to the `sudo` group and forces a password change at the first login.
It then updates the target host system, installs the package `rclone`,
creates the directory `onedrive` in the home directory and sets `/bin/bash` as the default shell.
Finally, it installs a colorful prompt that displays IP address, username and current directory
in different colors.

Run the playbook:

```bash
ansible-playbook -i inventory/hosts.ini dto_user.yml
```

## Versioning

Current version: 0.1.0-beta. A stable 1.0.0 release will be defined in the future.
