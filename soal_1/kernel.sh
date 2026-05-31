#!/bin/bash
set -euo pipefail

KERNEL_VERSION="6.1.1"
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TAR}"
KERNEL_DIR="linux-${KERNEL_VERSION}"

mkdir -p osboot

if [ "${1:-}" = "--clean" ]; then
    echo "[+] Cleaning old kernel source..."
    rm -rf "$KERNEL_DIR"
fi

if [ ! -f "$KERNEL_TAR" ]; then
    echo "[+] Downloading Linux kernel ${KERNEL_VERSION}..."
    wget -c "$KERNEL_URL"
fi

if [ ! -d "$KERNEL_DIR" ]; then
    echo "[+] Extracting ${KERNEL_TAR}..."
    tar -xf "$KERNEL_TAR"
fi

cd "$KERNEL_DIR"

KERNEL_CC="${CC:-gcc}"
echo "[+] Compiler:"
"$KERNEL_CC" --version | head -n 1

# Compatibility for GCC 15.x building Linux kernel 6.1.1.
# The important part is patching bool/true/false definitions BEFORE any build step.
# Some realmode objects ignore normal KCFLAGS ordering, so source patching is safer.
export KCFLAGS="-std=gnu11 -Wno-error -Wno-error=format ${KCFLAGS:-}"
export HOSTCFLAGS="-std=gnu11 -Wno-error -Wno-error=format ${HOSTCFLAGS:-}"
export KBUILD_USERCFLAGS="-std=gnu11 -Wno-error -Wno-error=format ${KBUILD_USERCFLAGS:-}"

echo "[+] Applying GCC 15.2.0 compatibility source patches..."
python3 - <<'PY'
from pathlib import Path
import re

# Patch include/linux/stddef.h: Linux 6.1.1 defines enum constants false/true.
# With GCC 15 defaulting to newer C behavior, false/true/bool can be keywords.
p = Path("include/linux/stddef.h")
if p.exists():
    s = p.read_text()
    if "SISOP_GCC15_C23_BOOL_PATCH" not in s:
        pat = re.compile(r"enum\s*\{\s*false\s*=\s*0\s*,\s*true\s*=\s*1\s*\};", re.S)
        repl = """/* SISOP_GCC15_C23_BOOL_PATCH */
#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 202311L
enum {
	false	= 0,
	true	= 1
};
#endif"""
        s2, n = pat.subn(repl, s, count=1)
        if n == 0:
            # Fallback for the exact common Linux 6.1.1 layout.
            s2 = s.replace("enum {\n\tfalse\t= 0,\n\ttrue\t= 1\n};", repl)
        p.write_text(s2)

# Patch include/linux/types.h: Linux 6.1.1 typedefs _Bool bool.
p = Path("include/linux/types.h")
if p.exists():
    s = p.read_text()
    if "SISOP_GCC15_C23_BOOL_TYPE_PATCH" not in s:
        s = re.sub(
            r"typedef\s+_Bool\s+bool\s*;",
            "/* SISOP_GCC15_C23_BOOL_TYPE_PATCH */\n#if !defined(__STDC_VERSION__) || __STDC_VERSION__ < 202311L\ntypedef _Bool bool;\n#endif",
            s,
            count=1,
        )
        p.write_text(s)

# Patch realmode makefile as an extra guard. Use += so it still works if the file layout differs.
p = Path("arch/x86/realmode/rm/Makefile")
if p.exists():
    s = p.read_text()
    if "SISOP_GCC15_GNU11_PATCH" not in s:
        s = "# SISOP_GCC15_GNU11_PATCH\nKBUILD_CFLAGS += -std=gnu11 -Wno-error\n" + s
        p.write_text(s)

# Patch blk-iocost format warnings seen on newer compilers.
p = Path("block/blk-iocost.c")
if p.exists():
    s = p.read_text()
    s = s.replace('"%s %u\\n", dname, iocg->cfg_weight', '"%s %lu\\n", dname, iocg->cfg_weight')
    s = s.replace('"default %u\\n", iocc->dfl_weight', '"default %lu\\n", iocc->dfl_weight')
    p.write_text(s)
PY

echo "[+] Preparing defconfig..."
make CC="$KERNEL_CC" HOSTCC="$KERNEL_CC" WERROR=0 KCFLAGS="$KCFLAGS" HOSTCFLAGS="$HOSTCFLAGS" KBUILD_USERCFLAGS="$KBUILD_USERCFLAGS" defconfig

echo "[+] Disabling WERROR and enabling needed kernel features..."
scripts/config --disable WERROR 2>/dev/null || true

scripts/config --enable BLK_DEV_INITRD
scripts/config --enable DEVTMPFS
scripts/config --enable DEVTMPFS_MOUNT
scripts/config --enable TMPFS
scripts/config --enable PROC_FS
scripts/config --enable SYSFS
scripts/config --enable TTY
scripts/config --enable VT
scripts/config --enable VT_CONSOLE
scripts/config --enable HW_CONSOLE
scripts/config --enable VGA_CONSOLE
scripts/config --enable SERIAL_8250
scripts/config --enable SERIAL_8250_CONSOLE
scripts/config --enable PCI
scripts/config --enable NET
scripts/config --enable NETDEVICES
scripts/config --enable ETHERNET
scripts/config --enable NET_VENDOR_INTEL
scripts/config --enable E1000
scripts/config --enable INET
scripts/config --enable PACKET
scripts/config --enable UNIX
scripts/config --enable FUSE_FS
scripts/config --enable NAMESPACES
scripts/config --enable USER_NS
scripts/config --enable PID_NS
scripts/config --enable IPC_NS
scripts/config --enable UTS_NS

echo "[+] Finalizing config..."
make CC="$KERNEL_CC" HOSTCC="$KERNEL_CC" WERROR=0 KCFLAGS="$KCFLAGS" HOSTCFLAGS="$HOSTCFLAGS" KBUILD_USERCFLAGS="$KBUILD_USERCFLAGS" olddefconfig

echo "[+] Building bzImage. This can take a while..."
make CC="$KERNEL_CC" HOSTCC="$KERNEL_CC" WERROR=0 KCFLAGS="$KCFLAGS" HOSTCFLAGS="$HOSTCFLAGS" KBUILD_USERCFLAGS="$KBUILD_USERCFLAGS" -j"$(nproc)" bzImage

cp arch/x86/boot/bzImage ../osboot/bzImage
cp .config ../.config

echo "[+] Done: osboot/bzImage"
