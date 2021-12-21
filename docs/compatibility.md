# Compatibility

**Warning**: OnionJuggler has only been tested on Debian and OpenBSD (almost complete). Contributions to improve current system or make it compatible with other systems is greatly appreciated.

The code works perfectly on Debian.
The code is not complete on OpenBSD because of missing packages, will be shortly as it is resolved. (missing basez and service configuration file for vanguards and httpd integration.

After setup, your operating system distro configuration file will be on /etc/onionjuggler/onionjuggler.conf. If it is not there of if there is an invalid value to your system, please open an issue on github. You can also override the default configuration file by adding *.conf files inside /etc/onionjuggler/conf.d.

# Building requirements from source

As a security practice, you can build the requirements from source. Other programs can also be compiled from source and the user should refer to their respective intructions.

## git

Source: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

Requirements: `autotools`, `curl`, `zlib`, `openssl`, `expat`, and `libiconv`
With `apt` or `dnf` you can use one of these commands to install the minimal dependencies for compiling and installing the Git binaries:
```sh
sudo apt-get install dh-autoreconf libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev
## or
sudo dnf install dh-autoreconf curl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel
```

Optionally add documentation in various formats (`doc`, `html` and `info`):
```sh
sudo dnf install asciidoc xmlto docbook2X
## or
sudo apt-get install asciidoc xmlto docbook2x
```

If you’re using a Debian-based distribution (Debian/Ubuntu/Ubuntu-derivatives), you also need the install-info package:
```sh
sudo apt-get install install-info
```

If you’re using a RPM-based distribution (Fedora/RHEL/RHEL-derivatives), you also need the getopt package (which is already installed on a Debian-based distro):
```sh
sudo dnf install getopt
```

Additionally, if you’re using Fedora/RHEL/RHEL-derivatives, due to binary name differences you need to do this:
```sh
sudo ln -s /usr/bin/db2x_docbook2texi /usr/bin/docbook2x-texi
```

```sh
git_version="2.34.1"
tar -zxf git-${git_version}.tar.gz
cd git-${git_version}
make configure
./configure --prefix=/usr
make all doc info
sudo make install install-doc install-html install-info
```

After this is done, you can also get Git via Git itself for updates:
```sh
git clone git://git.kernel.org/pub/scm/git/git.git
```

## tor

Source: https://gitweb.torproject.org/tor.git/tree/INSTALL

Build tor from source and install it:
```sh
git clone https://git.torproject.org/tor.git
sh autogen.sh
CPPFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" \ ./configure
make
make install
```

## stem

Source: https://stem.torproject.org/download.html

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

## basez

Source: http://www.quarkline.net/basez/download/README
```sh
basez_version="1.6.2"
wget http://www.quarkline.net/basez/download/basez-${basez_version}.tar.gz
tar -xzvf basez-${basez_version}.tar.gz
./configure
make
make install
```

## openssl

Source: https://github.com/openssl/openssl/blob/master/INSTALL.md
```sh
git clone https://github.com/openssl/openssl
cd openssl
./Configure
make
make install

```

## dialog

Source: https://invisible-island.net/dialog/dialog.html#download
```sh
wget https://invisible-island.net/datafiles/release/dialog.tar.gz
tar -xzvf dialog.tar.gz
cd dialog*
./configure
make
make install
```

## cabal

Source: https://gitlab.haskell.org/ghc/ghc/-/wikis/building/#building-and-porting-ghc

Cabal is used for building Pandoc and ShellCheck.
```sh
git clone --recurse-submodules https://gitlab.haskell.org/ghc/ghc.git
cd ghc
./configure
make
make install
cabal update
cabal install cabal-install
```

## pandoc

Source: https://github.com/jgm/pandoc/blob/2.16.2/INSTALL.md

Build [cabal](#cabal).
```sh
git clone https://github.com/jgm/pandoc
cd pandoc
cabal install
```

## shellcheck

Source: https://github.com/koalaman/shellcheck#compiling-shellcheck

Build [cabal](#cabal).
```sh
git clone https://github.com/koalaman/shellcheck
cd shellcheck
cabal install
```


# Install, enable and start tor per operating system

Information to install `tor` acquired on [community.torproject.org/relay/setup/bridge](https://community.torproject.org/relay/setup/bridge/).

## Debian

```sh
sudo apt install -y apt-transport-https wget gpg
printf "deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -sc) main
#deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -sc) main
" | sudo tee /etc/apt/sources.list.d/tor.list
wget -O- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null
sudo apt update -y
sudo apt install tor deb.torproject.org-keyring
sudo /usr/sbin/usermod -aG debian-tor "${USER}
```

## OpenBSD

```sh
printf "https://cdn.openbsd.org/pub/OpenBSD\n" > /etc/installurl
doas pkg_add tor
rcctl enable tor
rcctl start tor
```

## Fedora, CentOS, RHEL

```sh
dnf install epel-release -y
osys="centos" ## [centos(rhel)|fedora]
printf "
[tor]
name=Tor for Enterprise Linux $releasever - $basearch
baseurl=https://rpm.torproject.org/${osys}/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://rpm.torproject.org/${osys}/public_gpg.key
cost=100
" | tee /etc/yum.repos.d/tor.repo
dnf install tor -y
printf "
RunAsDaemon 1
" | tee -a /etc/tor/torrc
```

## Arch Linux

```sh
pacman -Syu tor
printf "
DataDirectory /var/lib/tor
User tor
" | tee -a /ec/tor/torrc
systemctl enable --now tor
systemctl restart tor
```

## Void Linux

```sh
xbps-install -S tor
ln -s /etc/sv/tor /var/service/.
sv restart tor
```

## OpenSUSE

```sh
zypper install tor
printf "
RunAsDaemon 1
" | tee -a /etc/tor/torrc
systemctl enable --now tor
```

## NetBSD

```sh
printf "PKG_PATH=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -m)/$(uname -r)/All\n" > /etc/pkg_install.conf
pkg_add tor
ln -sf /usr/pkg/share/examples/rc.d/tor /etc/rc.d/tor
printf "tor=YES\n" >> /etc/rc.conf
/etc/rc.d/tor start
```

## FreeBSD

```sh
pkg bootstrap
pkg update -f
pkg install ca_root_nss
mkdir -p /usr/local/etc/pkg/repos
printf "FreeBSD: {
  url: pkg+https://pkg.freebsd.org/${ABI}/latest
}" | tee -a /usr/local/etc/pkg/repos/FreeBSD.conf
pkg update -f
pkg upgrade -y -f
pkg install tor
printf "
RunAsDaemon 1
" | tee -a /usr/local/etc/tor/torrc
echo "net.inet.ip.random_id=1" >> /etc/sysctl.conf
sysctl net.inet.ip.random_id=1
sysrc tor_setuid=YES
sysrc tor_enable=YES
service tor start
```

## DragonflyBSD

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
