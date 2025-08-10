# dto_admin
Hier werden Playbooks gesammelt, die einen Remote Client manipulieren können.
Zuerst möchte ich einen Client remote updaten und den user "ironscope" anlegen.

## Verwendung

Das Inventory `inventory/hosts.ini` beinhaltet den Zielhost `192.168.188.121` und nutzt den Benutzer `root` für die Verbindung.

Das Playbook `dto_user.yml` legt den Benutzer `ironscope` an, erstellt ein Homeverzeichnis,
fügt ihn der Gruppe `sudo` hinzu und erzwingt eine Passwortänderung beim ersten Login.
Zunächst wird das System des Zielhosts aktualisiert. Anschließend installiert das Playbook das Paket `rclone`,
legt im Homeverzeichnis den Ordner `onedrive` an und setzt `/bin/bash` als Standardshell.
Abschließend installiert es eine farbige Prompt, die IP-Adresse, Benutzername und aktuelles Verzeichnis
in unterschiedlichen Farben anzeigt.

Playbook ausführen:

```bash
ansible-playbook -i inventory/hosts.ini dto_user.yml
```
