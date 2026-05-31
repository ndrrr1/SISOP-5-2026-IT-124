#!/bin/bash
set -e

# Soal 2 build/run helper with Bochs BIOS auto-detection for Kali Linux.
# It generates bochsrc.auto.txt so your original bochsrc.txt stays as template.

find_first_existing() {
    for p in "$@"; do
        if [ -f "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

make_bochsrc_auto() {
    BIOS_PATH="$(find_first_existing \
        /usr/share/bochs/BIOS-bochs-latest \
        /usr/share/bochs/BIOS-bochs-generic \
        /usr/share/bochs/BIOS-bochs-legacy \
        /usr/share/bochs/BIOS-bochs-2-processors)" || true

    VGA_PATH="$(find_first_existing \
        /usr/share/bochs/VGABIOS-lgpl-latest \
        /usr/share/bochs/VGABIOS-lgpl-latest.bin \
        /usr/share/vgabios/vgabios.bin \
        /usr/share/vgabios/vgabios-stdvga.bin \
        /usr/share/seabios/vgabios-stdvga.bin)" || true

    if [ -z "${BIOS_PATH:-}" ]; then
        echo "[!] Bochs BIOS tidak ditemukan. Install dulu:"
        echo "    sudo apt update"
        echo "    sudo apt install bochs bochs-sdl bochs-x bochsbios vgabios"
        echo "[i] Cek manual: find /usr/share -iname 'BIOS-bochs*'"
        exit 1
    fi

    if [ -z "${VGA_PATH:-}" ]; then
        echo "[!] VGA BIOS tidak ditemukan. Install dulu:"
        echo "    sudo apt update"
        echo "    sudo apt install bochsbios vgabios"
        echo "[i] Cek manual: find /usr/share -iname '*VGABIOS*' -o -iname '*vgabios*'"
        exit 1
    fi

    DISPLAY_LIB="${BOCHS_DISPLAY:-sdl2}"

    cat > bochsrc.auto.txt <<EOF
megs: 32
romimage: file=$BIOS_PATH
vgaromimage: file=$VGA_PATH
boot: floppy
floppya: 1_44=floppy.img, status=inserted
log: bochslog.txt
mouse: enabled=0
display_library: $DISPLAY_LIB
EOF

    echo "[+] Using BIOS    : $BIOS_PATH"
    echo "[+] Using VGA BIOS: $VGA_PATH"
    echo "[+] Using display : $DISPLAY_LIB"
}

case "${1:-}" in
    --run)
        if [ ! -f floppy.img ]; then
            make build
        fi
        make_bochsrc_auto
        bochs -f bochsrc.auto.txt
        ;;
    --run-x)
        if [ ! -f floppy.img ]; then
            make build
        fi
        BOCHS_DISPLAY=x make_bochsrc_auto
        BOCHS_DISPLAY=x bochs -f bochsrc.auto.txt
        ;;
    --run-term)
        if [ ! -f floppy.img ]; then
            make build
        fi
        BOCHS_DISPLAY=term make_bochsrc_auto
        BOCHS_DISPLAY=term bochs -f bochsrc.auto.txt
        ;;
    *)
        echo "[+] Building Soal 2 from template..."
        make clean >/dev/null 2>&1 || true
        make build
        echo "[+] Done: floppy.img"
        echo "Run with: ./build.sh --run"
        echo "If SDL2 display fails: ./build.sh --run-x"
        ;;
esac
