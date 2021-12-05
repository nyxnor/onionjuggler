# Compatibility

The required programs to OnionJuggler listed compatibility for different operating systems.

Information to install `tor` acquired on [community.torproject.org/relay/setup/bridge](https://community.torproject.org/relay/setup/bridge/) and and to install `stem` acquired on [stem.torproject.org](https://stem.torproject.org/download.html).

# packages from source

## tor

Build tor from source and install it:
```sh
git clone https://git.torproject.org/tor.git
sh autogen.sh
CPPFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" \ ./configure
make
make install
```

## Stem

Build Stem from source:
```sh
git clone https://git.torproject.org/stem.git
cd stem/
pip3 install -r requirements.txt
```

or install via pip:
```sh
easy_install pip
pip install stem
```

# OnionJuggler setup per operating system

The code is being tested on Debian and OpenBSD, but because of time and contributors limitation, it is not possible to test on every Unix-like system. Therefore, the rest of documentation is not complete.

Although the code is POSIX, it does not mean that the maintainer can indicate the correc `onionjuggler.conf` for every operating system, it is up to the user to test and we, the developers, are exempt of any liability that results of your failure.

The code works 100% on Debian.
The code is not complete on OpenBSD because of missing packages, will be shortly as it is resolved. (missing basez and service configuration file for vanguards).

## Debian

### tor

```sh
apt install -y apt-transport-https wget gpg
printf "deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -sc) main
#deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -sc) main
" | tee /etc/apt/sources.list.d/tor.list
wget -O- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null
apt update -y
apt install tor deb.torproject.org-keyring
```

### onionjuggler.conf

Use the default configuration file.

```sh
requirements="tor grep sed openssl basez git qrencode pandoc tar python3-stem dialog nginx"
```

## OpenBSD

### tor

```sh
printf "https://cdn.openbsd.org/pub/OpenBSD\n" > /etc/installurl
pkg_add tor
rcctl enable tor
rcctl start tor
```

### onionjuggler.conf

TODO: basez does not exist on OpenBSD, base64 is a part but missing base32 package, fix this).
```sh
privilege_command="doas"
tor_user="_tor"
tor_service="tor"
service_manager_control="rcctl"
etc_group_owner="wheel"
pkg_mngr_install="pkg_add"
requirements="tor grep sed openssl base64 git libqrencode pandoc tar py-stem ${dialog} ${web_server}"
data_dir="/var/tor"
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
echo "
RunAsDaemon 1
" | tee -a /etc/tor/torrc
```

### onionjuggler.conf

Untested.

```sh
dnf install python3-stem
```

## Arch Linux

```sh
pacman -Syu tor
echo "
DataDirectory /var/lib/tor
User tor
" | tee -a /ec/tor/torrc
systemctl enable --now tor
systemctl restart tor
```

### onionjuggler.conf

Untested.

```sh
pacman -S python-stem
```

### Void Linux

```sh
xbps-install -S tor
ln -s /etc/sv/tor /var/service/.
sv restart tor
```

### onionjuggler.conf

Untested.

## OpenSUSE

```sh
zypper install tor
echo "
RunAsDaemon 1
" | tee -a /etc/tor/torrc
systemctl enable --now tor
```

### onionjuggler.conf

Untested.


## NetBSD

### tor

```sh
echo "PKG_PATH=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -m)/$(uname -r)/All" > /etc/pkg_install.conf
pkg_add tor
ln -sf /usr/pkg/share/examples/rc.d/tor /etc/rc.d/tor
echo "tor=YES" >> /etc/rc.conf
/etc/rc.d/tor start
```

### onionjuggler.conf

Untested.

```sh
privilege_command="doas"
tor_user="_tor"
tor_service="tor"
service_manager_control="/etc/rc.d/tor"
etc_group_owner="wheel"
pkg_mngr_install="pkg_add"
requirements="tor grep sed openssl base64 git libqrencode pandoc tar py37-stem ${dialog} ${web_server}"
```

## FreeBSD

### tor
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
echo "
RunAsDaemon 1
" | tee -a /usr/local/etc/tor/torrc
echo "net.inet.ip.random_id=1" >> /etc/sysctl.conf
sysctl net.inet.ip.random_id=1
sysrc tor_setuid=YES
sysrc tor_enable=YES
service tor start
```

### onionjuggler.conf

Untested.

```sh
privilege_command="doas"
tor_user="_tor"
tor_service="tor"
service_manager_control="/etc/rc.d/tor"
etc_group_owner="wheel"
pkg_mngr_install="pkg install"
requirements="tor grep sed openssl base64 git libqrencode pandoc tar security/py-stem ${dialog} ${web_server}"
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

### onionjuggler.conf

Untested.
