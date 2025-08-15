#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# deployrepo.sh  —  Direct copy Host1 -> Host3 via Host2 using tar|ssh|tar
# Run on: Host1
# User:    olr (auf allen Hosts vorhanden)
# Copy:    /usr/local/drives/doeto111-misc/C:/temp/dto_admin  ->  Host3:/home/olr/dto_admin
# Hops:    ProxyJump über IP(s), keine Namensauflösung nötig
# -----------------------------------------------------------------------------
set -euo pipefail

### ====== [CONFIG] IPs, Pfade, Optionen anpassen ===============================
USER_NAME="olr"

# Zielhost (Host3)
TARGET_IP="10.10.81.241"          # <-- IP aus deinem Bild 3

# Zwischenhost-Kette (Host2, mehrere Hops per Komma)
JUMP_CHAIN="10.10.81.231"         # <-- IP aus deinem Bild 2; mehrere: "IP1,IP2"

# Quelle (Host1 – dieser Rechner)
SRC_DIR="/usr/local/drives/doeto111-misc/C:/temp/dto_admin"

# Zielpfad auf Host3
DST_DIR="/home/olr/dto_admin"

# Dry-Run nur anzeigen (true/false)
DRY_RUN=false

# Zu ignorierende Dateien/Ordner
EXCLUDES=(
  ".git/"
  "*.pyc"
  ".DS_Store"
  "Thumbs.db"
)
### ====== [/CONFIG] ============================================================

# ---- Logging helpers ----------------------------------------------------------
log() { printf '[*] %s\n' "$*"; }
ok()  { printf '[+] %s\n' "$*"; }
err() { printf '[!] %s\n' "$*" >&2; }

# ---- Vorab-Checks -------------------------------------------------------------
# 1) Häufiger Tippfehler /urs vs /usr
if [[ ! -d "$SRC_DIR" ]]; then
  if [[ "$SRC_DIR" == /urs/* ]]; then
    err "Pfad beginnt mit /urs/... — meintest du /usr/... ?"
  fi
  err "Quelle nicht gefunden: $SRC_DIR"
  exit 1
fi

# 2) Tools
command -v ssh >/dev/null 2>&1 || { err "ssh fehlt"; exit 1; }
command -v tar >/dev/null 2>&1 || { err "tar fehlt"; exit 1; }

# 3) ProxyJump-Option aus IP-Kette bauen
build_proxyjump_opt() {
  if [[ -z "${JUMP_CHAIN}" ]]; then
    echo ""
  else
    local hops with_user=()
    IFS=',' read -r -a hops <<< "${JUMP_CHAIN}"
    for ip in "${hops[@]}"; do
      with_user+=("${USER_NAME}@${ip}")
    done
    echo "-o ProxyJump=$(IFS=,; echo "${with_user[*]}")"
  fi
}
PJ_OPT="$(build_proxyjump_opt)"

# 4) Zielverzeichnis vorbereiten
log "Erzeuge Zielpfad auf ${TARGET_IP}: ${DST_DIR}"
if $DRY_RUN; then
  echo "ssh ${PJ_OPT:+$PJ_OPT }${USER_NAME}@${TARGET_IP} mkdir -p '$(printf %q "$DST_DIR")'"
else
  ssh ${PJ_OPT:+$PJ_OPT } "${USER_NAME}@${TARGET_IP}" "mkdir -p '$(printf %q "$DST_DIR")'"
fi
ok "SSH-Verbindung/Hop-Kette ok."

# ---- Transfer vorbereiten -----------------------------------------------------
PARENT_DIR="$(dirname "$SRC_DIR")"  # /usr/local/drives/doeto111-misc/C:/temp
BASE_NAME="$(basename "$SRC_DIR")"  # dto_admin

# Excludes für tar
TAR_EXCLUDES=()
for e in "${EXCLUDES[@]}"; do
  TAR_EXCLUDES+=( "--exclude=$e" )
done

# ---- Start Transfer (tar -> ssh -> tar) --------------------------------------
log "Starte Stream Host1 -> (${JUMP_CHAIN:-kein Hop}) -> ${TARGET_IP}"
log "Excludes: ${EXCLUDES[*]:-(keine)}"

if $DRY_RUN; then
  cat <<EOF
tar -C '$(printf %q "$PARENT_DIR")' -cpf - '$(printf %q "$BASE_NAME")' ${TAR_EXCLUDES[*]} \
| ssh ${PJ_OPT:+$PJ_OPT } ${USER_NAME}@${TARGET_IP} "tar -xpf - -C '$(printf %q "$DST_DIR")'"
EOF
else
  tar -C "$PARENT_DIR" -cpf - "$BASE_NAME" "${TAR_EXCLUDES[@]}" \
  | ssh ${PJ_OPT:+$PJ_OPT } "${USER_NAME}@${TARGET_IP}" "tar -xpf - -C '$(printf %q "$DST_DIR")'"
fi

ok "Transfer abgeschlossen: ${TARGET_IP}:${DST_DIR}"
