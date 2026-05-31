#!/bin/bash
set -euo pipefail

if [ -z "${FAKEROOTKEY:-}" ]; then
    exec fakeroot "$0" "$@"
fi

ROOTFS="rootfs_multi"
OUT="osboot/multi.gz"

rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp,root,home,mnt,lib,lib64,usr/lib,usr/bin,usr/sbin}

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
           ps kill true false setsid mknod ln groups ifconfig route nslookup; do
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
henn:x:1001:1001:henn:/home/henn:/bin/sh
hann:x:1002:1002:hann:/home/hann:/bin/sh
viii:x:1003:1003:viii:/home/viii:/bin/sh
kids:x:1004:1004:kids:/home/kids:/bin/sh
EOF

cat > "$ROOTFS/etc/group" <<'EOF'
root:x:0:
henn:x:1001:
hann:x:1002:
viii:x:1003:
kids:x:1004:
home_henn:x:2001:henn
home_hann:x:2002:henn,hann
home_viii:x:2003:henn,hann,viii
home_kids:x:2004:henn,hann,viii,kids
EOF

ROOT_HASH="$(openssl passwd -6 root123)"
HENN_HASH="$(openssl passwd -6 henn123)"
HANN_HASH="$(openssl passwd -6 hann123)"
VIII_HASH="$(openssl passwd -6 viii123)"
KIDS_HASH="$(openssl passwd -6 kids123)"

cat > "$ROOTFS/etc/shadow" <<EOF
root:${ROOT_HASH}:19000:0:99999:7:::
henn:${HENN_HASH}:19000:0:99999:7:::
hann:${HANN_HASH}:19000:0:99999:7:::
viii:${VIII_HASH}:19000:0:99999:7:::
kids:${KIDS_HASH}:19000:0:99999:7:::
EOF

chmod 600 "$ROOTFS/etc/shadow"

mkdir -p "$ROOTFS/home"/{henn,hann,viii,kids}

chown 0:0 "$ROOTFS/root"
chmod 700 "$ROOTFS/root"

chown 1001:2001 "$ROOTFS/home/henn"
chown 1002:2002 "$ROOTFS/home/hann"
chown 1003:2003 "$ROOTFS/home/viii"
chown 1004:2004 "$ROOTFS/home/kids"

chmod 770 "$ROOTFS/home/henn"
chmod 770 "$ROOTFS/home/hann"
chmod 770 "$ROOTFS/home/viii"
chmod 770 "$ROOTFS/home/kids"
chmod 1777 "$ROOTFS/tmp"

cat > "$ROOTFS/etc/farewell.txt" <<'EOF'
 ______                         _ _ 
|  ____|                       | | |
| |__ __ _ _ __ _____      _____| | |
|  __/ _` | '__/ _ \ \ /\ / / _ \ | |
| | | (_| | | |  __/\ V  V /  __/ | |
|_|  \__,_|_|  \___| \_/\_/ \___|_|_|

        Farewell Party OS
EOF

cat > "$ROOTFS/etc/profile" <<'EOF'
clear
cat /etc/farewell.txt
USER_NOW=$(whoami)
echo "Welcome, $USER_NOW, $USER_NOW"
echo "Type: party help"
echo "Type: nettest untuk tes ping dan wget"
echo ""
EOF

cat > "$ROOTFS/bin/party" <<'EOF'
#!/bin/sh

case "$1" in
    help|"")
        echo "party package manager"
        echo "Usage:"
        echo "  party help"
        echo "  party list"
        echo "  party install hello"
        echo "  party install fuse-demo"
        ;;
    list)
        echo "Available packages:"
        echo "  hello"
        echo "  fuse-demo"
        ;;
    install)
        case "$2" in
            hello)
                cat > /bin/hello-party <<'EOS'
#!/bin/sh
echo "Hello from Farewell Party package manager!"
EOS
                chmod +x /bin/hello-party
                echo "Installed: hello"
                ;;
            fuse-demo)
                if [ -x /bin/fuse-demo.real ]; then
                    ln -sf /bin/fuse-demo.real /bin/fuse-demo
                    echo "Installed: fuse-demo"
                    echo "Run: mkdir -p /mnt/fuse && fuse-demo /mnt/fuse &"
                else
                    cat > /bin/fuse-demo <<'EOS'
#!/bin/sh
MNT="$1"
if [ -z "$MNT" ]; then
    echo "usage: fuse-demo <mountpoint>"
    exit 1
fi
mkdir -p "$MNT"
echo "Farewell Party FUSE fallback demo works!" > "$MNT/hello.txt"
echo "Fallback demo prepared at $MNT/hello.txt"
while true; do sleep 3600; done
EOS
                    chmod +x /bin/fuse-demo
                    echo "Installed: fuse-demo fallback"
                fi
                ;;
            *)
                echo "Unknown package: $2"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unknown party command: $1"
        exit 1
        ;;
esac
EOF
chmod +x "$ROOTFS/bin/party"

# Try to add a real libfuse3 hello filesystem if the host has libfuse3-dev.
if command -v gcc >/dev/null 2>&1 && command -v pkg-config >/dev/null 2>&1 && pkg-config --exists fuse3; then
    cat > fuse_demo.c <<'EOF'
#define FUSE_USE_VERSION 31
#include <fuse3/fuse.h>
#include <string.h>
#include <errno.h>
#include <stddef.h>

static const char *hello_path = "/hello.txt";
static const char *hello_str = "Farewell Party FUSE works!\n";

static int hello_getattr(const char *path, struct stat *stbuf, struct fuse_file_info *fi) {
    (void) fi;
    memset(stbuf, 0, sizeof(struct stat));
    if (strcmp(path, "/") == 0) {
        stbuf->st_mode = S_IFDIR | 0755;
        stbuf->st_nlink = 2;
        return 0;
    }
    if (strcmp(path, hello_path) == 0) {
        stbuf->st_mode = S_IFREG | 0444;
        stbuf->st_nlink = 1;
        stbuf->st_size = strlen(hello_str);
        return 0;
    }
    return -ENOENT;
}

static int hello_readdir(const char *path, void *buf, fuse_fill_dir_t filler,
                         off_t offset, struct fuse_file_info *fi,
                         enum fuse_readdir_flags flags) {
    (void) offset;
    (void) fi;
    (void) flags;
    if (strcmp(path, "/") != 0) return -ENOENT;
    filler(buf, ".", NULL, 0, 0);
    filler(buf, "..", NULL, 0, 0);
    filler(buf, "hello.txt", NULL, 0, 0);
    return 0;
}

static int hello_open(const char *path, struct fuse_file_info *fi) {
    (void) fi;
    if (strcmp(path, hello_path) != 0) return -ENOENT;
    return 0;
}

static int hello_read(const char *path, char *buf, size_t size, off_t offset,
                      struct fuse_file_info *fi) {
    size_t len = strlen(hello_str);
    (void) fi;
    if (strcmp(path, hello_path) != 0) return -ENOENT;
    if ((size_t) offset < len) {
        if (offset + size > len) size = len - offset;
        memcpy(buf, hello_str + offset, size);
    } else {
        size = 0;
    }
    return size;
}

static const struct fuse_operations hello_oper = {
    .getattr = hello_getattr,
    .readdir = hello_readdir,
    .open = hello_open,
    .read = hello_read,
};

int main(int argc, char *argv[]) {
    return fuse_main(argc, argv, &hello_oper, NULL);
}
EOF

    if gcc fuse_demo.c -o "$ROOTFS/bin/fuse-demo.real" $(pkg-config fuse3 --cflags --libs) 2>/dev/null; then
        chmod +x "$ROOTFS/bin/fuse-demo.real"
        # Copy dynamic dependencies into rootfs.
        ldd "$ROOTFS/bin/fuse-demo.real" | awk '
            /=> \// {print $3}
            /^\// {print $1}
        ' | while read -r lib; do
            if [ -f "$lib" ]; then
                dest="$ROOTFS$lib"
                mkdir -p "$(dirname "$dest")"
                cp "$lib" "$dest"
            fi
        done
    fi
    rm -f fuse_demo.c
fi

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
    echo "Booting Farewell Party multi-user OS..."
    echo "Login accounts: root/henn/hann/viii/kids"
    echo ""

    /bin/setsid /bin/cttyhack /bin/login 2>/dev/null || /bin/sh -l || true
    sleep 1
done
EOF

chmod +x "$ROOTFS/init"

cd "$ROOTFS"
find . -print0 | cpio --null -ov --format=newc | gzip -9 > "../$OUT"
cd ..

echo "[+] Done: $OUT"
