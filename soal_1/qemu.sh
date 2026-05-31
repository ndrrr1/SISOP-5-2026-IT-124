#!/bin/bash
set -euo pipefail

MODE="${1:-}"
DISPLAY_MODE="${2:---gui}"

if [ -z "$MODE" ]; then
    echo "Usage:"
    echo "  ./qemu.sh --single [--gui|--serial]"
    echo "  ./qemu.sh --multi  [--gui|--serial]"
    echo "  ./qemu.sh --all    [--gui|--serial]"
    exit 1
fi

NET_ARGS=(-nic user,model=e1000)

if [ "$DISPLAY_MODE" = "--serial" ]; then
    DISP_ARGS=(-nographic)
    APPEND_CONSOLE="console=ttyS0,115200"
else
    DISP_ARGS=(-display gtk -vga std)
    APPEND_CONSOLE="console=tty0"
fi

case "$MODE" in
    --single)
        [ -f osboot/bzImage ] || { echo "Missing osboot/bzImage. Run ./kernel.sh"; exit 1; }
        [ -f osboot/single.gz ] || { echo "Missing osboot/single.gz. Run ./single.sh"; exit 1; }
        qemu-system-x86_64 \
            -m 512M \
            -kernel osboot/bzImage \
            -initrd osboot/single.gz \
            -append "$APPEND_CONSOLE" \
            "${DISP_ARGS[@]}" \
            "${NET_ARGS[@]}"
        ;;
    --multi)
        [ -f osboot/bzImage ] || { echo "Missing osboot/bzImage. Run ./kernel.sh"; exit 1; }
        [ -f osboot/multi.gz ] || { echo "Missing osboot/multi.gz. Run ./multi.sh"; exit 1; }
        qemu-system-x86_64 \
            -m 512M \
            -kernel osboot/bzImage \
            -initrd osboot/multi.gz \
            -append "$APPEND_CONSOLE" \
            "${DISP_ARGS[@]}" \
            "${NET_ARGS[@]}"
        ;;
    --all)
        [ -f osboot/farewell.iso ] || { echo "Missing osboot/farewell.iso. Run ./iso.sh"; exit 1; }
        qemu-system-x86_64 \
            -m 512M \
            -cdrom osboot/farewell.iso \
            -boot d \
            "${DISP_ARGS[@]}" \
            "${NET_ARGS[@]}"
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Usage:"
        echo "  ./qemu.sh --single [--gui|--serial]"
        echo "  ./qemu.sh --multi  [--gui|--serial]"
        echo "  ./qemu.sh --all    [--gui|--serial]"
        exit 1
        ;;
esac
