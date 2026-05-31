# SISOP-5-2026-IT-124

* **Nama**  : Ndaru Satria Tama
* **NRP**   : 5027251124
* **Kelas** : C

---

## Struktur Repository

```text
.
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
```

Catatan:

* Folder `soal_1/osboot` dapat kosong pada ZIP awal. Folder ini akan terisi setelah `kernel.sh`, `single.sh`, `multi.sh`, dan `iso.sh` dijalankan.
* File hasil build Soal 2 seperti `floppy.img`, `kernel.bin`, `kernel.o`, `kernel-asm.o`, `bootloader.bin`, dan `bochslog.txt` tidak disimpan dalam struktur final karena file tersebut dapat dibuat ulang dengan `./build.sh`.
* Semua langkah run dimulai dari root repository, yaitu folder yang berisi `soal_1` dan `soal_2`.

---

# Pendahuluan

Pada Modul 5 Sistem Operasi ini, saya mengerjakan dua soal yang berhubungan dengan proses pembuatan sistem operasi sederhana, pembuatan root filesystem, booting menggunakan QEMU, pembuatan ISO bootable, serta pembuatan kernel sederhana 16-bit yang dijalankan menggunakan Bochs.

Secara garis besar:

* **Soal 1** membuat environment bootable menggunakan Linux kernel 6.1.1, initramfs single-user, initramfs multi-user, ISO bootable, script QEMU, networking, package manager sederhana, dan backup hasil build.
* **Soal 2** membuat sistem operasi sederhana berbasis template bootloader dan kernel 16-bit. OS ini menerima input keyboard, menampilkan output ke layar, dan menjalankan command seperti `check`, `add`, `sub`, `fac`, `season`, `triangle`, `clear`, `help`, dan `about`.

Modul ini memperlihatkan bagaimana sistem operasi melakukan proses boot, bagaimana filesystem awal dibuat, bagaimana user dan permission diatur, bagaimana kernel sederhana membaca keyboard, serta bagaimana emulator seperti QEMU dan Bochs digunakan untuk menjalankan sistem operasi.

---

# Cara Menjalankan Program

Bagian ini ditulis untuk kondisi ketika seseorang baru saja mengekstrak ZIP final. Semua langkah dimulai dari folder utama repository.

Folder utama repository adalah folder yang berisi:

```text
soal_1  soal_2
```

## 1. Masuk ke folder hasil extract ZIP

Contoh:

```bash
cd ~/SISOP-5-2026-IT-124
```

Jika nama folder berbeda, sesuaikan dengan lokasi folder hasil extract.

## 2. Pastikan berada di root repository

```bash
ls
```

Output yang diharapkan:

```text
soal_1  soal_2
```

---

# Requirement Umum

Requirement ini dijalankan satu kali sebelum menjalankan soal.

## 1. Update package list

```bash
sudo apt update
```

## 2. Install dependency Soal 1 dan Soal 2

```bash
sudo apt install -y \
  build-essential git wget curl zip unzip file ca-certificates openssl \
  libncurses-dev bison flex libssl-dev libelf-dev bc cpio gzip xz-utils \
  fakeroot busybox-static tree make \
  qemu-system-x86 qemu-utils qemu-system-gui \
  xorriso syslinux-common isolinux \
  nasm bochs bochs-sdl bochs-x bochsbios vgabios \
  bcc bin86
```

## 3. Cek versi GCC

```bash
gcc --version
```

Repository ini sudah disiapkan agar `kernel.sh` dapat dijalankan pada Kali Linux dengan GCC modern, termasuk GCC 15.2.0.

## 4. Cek tool emulator

```bash
qemu-system-x86_64 --version
bochs -version
```

Jika dua command tersebut menampilkan versi program, QEMU dan Bochs sudah siap digunakan.

---

# Reporting Soal 1

## A. Deskripsi Soal

Pada soal pertama, dibuat sistem bootable berbasis Linux kernel 6.1.1. Sistem ini memiliki dua mode root filesystem, yaitu single-user dan multi-user.

Output utama yang dihasilkan Soal 1 adalah:

```text
soal_1/osboot/bzImage
soal_1/osboot/single.gz
soal_1/osboot/multi.gz
soal_1/osboot/farewell.iso
```

Script yang digunakan:

* `kernel.sh` untuk download, patch, konfigurasi, dan compile Linux kernel 6.1.1.
* `single.sh` untuk membuat initramfs single-user.
* `multi.sh` untuk membuat initramfs multi-user.
* `iso.sh` untuk membuat ISO bootable.
* `qemu.sh` untuk menjalankan sistem menggunakan QEMU.
* `backup.sh` untuk membuat backup hasil build.

---

## B. File yang Digunakan

File utama yang dikumpulkan:

* `soal_1/kernel.sh`
* `soal_1/single.sh`
* `soal_1/multi.sh`
* `soal_1/iso.sh`
* `soal_1/qemu.sh`
* `soal_1/backup.sh`
* `soal_1/osboot/`

File output runtime:

* `soal_1/osboot/bzImage`
* `soal_1/osboot/single.gz`
* `soal_1/osboot/multi.gz`
* `soal_1/osboot/farewell.iso`
* `soal_1/osboot/farewell_backup_[timestamp].zip`

---

## C. Cara Menjalankan Soal 1

Semua langkah pada bagian ini dimulai dari root repository.

### 1. Masuk ke folder `soal_1`

```bash
cd soal_1
```

### 2. Beri permission executable

```bash
chmod +x *.sh
```

### 3. Cek struktur awal

```bash
ls -la
```

Output minimal yang diharapkan:

```text
.config
backup.sh
iso.sh
kernel.sh
multi.sh
osboot
qemu.sh
single.sh
```

Jika `.config` tidak terlihat dengan `ls`, gunakan:

```bash
ls -la
```

---

## D. Build Kernel Linux 6.1.1

### 1. Jalankan script kernel

```bash
./kernel.sh
```

Jika ingin build bersih dari awal:

```bash
./kernel.sh --clean
```

Proses ini membutuhkan waktu cukup lama karena script akan mengekstrak dan mengompilasi Linux kernel.

### 2. Cek hasil kernel

```bash
ls -lh osboot/bzImage
```

Output yang diharapkan adalah file `bzImage` muncul di folder `osboot`.

### 3. Cek `.config`

```bash
ls -lh .config
```

File `.config` berisi konfigurasi kernel yang digunakan saat build.

---

## E. Build Single-user Filesystem

### 1. Jalankan script single-user

```bash
./single.sh
```

### 2. Cek hasil initramfs single-user

```bash
ls -lh osboot/single.gz
```

Output yang diharapkan:

```text
osboot/single.gz
```

### 3. Jalankan single-user dengan QEMU GUI

```bash
./qemu.sh --single
```

Jika QEMU GUI bermasalah, gunakan mode serial:

```bash
./qemu.sh --single --serial
```

### 4. Uji di dalam OS single-user

Setelah masuk ke shell OS, jalankan:

```sh
whoami
ls /
pwd
cd /root
pwd
touch /tmp/test_single
ls -l /tmp/test_single
```

Output yang diharapkan:

```text
whoami -> root
cd /root -> berhasil
touch /tmp/test_single -> berhasil
```

### 5. Uji jaringan single-user

Jika script `net-up` tersedia di dalam OS, jalankan:

```sh
net-up
nettest
```

Jika perlu konfigurasi manual, jalankan:

```sh
mkdir -p /etc
ip link set lo up
ip link set eth0 up
ip addr flush dev eth0
ip addr add 10.0.2.15/24 dev eth0
route del default 2>/dev/null
route add default gw 10.0.2.2 eth0 2>/dev/null || route add default gw 10.0.2.2
echo "nameserver 10.0.2.3" > /etc/resolv.conf
ip addr
route -n
ping -c 4 10.0.2.2
ping -c 4 8.8.8.8
ping -c 4 google.com
wget -O - http://example.com
```

Jika `ping` dan `wget` berhasil, jaringan QEMU sudah berjalan.

### 6. Keluar dari QEMU

Untuk QEMU GUI, pilih:

```text
Machine -> Quit
```

Untuk mode serial:

```text
Ctrl + A, lalu X
```

---

## F. Build Multi-user Filesystem

### 1. Jalankan script multi-user

```bash
./multi.sh
```

### 2. Cek hasil initramfs multi-user

```bash
ls -lh osboot/multi.gz
```

Output yang diharapkan:

```text
osboot/multi.gz
```

### 3. Jalankan multi-user dengan QEMU GUI

```bash
./qemu.sh --multi
```

Jika QEMU GUI bermasalah, gunakan mode serial:

```bash
./qemu.sh --multi --serial
```

### 4. Login sebagai root

```text
login: root
password: root123
```

### 5. Uji root

Di dalam OS:

```sh
whoami
ls /
ls /home
cd /root
pwd
cd /home/henn
cd /home/hann
cd /home/viii
cd /home/kids
```

Output yang diharapkan:

```text
root dapat mengakses /root dan semua folder /home
```

### 6. Uji jaringan multi-user

```sh
net-up
nettest
```

Jika perlu manual:

```sh
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
```

---

## G. Uji User dan Permission Multi-user

Akun yang tersedia:

```text
root : root123
henn : henn123
hann : hann123
viii : viii123
kids : kids123
```

### 1. Uji user `henn`

Jalankan QEMU multi-user:

```bash
./qemu.sh --multi
```

Login:

```text
login: henn
password: henn123
```

Tes:

```sh
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
```

Hasil yang diharapkan:

```text
henn dapat mengakses /home/henn, /home/hann, /home/viii, dan /home/kids.
henn tidak dapat mengakses /root.
```

### 2. Uji user `hann`

Login:

```text
login: hann
password: hann123
```

Tes:

```sh
whoami
cd /home/hann
touch test_hann
cd /home/viii
touch test_from_hann
cd /home/kids
touch test_from_hann
cd /home/henn
cd /root
```

Hasil yang diharapkan:

```text
hann dapat mengakses /home/hann, /home/viii, dan /home/kids.
hann tidak dapat mengakses /home/henn dan /root.
```

### 3. Uji user `viii`

Login:

```text
login: viii
password: viii123
```

Tes:

```sh
whoami
cd /home/viii
touch test_viii
cd /home/kids
touch test_from_viii
cd /home/henn
cd /home/hann
cd /root
```

Hasil yang diharapkan:

```text
viii dapat mengakses /home/viii dan /home/kids.
viii tidak dapat mengakses /home/henn, /home/hann, dan /root.
```

### 4. Uji user `kids`

Login:

```text
login: kids
password: kids123
```

Tes:

```sh
whoami
cd /home/kids
touch test_kids
cd /home/henn
cd /home/hann
cd /home/viii
cd /root
```

Hasil yang diharapkan:

```text
kids hanya dapat mengakses /home/kids.
kids tidak dapat mengakses /home/henn, /home/hann, /home/viii, dan /root.
```

---

## H. Uji Package Manager `party`

Jalankan QEMU multi-user dan login sebagai root:

```bash
./qemu.sh --multi
```

Login:

```text
root
root123
```

Di dalam OS:

```sh
party help
party list
party install hello
hello-party
```

Output yang diharapkan:

```text
Hello from Farewell Party package manager!
```

---

## I. Uji FUSE Demo

Masih di multi-user sebagai root:

```sh
party install fuse-demo
mkdir -p /mnt/fuse
fuse-demo /mnt/fuse &
cat /mnt/fuse/hello.txt
```

Output yang diharapkan salah satu dari berikut:

```text
Farewell Party FUSE works!
```

atau fallback demo:

```text
Farewell Party FUSE fallback demo works!
```

---

## J. Build ISO Bootable

### 1. Jalankan script ISO

```bash
./iso.sh
```

### 2. Cek hasil ISO

```bash
ls -lh osboot/farewell.iso
```

Output yang diharapkan:

```text
osboot/farewell.iso
```

### 3. Jalankan ISO dengan QEMU

```bash
./qemu.sh --all
```

Pada menu ISO, pilih:

```text
Boot single-user filesystem
```

Setelah masuk OS, tes:

```sh
whoami
ls /
```

Kemudian tutup QEMU dan jalankan lagi:

```bash
./qemu.sh --all
```

Pilih:

```text
Boot multi-user filesystem
```

Login sebagai root:

```text
root
root123
```

Tes:

```sh
whoami
ls /home
```

Output yang diharapkan:

```text
henn hann viii kids
```

---

## K. Backup Hasil Build

Backup dilakukan paling terakhir setelah semua screenshot dan pengujian selesai.

```bash
./backup.sh
```

Cek hasil backup:

```bash
ls -lh osboot
```

Output yang diharapkan berupa file:

```text
farewell_backup_DDMMYYYY-HHMMSS.zip
```

---

## L. Penjelasan Script Soal 1

### 1. `kernel.sh`

Script ini mengunduh dan mengompilasi Linux kernel 6.1.1. Script juga melakukan konfigurasi fitur penting seperti initramfs, `devtmpfs`, `procfs`, `sysfs`, console, network device, dan FUSE.

### 2. `single.sh`

Script ini membuat root filesystem single-user berbasis BusyBox. Mode ini langsung masuk ke shell root dan digunakan untuk pengujian sistem minimal.

### 3. `multi.sh`

Script ini membuat root filesystem multi-user. Di dalamnya dibuat user `root`, `henn`, `hann`, `viii`, dan `kids`, lengkap dengan permission direktori `/home` sesuai aturan akses.

### 4. `iso.sh`

Script ini membuat ISO bootable yang dapat memilih boot ke single-user atau multi-user filesystem.

### 5. `qemu.sh`

Script ini menjalankan sistem menggunakan QEMU. Mode yang tersedia:

```bash
./qemu.sh --single
./qemu.sh --multi
./qemu.sh --all
```

Mode serial tersedia sebagai cadangan:

```bash
./qemu.sh --single --serial
./qemu.sh --multi --serial
./qemu.sh --all --serial
```

### 6. `backup.sh`

Script ini membuat backup output build Soal 1 ke file ZIP timestamp.

---

## M. Hasil Akhir Soal 1

Setelah semua proses dijalankan, folder `soal_1/osboot` berisi:

```text
bzImage
single.gz
multi.gz
farewell.iso
```

---

# Reporting Soal 2

## A. Deskripsi Soal

Pada soal kedua, dibuat sistem operasi sederhana menggunakan template bootloader dan kernel. Bootloader memuat kernel ke memori, kemudian kernel menjalankan shell sederhana.

Shell pada OS ini dapat menerima command:

```text
check
add
sub
fac
season
triangle
clear
help
about
```

Program dijalankan menggunakan Bochs.

---

## B. File yang Digunakan

File utama:

* `soal_2/Makefile`
* `soal_2/README.md`
* `soal_2/bochsrc.txt`
* `soal_2/bootloader.asm`
* `soal_2/build.sh`
* `soal_2/kernel.asm`
* `soal_2/kernel.c`

File runtime yang dibuat saat build:

* `soal_2/floppy.img`
* `soal_2/bootloader.bin`
* `soal_2/kernel.bin`
* `soal_2/kernel.o`
* `soal_2/kernel-asm.o`
* `soal_2/bochslog.txt`

File runtime tersebut dapat dihapus karena bisa dibuat ulang dengan `./build.sh`.

---

## C. Cara Menjalankan Soal 2

Semua langkah pada bagian ini dimulai dari root repository.

### 1. Masuk ke folder `soal_2`

```bash
cd soal_2
```

### 2. Beri permission executable

```bash
chmod +x build.sh
```

### 3. Bersihkan hasil build lama

```bash
rm -f floppy.img bootloader.bin kernel.bin kernel.o kernel-asm.o bochslog.txt
```

### 4. Build Soal 2

```bash
./build.sh
```

Output yang diharapkan adalah file `floppy.img` berhasil dibuat.

Cek hasil build:

```bash
ls -lh floppy.img kernel.bin
```

### 5. Jalankan Soal 2 dengan Bochs

```bash
./build.sh --run
```

Jika Bochs masuk debugger dan menampilkan:

```text
<bochs:1>
```

ketik:

```text
c
```

lalu tekan Enter.

Jika muncul pop-up Bochs, pilih `Continue` atau `Alwayscont`.

---

## D. Uji Command Soal 2

Setelah OS tampil dan prompt muncul, jalankan command berikut satu per satu.

### 1. Uji `check`

```text
check
```

Output yang diharapkan:

```text
ok
```

### 2. Uji `add`

```text
add 5 3
```

Output yang diharapkan:

```text
8
```

### 3. Uji `sub`

```text
sub 10 2
```

Output yang diharapkan:

```text
8
```

### 4. Uji `fac`

```text
fac 6
```

Output yang diharapkan:

```text
720
```

Uji batas factorial:

```text
fac 120
```

Output yang diharapkan:

```text
know your limit little bro.
```

### 5. Uji `season`

```text
season winter
season spring
season summer
season fall
season radiant
```

Output yang diharapkan:

```text
winter mode
spring mode
summer mode
fall mode
radiant mode
```

Warna teks akan berubah sesuai mode season.

### 6. Uji `triangle`

```text
triangle 5
```

Output yang diharapkan:

```text
x
xx
xxx
xxxx
xxxxx
```

### 7. Uji `help`

```text
help
```

Output yang diharapkan adalah daftar command yang tersedia.

### 8. Uji `about`

```text
about
```

Output yang diharapkan adalah informasi singkat OS.

### 9. Uji `clear`

```text
clear
```

Layar akan dibersihkan.

---

## E. Cara Keluar dari Bochs

Jika menggunakan window Bochs, klik tombol close atau power pada window Bochs.

Jika berada di debugger Bochs, ketik:

```text
q
```

lalu tekan Enter.

Jika menjalankan dari terminal dan ingin menghentikan proses, tekan:

```text
Ctrl + C
```

---

## F. Penjelasan Kode Soal 2

### 1. `bootloader.asm`

File ini berfungsi sebagai bootloader. Bootloader dijalankan pertama kali oleh BIOS, kemudian membaca kernel dari floppy image dan memindahkannya ke memori.

### 2. `kernel.asm`

File ini berisi entry point assembly, fungsi `putInMemory`, dan fungsi `_getChar`. Fungsi `_getChar` membaca input keyboard menggunakan interrupt BIOS.

### 3. `kernel.c`

File ini berisi shell sederhana dan implementasi command. Command yang tersedia meliputi `check`, `add`, `sub`, `fac`, `season`, `triangle`, `clear`, `help`, dan `about`.

### 4. `Makefile`

File ini mengatur proses build bootloader, kernel, dan floppy image.

### 5. `build.sh`

Script ini mempermudah proses build dan run. Untuk build digunakan:

```bash
./build.sh
```

Untuk run digunakan:

```bash
./build.sh --run
```

---

## G. Hasil Akhir Soal 2

Struktur final ZIP tetap bersih:

```text
soal_2/
├── Makefile
├── README.md
├── bochsrc.txt
├── bootloader.asm
├── build.sh
├── kernel.asm
└── kernel.c
```

File hasil build dapat dibuat ulang saat runtime.

---

# Cleanup Setelah Testing

Command ini digunakan untuk mengembalikan repository ke kondisi bersih setelah testing. Jalankan dari root repository.

## 1. Stop QEMU jika masih berjalan

Jika QEMU masih terbuka, tutup window QEMU. Jika proses masih berjalan di background:

```bash
pkill qemu-system-x86_64 2>/dev/null || true
```

## 2. Stop Bochs jika masih berjalan

```bash
pkill bochs 2>/dev/null || true
```

## 3. Bersihkan runtime Soal 1

```bash
rm -rf soal_1/linux-6.1.1
rm -f soal_1/linux-6.1.1.tar.xz
rm -rf soal_1/rootfs_single
rm -rf soal_1/rootfs_multi
rm -rf soal_1/iso_root
```

Jika ingin mengosongkan hasil build `osboot`, jalankan:

```bash
rm -f soal_1/osboot/bzImage
rm -f soal_1/osboot/single.gz
rm -f soal_1/osboot/multi.gz
rm -f soal_1/osboot/farewell.iso
```

Folder `soal_1/osboot` tetap dipertahankan.

## 4. Bersihkan runtime Soal 2

```bash
rm -f soal_2/floppy.img
rm -f soal_2/bootloader.bin
rm -f soal_2/kernel.bin
rm -f soal_2/kernel.o
rm -f soal_2/kernel-asm.o
rm -f soal_2/bochslog.txt
```

## 5. Cek struktur akhir

```bash
tree -a
```

Struktur akhir yang diharapkan:

```text
.
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
```

---

# Urutan Screenshot yang Disarankan

## Soal 1

```text
1. Struktur folder soal_1.
2. Hasil ./kernel.sh atau bukti osboot/bzImage terbentuk.
3. Hasil ./single.sh dan file osboot/single.gz.
4. Boot ./qemu.sh --single dan hasil whoami.
5. Hasil net-up/nettest atau ping/wget.
6. Hasil ./multi.sh dan file osboot/multi.gz.
7. Login root pada multi-user.
8. Tes permission user henn.
9. Tes permission user hann.
10. Tes permission user viii.
11. Tes permission user kids.
12. Hasil party help, party list, party install hello.
13. Hasil fuse-demo.
14. Hasil ./iso.sh dan file osboot/farewell.iso.
15. Boot ./qemu.sh --all ke single-user.
16. Boot ./qemu.sh --all ke multi-user.
17. Hasil ./backup.sh.
```

## Soal 2

```text
1. Struktur folder soal_2.
2. Hasil ./build.sh.
3. Bochs berhasil boot.
4. check -> ok.
5. add 5 3 -> 8.
6. sub 10 2 -> 8.
7. fac 6 -> 720.
8. fac 120 -> know your limit little bro.
9. season winter/spring/summer/fall/radiant.
10. triangle 5.
11. help.
12. about.
13. clear.
```

---

# Zip Final

Setelah semua file bersih dan repository sudah berada di folder `SISOP-5-2026-IT-124`, buat ZIP final dari home:

```bash
cd ~
zip -r SISOP-5-2026-IT-124.zip SISOP-5-2026-IT-124
```

Cek hasil ZIP:

```bash
ls -lh SISOP-5-2026-IT-124.zip
```

---

# Kesimpulan

Dari dua soal pada Modul 5 ini, saya memahami beberapa konsep penting dalam Sistem Operasi.

* **Soal 1** memperlihatkan proses build kernel, pembuatan root filesystem, konfigurasi user, permission, networking, package manager sederhana, pembuatan ISO bootable, serta proses boot menggunakan QEMU.
* **Soal 2** memperlihatkan cara kerja bootloader dan kernel sederhana, penggunaan BIOS interrupt untuk input keyboard dan output layar, serta implementasi command shell sederhana pada sistem operasi 16-bit.

Secara keseluruhan, seluruh soal dapat dijalankan secara bertahap mulai dari proses build, booting emulator, pengujian user dan permission, pengujian jaringan, hingga pengujian command pada kernel sederhana.
