#!/usr/bin/env bash
# Build tgz on Host1 and copy to Host3 via one/more ProxyJump hops.
# Runs entirely on Host1. Uses scp with -o ProxyJump.
# Fill in the hop chain with *reachable* IP(s) from Host1.

# einmalig (falls Datei aus Windows kommt): Zeilenenden sichern
# sed -i 's/\r$//' /home/doeto111-misc/deployrepo_min.sh


set -euo pipefail

# --------- KONFIGURATION -------------------------------------------------------
SRC_DIR="/usr/local/drives/doeto111-misc/C:/temp/dto_admin"
ARCHIVE="$HOME/dto_admin.tgz"

# Proxy-Jump-Kette (vom Host1 ERREICHBARE IPs, pro Hop "user@ip", kommasepariert)
# Vermutung aus deiner Topologie: Host2 ist von Host1 aus eher über 10.200.133.151 erreichbar.
JUMP_CHAIN="olr@10.200.133.151"     # Beispiel: ein Hop (Host2). Mehr Hops: "user@IP1,user@IP2"

# Ziel
TARGET_USER="olr"
TARGET_IP="10.10.81.241"
TARGET_DIR="/home/olr"
# -----------------------------------------------------------------------------

log(){ printf '[*] %s\n' "$*"; }
ok(){  printf '[+] %s\n' "$*"; }
err(){ printf '[!] %s\n' "$*" >&2; }

# --- 0) Sanity: Quelle vorhanden?
if [[ ! -d "$SRC_DIR" ]]; then
  [[ "$SRC_DIR" == /urs/* ]] && err "Tippfehler entdeckt: '/urs/...'; gemeint: '/usr/...'"
  err "Quelle nicht gefunden: $SRC_DIR"
  exit 1
fi

# --- 1) Archiv erstellen (EXAKT wie gewünscht)
log "Erzeuge Archiv: $ARCHIVE"
tar czf "$ARCHIVE" "$SRC_DIR"
ok  "Archiv fertig."

# --- 2) Hop-Diagnose: jede Etappe prüfen
IFS=',' read -r -a HOPS <<< "$JUMP_CHAIN"
# Ziel als letzter „Hop“ zum Test anhängen
HOPS+=("${TARGET_USER}@${TARGET_IP}")

log "Prüfe Erreichbarkeit jeder Etappe (ssh -J … true):"
if ((${#HOPS[@]} == 0)); then
  err "JUMP_CHAIN ist leer – ohne direkten Pfad wird das nichts."
  exit 1
fi

# Kette progressiv aufbauen und testen
CHAIN=""
for ((i=0; i<${#HOPS[@]}-1; i++)); do
  [[ -z "$CHAIN" ]] && CHAIN="${HOPS[i]}" || CHAIN="${CHAIN},${HOPS[i]}"
  NEXT="${HOPS[i+1]}"
  printf '   - '
  echo "ssh -o ProxyJump='$CHAIN' '$NEXT' true"
  if ! ssh -o BatchMode=yes -o ConnectTimeout=6 -o ProxyJump="$CHAIN" "$NEXT" true 2>/tmp/pushpull_ssh_err.$$; then
    err "Hop fehlgeschlagen: → $NEXT"
    echo "---- ssh-Fehler ----"; cat /tmp/pushpull_ssh_err.$$; echo "--------------------"
    err "Tipps: 1) Prüfe, ob diese IP von Host1 aus *routbar* ist."
    err "      2) Nutze die alternative Host2-IP 10.200.133.151 statt 10.10.81.231 (sofern erreichbar)."
    err "      3) 'ip r' und 'tracepath -n <IP>' auf Host1 prüfen."
    exit 2
  fi
done
ok "SSH-Route steht."

# --- 3) Zielverzeichnis erstellen
log "Erzeuge Zielpfad auf ${TARGET_IP}:${TARGET_DIR}"
ssh -o ProxyJump="$JUMP_CHAIN" "${TARGET_USER}@${TARGET_IP}" "mkdir -p '$(printf %q "$TARGET_DIR")'"

# --- 4) scp-Transfer mit ProxyJump
log "Übertrage Archiv via scp …"
scp -o ProxyJump="$JUMP_CHAIN" "$ARCHIVE" "${TARGET_USER}@${TARGET_IP}:${TARGET_DIR}/"

ok "Fertig: ${TARGET_IP}:${TARGET_DIR}/$(basename "$ARCHIVE")"
