# dto_admin
Hier werden Playbooks gesammelt, die einen Remote Client manipulieren können.
Zuerst möchte ich einen Client remote updaten und den user "dto" anlegen.

## Verwendung

Das Inventory `inventory/hosts.ini` beinhaltet den Zielhost `192.168.188.92` und nutzt den Benutzer `root` für die Verbindung.

Das Playbook `dto_user.yml` legt den Benutzer `dto` an, erstellt ein Homeverzeichnis,
fügt ihn der Gruppe `sudo` hinzu und erzwingt eine Passwortänderung beim ersten Login.

Playbook ausführen:

```bash
ansible-playbook -i inventory/hosts.ini dto_user.yml
```
