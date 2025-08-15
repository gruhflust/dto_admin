#!/usr/bin/env bash
#
# ova2proxmox.sh — Importiert eine extrahierte OVA/OVF (VMDK+OVF) als VM auf Proxmox
# Usage: sudo ./ova2proxmox.sh /pfad/zur/ovf-dir 105 local-lvm
#
set -Eeuo pipefail

log()   { printf "[%(%F %T)T] [INFO] %s\n" -1 "$*"; }
warn()  { printf "[%(%F %T)T] [WARN] %s\n" -1 "$*" >&2; }
err()   { printf "[%(%F %T)T] [ERR ] %s\n"  -1 "$*" >&2; exit 1; }
on_exit(){ rc=$?; [[ $rc -eq 0 ]] || warn "Abbruch mit Exit-Code $rc"; }
trap on_exit EXIT

# --- Parameter ---------------------------------------------------------------
if [[ $# -ne 3 ]]; then
  cat >&2 <<USAGE
Usage: $0 <OVF_DIR> <VMID> <STORAGE>
  <OVF_DIR>  : Verzeichnis, das .ovf/.vmdk (aus OVA extrahiert) enthält
  <VMID>     : Ziel-VMID (z. B. 105)
  <STORAGE>  : Proxmox-Storage-Name (z. B. local-lvm, local, zfs, ceph-...)
Beispiel: $0 /mnt/spec/debian-small 105 local-lvm
USAGE
  exit 2
fi
OVF_DIR="$1"
VMID="$2"
STORAGE="$3"

# --- Vorprüfungen ------------------------------------------------------------
command -v qm        >/dev/null || err "qm nicht gefunden – bitte auf einem Proxmox-Host ausführen."
command -v qemu-img  >/dev/null || err "qemu-img nicht gefunden."
command -v pvesm     >/dev/null || err "pvesm nicht gefunden."

[[ -d "$OVF_DIR" ]] || err "OVF-Verzeichnis nicht gefunden: $OVF_DIR"

# Storage prüfen
if ! pvesm status | awk 'NR>1{print $1}' | grep -qx "$STORAGE"; then
  err "Storage '$STORAGE' existiert nicht. 'pvesm status' prüfen."
fi

# OVF/VMDK ermitteln
shopt -s nullglob
mapfile -t OVF_FILES < <(ls -1 "$OVF_DIR"/*.ovf 2>/dev/null || true)
mapfile -t VMDK_FILES < <(ls -1 "$OVF_DIR"/*.vmdk 2>/dev/null || true)
[[ ${#VMDK_FILES[@]} -ge 1 ]] || err "Keine .vmdk in $OVF_DIR gefunden."
[[ ${#OVF_FILES[@]} -ge 1 ]] || warn "Keine .ovf gefunden – fahre mit Defaults fort."

# Nimm die größte VMDK (falls mehrere)
VMDK_FILE="$(ls -1S "$OVF_DIR"/*.vmdk | head -n1)"
log "Verwende VMDK: $VMDK_FILE"

OVF_FILE="${OVF_FILES[0]:-}"
VM_NAME="${OVF_DIR##*/}" # Default: Verzeichnisname
MEM_MB=2048
CPUS=2

# Versuche optionale Werte aus der OVF zu lesen (best effort)
if [[ -n "$OVF_FILE" ]]; then
  log "OVF gefunden: $OVF_FILE (lese optionale Werte)…"
  # Name
  if NAME_FROM_OVF=$(grep -oPm1 '(?<=<VirtualSystem ovf:name=")[^"]+' "$OVF_FILE" || true); then
    VM_NAME="${NAME_FROM_OVF// /-}"
  fi
  # Memory in MB
  if MEM_FROM_OVF=$(grep -oPm1 '<rasd:ResourceType>4</rasd:ResourceType>.*?<rasd:VirtualQuantity>\K[0-9]+' -z "$OVF_FILE" 2>/dev/null | tr -d '\0' | tail -n1); then
    [[ -n "$MEM_FROM_OVF" ]] && MEM_MB="$MEM_FROM_OVF"
  fi
  # vCPUs
  if CPU_FROM_OVF=$(grep -oPm1 '<rasd:ResourceType>3</rasd:ResourceType>.*?<rasd:VirtualQuantity>\K[0-9]+' -z "$OVF_FILE" 2>/dev/null | tr -d '\0' | tail -n1); then
    [[ -n "$CPU_FROM_OVF" ]] && CPUS="$CPU_FROM_OVF"
  fi
fi

log "Ziel: VMID=$VMID, Name=$VM_NAME, Storage=$STORAGE, RAM=${MEM_MB}MB, vCPU=${CPUS}"

# --- Idempotenz: existiert VM schon? ----------------------------------------
if qm status "$VMID" &>/dev/null; then
  err "Es existiert bereits eine VM mit ID $VMID. Bitte andere VMID wählen oder erst löschen."
fi

# --- VM-Gerüst erzeugen (ohne Disk) -----------------------------------------
log "Erzeuge leere VM-Konfiguration…"
qm create "$VMID" --name "$VM_NAME" --memory "$MEM_MB" --cores "$CPUS" \
  --net0 virtio,bridge=vmbr0 --ostype l26

# --- VMDK -> QCOW2 konvertieren (robust) ------------------------------------
QCOW2="$OVF_DIR/vm-${VMID}-import.qcow2"
if [[ -f "$QCOW2" ]]; then
  log "QCOW2 existiert bereits: $QCOW2 (überspringe Konvertierung)"
else
  log "Konvertiere VMDK nach QCOW2 (kann je nach Größe dauern)…"
  qemu-img convert -p -f vmdk "$VMDK_FILE" -O qcow2 "$QCOW2"
fi

# --- Disk in den Storage importieren ----------------------------------------
log "Importiere Disk in Storage '$STORAGE'…"
# Hinweis: qm importdisk funktioniert mit dir, lvmthin, zfs, ceph etc.
qm importdisk "$VMID" "$QCOW2" "$STORAGE" --format qcow2

# Volume-Name heuristisch bestimmen (erste Disk = -disk-0)
VOL_ID="${STORAGE}:vm-${VMID}-disk-0"

# Prüfen, ob das Volume tatsächlich existiert; wenn nicht: neu ermitteln
if ! pvesm path "$VOL_ID" &>/dev/null; then
  # Fallback: jüngstes Volume des VMID auf dem Storage ermitteln
  CANDIDATE=$(pvesm list "$STORAGE" | awk -v id="$VMID" '$0 ~ ("vm-"id"-disk-"){print $1}' | tail -n1)
  [[ -n "${CANDIDATE:-}" ]] && VOL_ID="${STORAGE}:${CANDIDATE}"
fi

pvesm path "$VOL_ID" >/dev/null 2>&1 || err "Konnte importiertes Volume nicht finden (gesucht: $VOL_ID). Prüfe 'pvesm list $STORAGE'."

# --- Disk anhängen & Boot-Reihenfolge setzen --------------------------------
log "Hänge Disk als scsi0 an und setze Bootorder…"
qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$VOL_ID"
qm set "$VMID" --boot order=scsi0

# Optional: SCSI-Controller-Queueing optimieren (harmlos, kann man weglassen)
qm set "$VMID" --aio io_uring || true

log "Fertig. Die VM wurde erstellt, aber NICHT gestartet."
log "VM anzeigen:   qm config $VMID"
log "Start (manuell): qm start $VMID"
