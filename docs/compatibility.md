# Packages for OnionJuggler per system

Debian:
```sh
tor grep sed openssl basez git qrencode pandoc tar python3-stem dialog nginx
```

OpenBSD (TODO: basez does not exist on OpenBSD, fix this):
```sh
tor grep sed openssl basez git libqrencode pandoc tar py-stem dialog nginx
```

# Tor packages compatibility list

The required programs to OnionJuggler listed compatibility for different operating systems.

# tor

Source [TPO bridge setup](https://community.torproject.org/relay/setup/bridge/).

## Source

```sh
git clone https://git.torproject.org/tor.git
sh autogen.sh
CPPFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" \ ./configure
make
make install
```

## Linux

### Debian

```sh
apt install -y apt-transport-https wget gpg
echo "deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -sc) main
#deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/tor.list
wget -O- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null
apt update -y
apt install tor deb.torproject.org-keyring
```

### Fedora, CentOS, RHEL

```sh
dnf install epel-release -y
osys="centos" ## [centos(rhel)|fedora]
echo "
[tor]
name=Tor for Enterprise Linux $releasever - $basearch
baseurl=https://rpm.torproject.org/${osys}/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://rpm.torproject.org/${osys}/public_gpg.key
cost=100 " | tee /etc/yum.repos.d/tor.repo
dnf install tor -y
```

### Arch Linux

```sh
pacman -Syu tor
systemctl enable --now tor
systemctl restart tor
```

### Void Linux

```sh
xbps-install -S tor
ln -s /etc/sv/tor /var/service/.
sv restart tor
```

### OpenSUSE

```sh
zypper install tor
systemctl enable --now tor
```

## BSD

### OpenBSD

```sh
echo "https://cdn.openbsd.org/pub/OpenBSD" > /etc/installurl
pkg_add tor
rcctl enable tor
rcctl start tor
```

### NetBSD

```sh
echo "PKG_PATH=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -m)/$(uname -r)/All" > /etc/pkg_install.conf
pkg_add tor
ln -sf /usr/pkg/share/examples/rc.d/tor /etc/rc.d/tor
echo "tor=YES" >> /etc/rc.conf
/etc/rc.d/tor start
```

### FreeBSD

```sh
pkg bootstrap
pkg update -f
pkg install ca_root_nss
mkdir -p /usr/local/etc/pkg/repos
echo "FreeBSD: {
  url: pkg+https://pkg.freebsd.org/${ABI}/latest
}" | tee -a /usr/local/etc/pkg/repos/FreeBSD.conf
pkg update -f
pkg upgrade -y -f
pkg install tor
echo "net.inet.ip.random_id=1" >> /etc/sysctl.conf
sysctl net.inet.ip.random_id=1
sysrc tor_setuid=YES
sysrc tor_enable=YES
service tor start
```

### DragonflyBSD

```sh
cd /usr
make pkg-bootstrap
rehash
pkg-static install -y pkg
rehash
pkg install ca_root_nss
echo "DragonflyBSD: {
  url: pkg+https://mirror-master.dragonflybsd.org/
}" | tee /usr/local/etc/pkg/repos/df-latest
pkg update -f
pkg upgrade -y -f
pkg install tor
echo "tor_setuid=YES" >> /etc/rc.conf
echo "tor_enable=YES" >> /etc/rc.conf
service tor start
```


# Stem

Source: [Stem TPO](https://stem.torproject.org/download.html)

## Source

```sh
git clone https://git.torproject.org/stem.git
cd stem/
pip3 install -r requirements.txt
```

## Python Indexed Packages and for MacOSX

```sh
easy_install pip
pip install stem
```

## Linux

### Debian

```sh
apt-get install python3-stem
```

### Fedora

```sh
dnf install python3-stem
```

### Gentoo

```sh
emerge stem
```

### Arch Linux

```sh
pacman -S python-stem
```

## BSD

### FreeBSD

```sh
pkg install security/py-stem
```

### OpenBSD

```sh
pkg_add py-stem
```

### NetBSD

```sh
pkg_add py37-stem
```
