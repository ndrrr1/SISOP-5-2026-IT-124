#!/bin/bash
set -euo pipefail

if [ -z "${FAKEROOTKEY:-}" ]; then
    exec fakeroot "$0" "$@"
fi

ROOTFS="rootfs_single"
OUT="osboot/single.gz"

rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp,root,home,mnt,usr/bin,usr/sbin}

get_static_busybox() {
    mkdir -p "$ROOTFS/bin"
    if command -v busybox >/dev/null 2>&1 && ldd "$(command -v busybox)" 2>&1 | grep -q "not a dynamic executable"; then
        cp "$(command -v busybox)" "$ROOTFS/bin/busybox"
    else
        wget -O "$ROOTFS/bin/busybox" "https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox"
    fi
    chmod +x "$ROOTFS/bin/busybox"
}

get_static_busybox

for cmd in sh ash ls cat echo mount umount mkdir rmdir touch rm cp mv pwd id whoami \
           login getty cttyhack ping wget ip udhcpc clear sleep dmesg uname chmod chown \
           ps kill true false setsid mknod ifconfig route nslookup; do
    ln -sf /bin/busybox "$ROOTFS/bin/$cmd"
    ln -sf /bin/busybox "$ROOTFS/sbin/$cmd" 2>/dev/null || true
    ln -sf /bin/busybox "$ROOTFS/usr/bin/$cmd" 2>/dev/null || true
done

cat > "$ROOTFS/bin/udhcpc.script" <<'EOF'
#!/bin/sh
set +e
[ -n "$interface" ] || interface="eth0"
case "$1" in
    deconfig)
        ip addr flush dev "$interface" 2>/dev/null || true
        ;;
    bound|renew)
        ip addr flush dev "$interface" 2>/dev/null || true
        if [ -n "$subnet" ]; then
            ifconfig "$interface" "$ip" netmask "$subnet" up 2>/dev/null || true
        else
            ip addr add "$ip/24" dev "$interface" 2>/dev/null || ifconfig "$interface" "$ip" up 2>/dev/null || true
        fi
        route del default 2>/dev/null || true
        for r in $router; do
            route add default gw "$r" "$interface" 2>/dev/null || route add default gw "$r" 2>/dev/null || ip route add default via "$r" dev "$interface" 2>/dev/null || true
            break
        done
        mkdir -p /etc
        : > /etc/resolv.conf
        for d in $dns; do
            echo "nameserver $d" >> /etc/resolv.conf
        done
        [ -s /etc/resolv.conf ] || echo "nameserver 10.0.2.3" > /etc/resolv.conf
        ;;
esac
exit 0
EOF
chmod +x "$ROOTFS/bin/udhcpc.script"

cat > "$ROOTFS/bin/net-up" <<'EOF'
#!/bin/sh
set +e
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH

mkdir -p /etc /tmp /proc /sys /dev
[ -f /etc/resolv.conf ] || touch /etc/resolv.conf

echo "nameserver 10.0.2.3" > /etc/resolv.conf

ip link set lo up 2>/dev/null || ifconfig lo up 2>/dev/null || true

IFACE=""
for dev in eth0 ens3 enp0s3; do
    if ip link show "$dev" >/dev/null 2>&1 || ifconfig "$dev" >/dev/null 2>&1; then
        IFACE="$dev"
        break
    fi
done

if [ -z "$IFACE" ]; then
    echo "Tidak menemukan interface jaringan."
    ip addr 2>/dev/null || ifconfig -a 2>/dev/null || true
    exit 1
fi

ip link set "$IFACE" up 2>/dev/null || ifconfig "$IFACE" up 2>/dev/null || true

# 1) Coba DHCP QEMU lebih dulu. Pakai script eksplisit agar IP/gateway benar-benar dipasang.
udhcpc -i "$IFACE" -s /bin/udhcpc.script -q -t 4 -T 2 2>/dev/null || true

# 2) Jika DHCP tidak menghasilkan IPv4, pakai fallback statis untuk QEMU user-mode network.
if ! ip addr show "$IFACE" 2>/dev/null | grep -q 'inet '; then
    echo "DHCP belum memberi IPv4, memakai fallback static QEMU: 10.0.2.15/24"
    ip addr flush dev "$IFACE" 2>/dev/null || true
    ip addr add 10.0.2.15/24 dev "$IFACE" 2>/dev/null || ifconfig "$IFACE" 10.0.2.15 netmask 255.255.255.0 up 2>/dev/null || true
    ip link set "$IFACE" up 2>/dev/null || ifconfig "$IFACE" up 2>/dev/null || true
    route del default 2>/dev/null || true
    route add default gw 10.0.2.2 "$IFACE" 2>/dev/null || route add default gw 10.0.2.2 2>/dev/null || ip route add default via 10.0.2.2 dev "$IFACE" 2>/dev/null || true
    echo "nameserver 10.0.2.3" > /etc/resolv.conf
fi

printf 'Interface: %s\n' "$IFACE"
ip addr show "$IFACE" 2>/dev/null || ifconfig "$IFACE" 2>/dev/null || true
route -n 2>/dev/null || ip route 2>/dev/null || true
EOF
chmod +x "$ROOTFS/bin/net-up"

cat > "$ROOTFS/bin/nettest" <<'EOF'
#!/bin/sh
set +e
/bin/net-up

echo "--- Ping gateway QEMU ---"
ping -c 4 10.0.2.2

echo "--- Ping IP public ---"
ping -c 4 8.8.8.8

echo "--- Ping DNS/domain ---"
ping -c 4 google.com

echo "--- Wget HTTP ---"
wget -O - http://example.com
EOF
chmod +x "$ROOTFS/bin/nettest"


cat > "$ROOTFS/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/sh
EOF

cat > "$ROOTFS/etc/group" <<'EOF'
root:x:0:
EOF

ROOT_HASH="$(openssl passwd -6 root123)"
cat > "$ROOTFS/etc/shadow" <<EOF
root:${ROOT_HASH}:19000:0:99999:7:::
EOF

cat > "$ROOTFS/etc/profile" <<'EOF'
clear
echo "========================================"
echo "          Farewell Party OS"
echo "          Single-user mode"
echo "========================================"
echo "Welcome, root, root"
echo ""
EOF

cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh

# Init process must never exit. If /init exits, Linux panics with:
# Kernel panic - not syncing: Attempted to kill init!
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH

mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t tmpfs tmpfs /tmp 2>/dev/null || true

mkdir -p /etc /dev /proc /sys /tmp /mnt /root /home
[ -c /dev/console ] || mknod /dev/console c 5 1 2>/dev/null || true
[ -c /dev/null ] || mknod /dev/null c 1 3 2>/dev/null || true
[ -c /dev/tty0 ] || mknod /dev/tty0 c 4 0 2>/dev/null || true

[ -f /etc/resolv.conf ] || touch /etc/resolv.conf
echo "nameserver 10.0.2.3" > /etc/resolv.conf

# Aktifkan jaringan. net-up memiliki DHCP script dan fallback static QEMU.
/bin/net-up >/tmp/net-up.log 2>&1 || true

while true; do
    clear 2>/dev/null || true
    echo "========================================"
    echo "          Farewell Party OS"
    echo "          Single-user mode"
    echo "========================================"
    echo "Welcome, root, root"
    echo "Type 'exit' to restart shell. Type 'nettest' to test ping/wget."
    echo ""

    /bin/setsid /bin/cttyhack /bin/sh -l 2>/dev/null || /bin/sh -l || true
    sleep 1
done
EOF

chmod +x "$ROOTFS/init"
chmod 600 "$ROOTFS/etc/shadow"
chmod 755 "$ROOTFS"
chmod 700 "$ROOTFS/root"
chmod 1777 "$ROOTFS/tmp"

cd "$ROOTFS"
find . -print0 | cpio --null -ov --format=newc | gzip -9 > "../$OUT"
cd ..

echo "[+] Done: $OUT"
