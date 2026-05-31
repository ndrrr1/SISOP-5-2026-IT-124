# SISOP-5-2026-IT-124

* **Nama**  : Ndaru Satria Tama
* **NRP**   : 5027251124
* **Kelas** : C

---

## Struktur Repository

```text
.
├── README.md
├── soal_1
│   ├── backup.sh
│   ├── iso.sh
│   ├── kernel.sh
│   ├── multi.sh
│   ├── osboot
│   ├── qemu.sh
│   └── single.sh
└── soal_2
    ├── bochsrc.txt
    ├── bootloader.asm
    ├── build.sh
    ├── kernel.asm
    ├── kernel.c
    ├── Makefile
    └── README.md

Catatan:

Folder soal_1/osboot dapat kosong pada ZIP awal karena isinya dibuat saat runtime.
File hasil build Soal 2 seperti floppy.img, kernel.bin, kernel.o, dan bootloader.bin tidak disimpan dalam struktur final karena dapat dibuat ulang dengan ./build.sh.
Semua command dijalankan dari root repository, yaitu folder yang berisi soal_1 dan soal_2.
Pendahuluan

Pada Modul 5 Sistem Operasi ini, saya mengerjakan dua soal utama.

Soal 1 membuat sistem bootable berbasis Linux kernel 6.1.1. Sistem ini memiliki mode single-user, multi-user, ISO bootable, QEMU runner, networking, package manager sederhana, dan backup hasil build.
Soal 2 membuat sistem operasi sederhana 16-bit menggunakan bootloader, kernel assembly, dan kernel C. OS ini dijalankan menggunakan Bochs dan memiliki command shell seperti check, add, sub, fac, season, triangle, clear, help, dan about.
Requirement Umum
sudo apt update
sudo apt install -y \
  build-essential git wget curl zip unzip file ca-certificates openssl \
  libncurses-dev bison flex libssl-dev libelf-dev bc cpio gzip xz-utils \
  fakeroot busybox-static tree make \
  qemu-system-x86 qemu-utils qemu-system-gui \
  xorriso syslinux-common isolinux \
  nasm bochs bochs-sdl bochs-x bochsbios vgabios \
  bcc bin86

Cek tool:

gcc --version
qemu-system-x86_64 --version
bochs -version
Reporting Soal 1
A. Deskripsi Soal

Pada soal pertama, dibuat sistem bootable menggunakan Linux kernel 6.1.1. Sistem ini memiliki dua root filesystem:

single.gz untuk single-user mode.
multi.gz untuk multi-user mode.

Selain itu, dibuat juga ISO bootable farewell.iso dan script QEMU untuk menjalankan seluruh mode tersebut.

Output utama Soal 1:

soal_1/osboot/bzImage
soal_1/osboot/single.gz
soal_1/osboot/multi.gz
soal_1/osboot/farewell.iso
B. File yang Digunakan
soal_1/kernel.sh
soal_1/single.sh
soal_1/multi.sh
soal_1/iso.sh
soal_1/qemu.sh
soal_1/backup.sh
soal_1/osboot/
C. Kode Lengkap kernel.sh
<details> <summary>Klik untuk membuka/menutup kode lengkap kernel.sh</summary>
MD

cat soal_1/kernel.sh >> README.md

cat >> README.md <<'MD'
</details>
D. Kode Lengkap single.sh
<details> <summary>Klik untuk membuka/menutup kode lengkap single.sh</summary>
MD

cat soal_1/single.sh >> README.md

cat >> README.md <<'MD'
</details>
E. Kode Lengkap multi.sh
<details> <summary>Klik untuk membuka/menutup kode lengkap multi.sh</summary>
MD

cat soal_1/multi.sh >> README.md

cat >> README.md <<'MD'
</details>
F. Kode Lengkap iso.sh
<details> <summary>Klik untuk membuka/menutup kode lengkap iso.sh</summary>
MD

cat soal_1/iso.sh >> README.md

cat >> README.md <<'MD'
</details>
G. Kode Lengkap qemu.sh
<details> <summary>Klik untuk membuka/menutup kode lengkap qemu.sh</summary>
MD

cat soal_1/qemu.sh >> README.md

cat >> README.md <<'MD'
</details>
H. Kode Lengkap backup.sh
<details> <summary>Klik untuk membuka/menutup kode lengkap backup.sh</summary>
MD

cat soal_1/backup.sh >> README.md

cat >> README.md <<'MD'
</details>
I. Cara Menjalankan Soal 1

Semua langkah dimulai dari root repository.

1. Masuk ke folder Soal 1
cd soal_1
chmod +x *.sh
2. Build kernel
./kernel.sh

Jika ingin build bersih:

./kernel.sh --clean

Cek hasil:

ls -lh osboot/bzImage
ls -lh .config
3. Build single-user filesystem
./single.sh

Cek:

ls -lh osboot/single.gz

Run:

./qemu.sh --single

Di dalam OS:

whoami
ls /
cd /root
touch /tmp/test_single
ls -l /tmp/test_single
4. Test network single-user

Di dalam QEMU:

net-up
nettest

Jika ingin manual:

mkdir -p /etc
ip link set lo up
ip link set eth0 up
ip addr flush dev eth0
ip addr add 10.0.2.15/24 dev eth0
route del default 2>/dev/null
route add default gw 10.0.2.2 eth0 2>/dev/null || route add default gw 10.0.2.2
echo "nameserver 10.0.2.3" > /etc/resolv.conf
ping -c 4 10.0.2.2
ping -c 4 8.8.8.8
ping -c 4 google.com
wget -O - http://example.com
5. Build multi-user filesystem
./multi.sh

Cek:

ls -lh osboot/multi.gz

Run:

./qemu.sh --multi

Login akun:

root : root123
henn : henn123
hann : hann123
viii : viii123
kids : kids123
6. Test permission root

Login sebagai root:

root
root123

Command:

whoami
cd /root
cd /home/henn
cd /home/hann
cd /home/viii
cd /home/kids

Root harus bisa mengakses semua folder.

7. Test permission henn

Login:

henn
henn123

Command:

whoami
cd /home/henn
touch test_henn
cd /home/hann
touch test_from_henn
cd /home/viii
touch test_from_henn
cd /home/kids
touch test_from_henn
cd /root

Hasil:

henn bisa akses /home/henn, /home/hann, /home/viii, /home/kids.
henn tidak bisa akses /root.
8. Test permission hann

Login:

hann
hann123

Command:

whoami
cd /home/hann
touch test_hann
cd /home/viii
touch test_from_hann
cd /home/kids
touch test_from_hann
cd /home/henn
cd /root

Hasil:

hann bisa akses /home/hann, /home/viii, /home/kids.
hann tidak bisa akses /home/henn dan /root.
9. Test permission viii

Login:

viii
viii123

Command:

whoami
cd /home/viii
touch test_viii
cd /home/kids
touch test_from_viii
cd /home/henn
cd /home/hann
cd /root

Hasil:

viii bisa akses /home/viii dan /home/kids.
viii tidak bisa akses /home/henn, /home/hann, dan /root.
10. Test permission kids

Login:

kids
kids123

Command:

whoami
cd /home/kids
touch test_kids
cd /home/henn
cd /home/hann
cd /home/viii
cd /root

Hasil:

kids hanya bisa akses /home/kids.
kids tidak bisa akses /home/henn, /home/hann, /home/viii, dan /root.
11. Test package manager party

Login sebagai root di multi-user:

party help
party list
party install hello
hello-party

Output yang diharapkan:

Hello from Farewell Party package manager!
12. Test FUSE demo
party install fuse-demo
mkdir -p /mnt/fuse
fuse-demo /mnt/fuse &
cat /mnt/fuse/hello.txt

Output yang diharapkan:

Farewell Party FUSE works!

atau fallback:

Farewell Party FUSE fallback demo works!
13. Build ISO bootable
./iso.sh

Cek:

ls -lh osboot/farewell.iso

Run ISO:

./qemu.sh --all

Pilih menu single-user, lalu tes:

whoami
ls /

Run lagi:

./qemu.sh --all

Pilih menu multi-user, login root:

root
root123

Tes:

whoami
ls /home

Output:

henn hann viii kids
14. Backup hasil build

Backup dilakukan paling terakhir.

./backup.sh

Cek:

ls -lh osboot

Output berupa:

farewell_backup_DDMMYYYY-HHMMSS.zip
J. Penjelasan Kode Soal 1
1. kernel.sh

Script ini mengunduh, melakukan patch, mengonfigurasi, dan mengompilasi Linux kernel 6.1.1. Patch dilakukan agar kernel tetap dapat dikompilasi pada GCC modern, termasuk GCC 15.2.0. Output utama script ini adalah osboot/bzImage dan .config.

2. single.sh

Script ini membuat root filesystem single-user berbasis BusyBox. Sistem langsung masuk ke shell root setelah boot. Script ini juga membuat /init, mount proc, sysfs, devtmpfs, dan tmpfs.

3. multi.sh

Script ini membuat root filesystem multi-user. Di dalamnya terdapat user root, henn, hann, viii, dan kids, lengkap dengan password, group, home directory, permission, networking, dan package manager party.

4. iso.sh

Script ini membuat ISO bootable menggunakan bzImage, single.gz, dan multi.gz. ISO memiliki menu untuk boot ke single-user atau multi-user.

5. qemu.sh

Script ini menjalankan sistem menggunakan QEMU. Mode yang tersedia adalah --single, --multi, dan --all.

6. backup.sh

Script ini membuat backup hasil build Soal 1 ke file ZIP bertimestamp.

Reporting Soal 2
A. Deskripsi Soal

Pada soal kedua, dibuat sistem operasi sederhana 16-bit menggunakan bootloader dan kernel. Bootloader membaca kernel dari floppy image, lalu kernel menjalankan shell sederhana.

Command yang tersedia:

check
add
sub
fac
season
triangle
clear
help
about
B. File yang Digunakan
soal_2/Makefile
soal_2/README.md
soal_2/bochsrc.txt
soal_2/bootloader.asm
soal_2/build.sh
soal_2/kernel.asm
soal_2/kernel.c
C. Kode Lengkap bootloader.asm
<details> <summary>Klik untuk membuka/menutup kode lengkap bootloader.asm</summary>
MD

cat soal_2/bootloader.asm >> README.md

cat >> README.md <<'MD'
</details>
D. Kode Lengkap kernel.asm
<details> <summary>Klik untuk membuka/menutup kode lengkap kernel.asm</summary>
MD

cat soal_2/kernel.asm >> README.md

cat >> README.md <<'MD'
</details>
E. Kode Lengkap kernel.c
<details> <summary>Klik untuk membuka/menutup kode lengkap kernel.c</summary>
MD

cat soal_2/kernel.c >> README.md

cat >> README.md <<'MD'
</details>
F. Kode Lengkap Makefile
<details> <summary>Klik untuk membuka/menutup kode lengkap Makefile</summary>
MD

cat soal_2/Makefile >> README.md

cat >> README.md <<'MD'
</details>
G. Kode Lengkap build.sh
<details> <summary>Klik untuk membuka/menutup kode lengkap build.sh</summary>
MD

cat soal_2/build.sh >> README.md

cat >> README.md <<'MD'
</details>
H. Kode Lengkap bochsrc.txt
<details> <summary>Klik untuk membuka/menutup kode lengkap bochsrc.txt</summary>
MD

cat soal_2/bochsrc.txt >> README.md

cat >> README.md <<'MD'
</details>
I. Cara Menjalankan Soal 2

Semua langkah dimulai dari root repository.

1. Masuk ke folder Soal 2
cd soal_2
chmod +x build.sh
2. Hapus hasil build lama
rm -f floppy.img bootloader.bin kernel.bin kernel.o kernel-asm.o bochslog.txt
3. Build
./build.sh

Cek:

ls -lh floppy.img kernel.bin
4. Run dengan Bochs
./build.sh --run

Jika masuk debugger:

<bochs:1>

ketik:

c

lalu Enter.

J. Uji Command Soal 2
1. check
check

Output:

ok
2. add
add 5 3

Output:

8
3. sub
sub 10 2

Output:

8
4. fac
fac 6

Output:

720

Limit:

fac 120

Output:

know your limit little bro.
5. season
season winter
season spring
season summer
season fall
season radiant

Output:

winter mode
spring mode
summer mode
fall mode
radiant mode
6. triangle
triangle 5

Output:

x
xx
xxx
xxxx
xxxxx
7. help
help

Output berupa daftar command.

8. about
about

Output berupa informasi OS.

9. clear
clear

Layar dibersihkan.

K. Penjelasan Kode Soal 2
1. bootloader.asm

File ini adalah bootloader yang dijalankan pertama kali oleh BIOS. Bootloader membaca kernel dari floppy image menggunakan BIOS interrupt int 0x13, lalu memindahkan eksekusi ke kernel.

2. kernel.asm

File ini menjadi penghubung antara assembly dan C. File ini menyediakan _start, _putInMemory, dan _getChar. Fungsi _putInMemory digunakan untuk menulis ke video memory, sedangkan _getChar membaca keyboard menggunakan BIOS interrupt int 0x16.

3. kernel.c

File ini berisi shell utama OS. Program membaca input keyboard, membandingkan command, lalu menjalankan fungsi sesuai command. Fungsi penting di dalamnya meliputi printChar, printString, readString, parseNumber, printNumber, commandAdd, commandSub, commandFac, commandSeason, dan commandTriangle.

4. Makefile

File ini mengatur proses pembuatan floppy image, bootloader binary, kernel object, kernel binary, dan penulisan semuanya ke floppy.img.

5. build.sh

Script ini memudahkan proses build dan run. ./build.sh digunakan untuk build, sedangkan ./build.sh --run digunakan untuk menjalankan Bochs.

Cleanup Setelah Testing

Jalankan dari root repository.

1. Stop emulator
pkill qemu-system-x86_64 2>/dev/null || true
pkill bochs 2>/dev/null || true
2. Bersihkan runtime Soal 1
rm -rf soal_1/linux-6.1.1
rm -f soal_1/linux-6.1.1.tar.xz
rm -rf soal_1/rootfs_single
rm -rf soal_1/rootfs_multi
rm -rf soal_1/iso_root

Jika ingin mengosongkan output osboot:

rm -f soal_1/osboot/bzImage
rm -f soal_1/osboot/single.gz
rm -f soal_1/osboot/multi.gz
rm -f soal_1/osboot/farewell.iso
3. Bersihkan runtime Soal 2
rm -f soal_2/floppy.img
rm -f soal_2/bootloader.bin
rm -f soal_2/kernel.bin
rm -f soal_2/kernel.o
rm -f soal_2/kernel-asm.o
rm -f soal_2/bochslog.txt
Urutan Screenshot yang Disarankan
Soal 1
1. Struktur folder soal_1.
2. Build kernel atau bukti bzImage terbentuk.
3. Build single.gz.
4. Boot single-user.
5. whoami di single-user.
6. Test ping dan wget.
7. Build multi.gz.
8. Login root di multi-user.
9. Test permission henn.
10. Test permission hann.
11. Test permission viii.
12. Test permission kids.
13. Test party.
14. Test fuse-demo.
15. Build farewell.iso.
16. Boot ISO single-user.
17. Boot ISO multi-user.
18. Backup hasil build.
Soal 2
1. Struktur folder soal_2.
2. Hasil ./build.sh.
3. Bochs berhasil boot.
4. check -> ok.
5. add 5 3 -> 8.
6. sub 10 2 -> 8.
7. fac 6 -> 720.
8. fac 120 -> know your limit little bro.
9. season radiant.
10. triangle 5.
11. help.
12. about.
13. clear.
Zip Final

Dari home:

cd ~
zip -r SISOP-5-2026-IT-124.zip SISOP-5-2026-IT-124

Cek:

ls -lh SISOP-5-2026-IT-124.zip
Kesimpulan

Pada Modul 5 ini, Soal 1 memperlihatkan proses build kernel, pembuatan initramfs, konfigurasi user, permission, networking, QEMU, ISO bootable, dan backup. Soal 2 memperlihatkan cara kerja bootloader, kernel sederhana, input keyboard, output layar, serta command shell sederhana yang berjalan pada Bochs.
MD
EOF
