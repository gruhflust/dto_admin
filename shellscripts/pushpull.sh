#!/usr/bin/env bash
# Build & send dto_admin.tgz from Host1 -> (Jump) -> Host3 using scp
# Run on Host1. Uses user 'olr' für die SSH-Verbindungen.
# einmalig (falls Datei aus Windows kommt): Zeilenenden sichern
# sed -i 's/\r$//' /home/doeto111-misc/deployrepo_min.sh

set -euo pipefail

# --- Konfig ---
SRC="/usr/local/drives/doeto111-misc/C:/temp/dto_admin"
ARCHIVE="$HOME/dto_admin.tgz"

JUMP_IP="10.10.81.231"   # Zwischenhost (Host2)
TARGET_IP="10.10.81.241" # Zielhost (Host3)
TARGET_DIR="/home/olr"   # Zielverzeichnis auf Host3
USER_REMOTE="olr"        # Remote-User (auf Jump & Ziel)

# --- Checks ---
if [[ ! -d "$SRC" ]]; then
  [[ "$SRC" == /urs/* ]] && echo "[!] Tippfehler? '/urs/...' statt '/usr/...'" >&2
  echo "[!] Quelle nicht gefunden: $SRC" >&2
  exit 1
fi
command -v tar >/dev/null || { echo "[!] tar fehlt"; exit 1; }
command -v scp >/dev/null || { echo "[!] scp fehlt"; exit 1; }

# --- 1) Archiv erstellen (genau wie gewünscht) ---
echo "[*] Erzeuge Archiv: $ARCHIVE"
tar czf "$ARCHIVE" "$SRC"

# --- 2) Zielverzeichnis anlegen (über Jump) ---
echo "[*] Erzeuge Zielpfad auf $TARGET_IP:$TARGET_DIR"
ssh -o "ProxyJump=${USER_REMOTE}@${JUMP_IP}" "${USER_REMOTE}@${TARGET_IP}" \
  "mkdir -p '$(printf %q "$TARGET_DIR")'"

# --- 3) scp-Transfer mit ProxyJump ---
echo "[*] Übertrage Archiv via scp …"
scp -o "ProxyJump=${USER_REMOTE}@${JUMP_IP}" \
    "$ARCHIVE" "${USER_REMOTE}@${TARGET_IP}:${TARGET_DIR}/"

echo "[+] Fertig: ${TARGET_IP}:${TARGET_DIR}/$(basename "$ARCHIVE")"

