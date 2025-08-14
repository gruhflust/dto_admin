# dto_admin

## Überblick (Deutsch)

Dieses Repository enthält eine Sammlung von Ansible‑Playbooks zur Verwaltung
entfernter Linux‑Rechner sowie zur Automatisierung von Proxmox‑Hosts.

### Voraussetzungen
- Passwortloser SSH‑Zugang als `root` zu allen Zielsystemen
- Installiertes [Ansible](https://www.ansible.com/) auf dem Administrationsrechner

### Inventory
Das Inventory `inventory/hosts.ini` definiert sowohl klassische Linux‑Hosts als
auch mehrere Proxmox‑Server. Alle Verbindungen erfolgen als Benutzer `root`.

### Playbooks

#### Benutzerverwaltung
- `dto_user.yml` legt den Benutzer `ironscope` an, fügt ihn der passenden
  Administrationsgruppe hinzu, erzwingt beim ersten Login ein Passwort‑Update
  und installiert Werkzeuge wie `rclone` sowie eine farbige Shell‑Prompt.
- `dto_userhome.yml` richtet das Home‑Verzeichnis von `ironscope` ein,
  inklusive `onedrive`‑Ordner und einer aus `templates/bashrc.j2`
  generierten `.bashrc`.

#### Proxmox‑Playbooks
- `dto_proxreport.yml` ermittelt Storage‑Status, Netzwerk‑ und Hardware‑Daten
  und erzeugt aus den Vorlagen `templates/proxmox_summary.md.j2` und
  `templates/proxmox_summary.html.j2` einen Bericht `proxmox-summary.pdf`.
- `dto_proxcomfort.yml` entfernt den Subskriptionshinweis auf einem
  Proxmox‑Host und installiert eine farbige Prompt für `root`.
- `dto_proxstorage.yml` richtet zusätzlichen LVM‑Thin‑Storage ein, der den
  kompletten freien Speicherplatz nutzt. Die Parameter werden pro Host in
  `templates/proxstorage/<inventory_hostname>.yml.j2`
  definiert (z.B. `storage_name`, `vg_name`, `thinpool_name`).
  `dto_proxstoragedestroy.yml` macht diese Änderungen rückgängig.
- `dto_proxinvoke.yml` erstellt neue virtuelle Maschinen. Alle
  VM‑Einstellungen wie `vmid`, `name`, `target_host`, `storage`,
  `disk_size` (in GiB), `cores`, `memory` und `networks` stammen aus der
  Datei `templates/proxinvoke/<inventory_hostname>.yml.j2`.
  Die gleiche Vorlage nutzt `dto_proxrevoke.yml`, um VMs wieder zu
  entfernen.

### Ausführung

Playbooks können direkt oder über in `.bashrc` definierte Aliase
aufgerufen werden:

```bash
# direkte Ausführung
ansible-playbook -i inventory/hosts.ini dto_user.yml            # Alias: admin

# Proxmox
ansible-playbook -i inventory/hosts.ini dto_proxreport.yml      # Alias: proxreport
ansible-playbook -i inventory/hosts.ini dto_proxcomfort.yml     # Alias: proxcomfort
ansible-playbook -i inventory/hosts.ini dto_proxstorage.yml     # Alias: proxstorage
ansible-playbook -i inventory/hosts.ini dto_proxstoragedestroy.yml # Alias: proxstoragedestroy
ansible-playbook -i inventory/hosts.ini dto_proxinvoke.yml      # Alias: proxinvoke
ansible-playbook -i inventory/hosts.ini dto_proxrevoke.yml      # Alias: proxrevoke

# mittels Alias
admin
proxreport
proxcomfort
proxstorage
proxstoragedestroy
proxinvoke
proxrevoke
```

### Versionierung
Aktuelle Version: 0.1.0‑beta. Eine stabile 1.0.0‑Version wird später
veröffentlicht.

---

## Overview (English)

This repository provides Ansible playbooks for managing remote Linux
machines and automating Proxmox hosts.

### Requirements
- Passwordless SSH access as `root` to all target systems
- [Ansible](https://www.ansible.com/) installed on the control node

### Inventory
The inventory file `inventory/hosts.ini` lists both standard Linux hosts and
multiple Proxmox servers. All connections use the `root` user.

### Playbooks

#### User management
- `dto_user.yml` creates the `ironscope` user, adds it to the proper admin
  group, forces a password change on first login and installs tools like
  `rclone` along with a colourful shell prompt.
- `dto_userhome.yml` prepares the home directory of `ironscope`, including
  an `onedrive` folder and a `.bashrc` generated from `templates/bashrc.j2`.

#### Proxmox playbooks
- `dto_proxreport.yml` gathers storage, network and hardware information and
  builds `proxmox-summary.pdf` using the templates
  `templates/proxmox_summary.md.j2` and
  `templates/proxmox_summary.html.j2`.
- `dto_proxcomfort.yml` removes the subscription warning on a Proxmox host
  and installs a colourful prompt for `root`.
- `dto_proxstorage.yml` sets up additional LVM thin storage. Host specific
  parameters are stored in
  `templates/proxstorage/<inventory_hostname>.yml.j2`
  (e.g. `storage_name`, `vg_name`, `thinpool_name`).
  `dto_proxstoragedestroy.yml` reverses these changes.
- `dto_proxinvoke.yml` provisions new virtual machines. All VM parameters
  (`vmid`, `name`, `target_host`, `storage`, `disk_size` (GiB), `cores`,
  `memory`, `networks`) are loaded from
  `templates/proxinvoke/<inventory_hostname>.yml.j2`.
  The same template is used by `dto_proxrevoke.yml` to remove VMs.

### Running the playbooks

Playbooks can be executed directly or via the aliases defined in
`.bashrc`:

```bash
# direct commands
ansible-playbook -i inventory/hosts.ini dto_user.yml            # alias: admin

# Proxmox
ansible-playbook -i inventory/hosts.ini dto_proxreport.yml      # alias: proxreport
ansible-playbook -i inventory/hosts.ini dto_proxcomfort.yml     # alias: proxcomfort
ansible-playbook -i inventory/hosts.ini dto_proxstorage.yml     # alias: proxstorage
ansible-playbook -i inventory/hosts.ini dto_proxstoragedestroy.yml # alias: proxstoragedestroy
ansible-playbook -i inventory/hosts.ini dto_proxinvoke.yml      # alias: proxinvoke
ansible-playbook -i inventory/hosts.ini dto_proxrevoke.yml      # alias: proxrevoke

# using aliases
admin
proxreport
proxcomfort
proxstorage
proxstoragedestroy
proxinvoke
proxrevoke
```

### Versioning
Current version: 0.1.0-beta. A stable 1.0.0 release will be defined later.
