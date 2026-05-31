#!/bin/bash
set -euo pipefail

ISO_DIR="iso_root"

for f in osboot/bzImage osboot/single.gz osboot/multi.gz; do
    if [ ! -f "$f" ]; then
        echo "Missing $f"
        echo "Run ./kernel.sh, ./single.sh, and ./multi.sh first."
        exit 1
    fi
done

rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/boot" "$ISO_DIR/isolinux"

cp osboot/bzImage "$ISO_DIR/boot/bzImage"
cp osboot/single.gz "$ISO_DIR/boot/single.gz"
cp osboot/multi.gz "$ISO_DIR/boot/multi.gz"

ISOLINUX_BIN=""
for p in /usr/lib/ISOLINUX/isolinux.bin /usr/lib/syslinux/isolinux.bin; do
    if [ -f "$p" ]; then ISOLINUX_BIN="$p"; break; fi
done

if [ -z "$ISOLINUX_BIN" ]; then
    echo "isolinux.bin not found. Install: sudo apt install isolinux syslinux-common"
    exit 1
fi

cp "$ISOLINUX_BIN" "$ISO_DIR/isolinux/"

for mod in ldlinux.c32 menu.c32 libutil.c32; do
    found=""
    for p in /usr/lib/syslinux/modules/bios/$mod /usr/lib/syslinux/$mod; do
        if [ -f "$p" ]; then found="$p"; break; fi
    done
    if [ -n "$found" ]; then cp "$found" "$ISO_DIR/isolinux/"; fi
done

cat > "$ISO_DIR/isolinux/isolinux.cfg" <<'EOF'
DEFAULT menu.c32
PROMPT 0
TIMEOUT 100

MENU TITLE Farewell Party OS

LABEL single
    MENU LABEL Boot single-user filesystem
    KERNEL /boot/bzImage
    APPEND initrd=/boot/single.gz console=tty0

LABEL multi
    MENU LABEL Boot multi-user filesystem
    KERNEL /boot/bzImage
    APPEND initrd=/boot/multi.gz console=tty0
EOF

xorriso -as mkisofs \
    -o osboot/farewell.iso \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    "$ISO_DIR"

echo "[+] Done: osboot/farewell.iso"
