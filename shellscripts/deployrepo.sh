#!/usr/bin/env bash
# copy_dto_admin_direct.sh
# Zweck: Von HOST1 (dieser Rechner) direkt zu HOST3 streamen (kein Staging),
#        über einen oder mehrere SSH-Hops (ProxyJump), nur mit tar/ssh.
# Ausführen auf: HOST1
# Voraussetzung: SSH-Key-Login als 'olr' von HOST1 -> Hops -> HOST3.
# Hinweis: rsync wird NICHT benötigt. Nur tar & ssh auf den beteiligten Hosts.

set -euo pipefail

### ========= KONFIGURATION (ANPASSEN) ==========================================
USER_NAME="olr"

# Ziel (HOST3) – IP-Adresse
TARGET_IP="10.10.81.241"          # <-- IP vom Zielhost (Bild 3)

# Hops (HOST2 …) – IP-Kette, kommasepariert. Beispiel für 2 Hops: "10.1.2.3,10.4.5.6"
# Für einen Hop einfach eine IP setzen, für keinen Hop leer lassen (nicht dein Fall).
JUMP_CHAIN="10.10.81.231"         # <-- IP vom Zwischenhost (Bild 2)

# Quelle (auf HOST1)
SRC_DIR="/usr/local/drives/doeto111-misc/C:/temp/dto_admin"

# Zielpfad (auf HOST3)
DST_DIR="/home/olr/dto_admin"

# Optional: Testlauf ohne Schreiben
DRY_RUN=false

# Excludes (werden NICHT übertragen)
EXCLUDES=(
  ".git/"
  "*.pyc"
  ".DS_Store"
  "Thumbs.db"
)
### ========= ENDE KONFIGURATION ===============================================

# -- Hilfsfunktionen -----------------------------------------------------------
join_by() { local IFS="$1"; shift; echo "$*"; }

build_proxyjump_opt() {
  # Baut die -o ProxyJump=... Option aus der IP-Kette
  if [[ -z "${JUMP_CHAIN}" ]]; then
    echo ""
  else
    local hops=()
    IFS=',' read -r -a hops <<< "${JUMP_CHAIN}"
    local with_user=()
    for ip in "${hops[@]}"; do
      with_user+=("${USER_NAME}@${ip}")
    done
    echo "-o ProxyJump=$(join_by , "${with_user[@]}")"
  fi
}

# -- Vorbereitungen ------------------------------------------------------------
if [[ ! -d "$SRC_DIR" ]]; then
  echo "Quelle nicht gefunden: $SRC_DIR" >&2
  exit 1
fi

PARENT_DIR="$(dirname "$SRC_DIR")"
BASE_NAME="$(basename "$SRC_DIR")"

# tar --exclude Parameter bauen
TAR_EXCLUDES=()
for e in "${EXCLUDES[@]}"; do
  TAR_EXCLUDES+=( "--exclude=$e" )
done

# ProxyJump-Option
PJ_OPT="$(build_proxyjump_opt)"

# -- Ziel vorbereiten (Remote-Verzeichnis anlegen) -----------------------------
echo "[*] Prüfe/erstelle Zielverzeichnis auf ${TARGET_IP}: ${DST_DIR}"
if $DRY_RUN; then
  echo "ssh ${PJ_OPT:+$PJ_OPT }${USER_NAME}@${TARGET_IP} \"mkdir -p '$(printf %q "$DST_DIR")'\""
else
  ssh ${PJ_OPT:+$PJ_OPT } "${USER_NAME}@${TARGET_IP}" "mkdir -p '$(printf %q "$DST_DIR")'"
fi

# -- Transfer: tar (Quelle) -> ssh (Hops) -> tar (Ziel) ------------------------
echo "[*] Starte Stream von HOST1 → (${JUMP_CHAIN}) → ${TARGET_IP}"
echo "[*] Excludes: ${EXCLUDES[*]:-(keine)}"

if $DRY_RUN; then
  echo "tar -C '$(printf %q "$PARENT_DIR")' -cpf - '$(printf %q "$BASE_NAME")' ${TAR_EXCLUDES[*]} \
| ssh ${PJ_OPT:+$PJ_OPT } ${USER_NAME}@${TARGET_IP} \"tar -xpf - -C '$(printf %q "$DST_DIR")'\""
else
  tar -C "$PARENT_DIR" -cpf - "$BASE_NAME" "${TAR_EXCLUDES[@]}" \
  | ssh ${PJ_OPT:+$PJ_OPT } "${USER_NAME}@${TARGET_IP}" "tar -xpf - -C '$(printf %q "$DST_DIR")'"
fi

echo "[✓] Transfer abgeschlossen: ${TARGET_IP}:${DST_DIR}"
