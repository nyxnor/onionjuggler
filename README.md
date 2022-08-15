# OnionJuggler
[![shellcheck](https://github.com/nyxnor/onionjuggler/actions/workflows/main.yaml/badge.svg)](https://github.com/nyxnor/onionjuggler/actions/workflows/main.yaml)
[![CodeFactor](https://www.codefactor.io/repository/github/nyxnor/onionjuggler/badge/main)](https://www.codefactor.io/repository/github/nyxnor/onionjuggler/overview/main)
[![GitHub top language](https://img.shields.io/github/languages/top/nyxnor/onionjuggler.svg)](https://github.com/nyxnor/onionjuggler/search?l=Shell)
[![License](https://img.shields.io/github/license/nyxnor/onionjuggler.svg)](https://github.com/nyxnor/onionjuggler/blob/main/LICENSE)
[![Just works](https://img.shields.io/badge/works-on_my_machine-darkred.svg?style=flat)](https://en.wikipedia.org/wiki/Typewriter)


### Feature-rich onion service manager for UNIX-like operating systems written in POSIX compliant shellscript

OnionJuggler is a minimal requirement, portable collection of scripts and documentation to help the service operator juggle (manage) his onion(s).

**WARNING: `do not trust this repo yet`, backup your hs keys in another location. This project has not been released and should be considered for development only.**

Quick link to this repository: [git.io/onionjuggler](https://git.io/onionjuggler)

## Table of Contents

* [Introduction](#introduction)
  * [Images](#images)
  * [History](#history)
  * [Goal](#goal)
  * [Features](#features)
* [Requirements](#requirements)
* [Instructions](#instructions)
  * [Clone the repository](#clone-the-repository)
  * [Set custom variables](#set-custom-variables)
  * [Setup the environment](#setup-the-environment)
  * [Usage](#usage)
    * [tui](#tui)
    * [cli](#cli)
* [Featured on](#featured-on)
* [Contributors](#contributors)

## Introduction

### Images

![tui-dialog](images/tui-dialog.png)
![tui-whiptail](images/tui-whiptail.png)
![cli](images/cli.png)

### History

This project was started after seeing the amazing [OnionShare CLI python scripts](https://github.com/onionshare/onionshare/tree/develop/cli), which possibilitates ephemeral onion services that never touch the disk and can be run on Tails or Whonix easily. Then after seeing the [RaspiBlitz onion service bash script for the Raspberry Pi](https://github.com/rootzoll/raspiblitz/blob/v1.7/home.admin/config.scripts/internet.hiddenservice.sh), the idea to port it to any Debian distribution started. As the idea grew, using GNU Bash and Linux was a single point of failure [1](https://metrics.torproject.org/platforms.html) [2](https://metrics.torproject.org/webstats-tb-platform.html), so the making the script POSIX compliant to be compatible with any Unix-like system was a definitive goal.

### Goal

The goal of this project is:
* facilitate onion service management, from activating a service to adding client authorization to it, giving the full capabilities of editing files manually would have but with less tipying.
* show the that managing the onion service is much more than just using a webserver with your pages.
* distribution, from the source code level (FOSS) to the effect it takes when it allows anyone to run the code on any operating system, shell or service manager. Mitigation from a single point of failure

Mitigation from a single point of failure:
* **Kernel** from predominant `Linux` to also `BSD` and any other Unix-like system.
* **Shell** from predominant `Bash` to also any POSIX shell such as `ksh`, `(y,d)ash` and `Zsh` (emulating sh).
* **Service manager** from predominant `Systemd` to also `RC`, `OpenRC`, `SysVinit`, `Runit`.

Editing the tor configuration file (torrc) is not difficult, but automation solves problem of misconfiguration and having:
* less time spent by running a single line command
* no downtime by rejecting invalid configuration before applying them to be used
* complete uniformity
* graphical interface to help newbies

### Features

* [**Enable service**](https://community.torproject.org/onion-services/setup/) - Create directory if not existent (HiddenServiceDir), select onion version (HiddenServiceVersion), custom socket type being unix or tcp, with as many virtual ports as you would like, as well as targets (HiddenServicePort).
* **Disable service** - Remove service configuration from the torrc, the service will not be acessible anymore, but you can enable it again any time you want. Optionally purge the service, deleting its configuration and directory, which will delete its keys permanently.
* **Renew service address** - Focused on private onion services, if you ever leak its address, you can change its hostname, beware all of your authorized clients will be disconnected and the service keys will be permanently deleted.
* **Credentials** - Show hostname, clients, torrc block, qrencoded hostname.
* [**Onion authentication**](https://community.torproject.org/onion-services/advanced/client-auth/) - For v3 onion services only. This depends on client and server side configuration and works with a key pair, the client holds the private key part either generate by him (more safe) or given by the service operator and the onion service operator holds the public part. If any if
  * **Server** - Generate key pair or add public part, list client names and their public keys from `<HiddenServiceDir>/authorized_clients/<client>.auth`. If any client is configured, the service will not be acessible without authentication.
  * **Client** - Generate key pair or add public part, list your `<ClientOnionAuthDir>/<SOME_ONION>.auth_private`.
* [**Onion-Location**](https://community.torproject.org/onion-services/advanced/onion-location/) - For public onion services You can redirect your plainnet users to your onion service with this guide for nginx, apache2 and html header attributes.
* [**OpSec**](https://community.torproject.org/onion-services/advanced/opsec/) - Operation Security
  * [**Unix socket**](https://riseup.net/en/security/network-security/tor/onionservices-best-practices) - Support for enabling an onion service over unix socket to avoid localhost bypasses.
* **Web server** - Serve files with your hidden service using Nginx or Apache2 web server.
* **Usability** - There are two dialog boxes compatible with the project, `dialog` and `whiptail`.
* **Bulk** - Some commands can be bulked with the argument `@all` to include all services or clients depending on the option `--service` or `--client`, list enabled arguments`[SERV1,SERV2,...]` and `[CLIENT1,CLIENT2,...]`, the command will loop the variables and apply the combination.
* **Fool-proof** - The script tries its best to filter invalid commands and incorrect syntax. The commands are not difficult but at first sight may scare you. Don't worry, if it is invalid, it won't run to avoid tor daemon failing to reload because of invalid configuration. If an invalid command runs, please open an issue.

## Requirements

* General:
  * Unix-like system.
  * superuser privileges to call commands as root and the tor user

* Required programs:
  * **sh** - any POSIX shell: `dash` 0.5.4+, `bash` 2.03+, `ksh` 88+, `mksh` R28+, `yash` 2.29+, busybox `ash` 1.1.3+,  `zsh` 3.1.9+ (`zsh --emulate sh`) etc.
  * **tor** >= 0.3.5.7
  * **grep** >=0.9
  * **sed**
  * **openssl** >= 1.1 (Client Authorization - requires algorithm x25519, so it can't be LibreSSL)
  * **basez** >= 1.6.2 (Client Authorization)
  * **git** (Build)
  * **dialog**/**whiptail** (TUI)
  * **nginx**/**apache2** (Web server)

* Optional programs:
  * **(lib)qrencode** >= 4.1.1 (List)

* Development programs:
  * **pandoc** (Manual)
  * **shellcheck** (Review)

## Instructions

### Clone the repository

```sh
git clone https://github.com/nyxnor/onionjuggler.git
cd onionjuggler
```

### Set custom variables

You should not modify the default configuration on `/etc/onionjuggler/onionjuggler.conf`, it will be modified on every update. Your local configurations should be on `/etc/onionjuggler/conf.d/*.conf`.

To assign values to the variables, yyou can either:

* Open the mentioned configuration file with your favorite editor:
```sh
"${EDITOR:-vi}" /etc/onionjuggler/cond.d/local.conf
```

* or insert configuration to the end of the file with tee:
```sh
printf "tor_conf_dir=\"/etc/tor\"\n" | tee -a /etc/onionjuggler/cond.d/local.conf
```

* or edit with sed:
```sh
sed -i'' "s|^tor_conf_dir=.*|tor_conf_dir=\"/etc/tor\"|" /etc/onionjuggler/cond.d/local.conf
```

### Setup the enviroment

Run from inside the cloned repository to create the tor directories, create manual pages and copy scripts to path:
```sh
./configure.sh --install
```

### Usage

### configure.sh

**configure.sh** setup the environment for OnionJuggler by adding the scripts and manual pages to path and detecting your operating system to fit with its default configuration. It can also be used to uninstall. Common development use is to create manual pages, check shell syntax and do all of the aforementioned and give the git status for files to be commited. The update option is raw and only recommended for development as of now.

Install:
```sh
configure.sh -i
```

Uninstall:
```sh
configure.sh -d
```

Update (development only):
```sh
configure.sh -u
```

#### tui

**onionjuggler-tui** wraps the CLI in a Terminal User Interface.
Some TUI options will let you edit the authorization files, which is recommended to set your favorite text editor to an environment variable that will be tried on the following order: `DOAS_EDITOR`/`SUDO_EDITOR`, if empty will try `VISUAL`, if empty will try `EDITOR`, if empty WILL fallback to `Vi`.

Read the [tui manual](docs/onionjuggler-tui.1.md)
```sh
man onionjuggler-tui
```

To use the TUI, just run:
```sh
onionjuggler-tui
```

#### cli

**onionjuggler-cli** is the main script that manages the HiddenServices. Take a look at the documentation inside `docs` folder, there are many other onion services management guides. Read:

Don't forget the [cli manual](docs/onionjuggler-cli.1.md) and the [conf manual](docs/onionjuggler.conf.5.md) for advanced usage:
```sh
man onionjuggler-cli
man onionjuggler.conf
```

To create a service named `terminator`, it is as easy as possible:
```sh
onionjuggler-cli --on -s terminator -p 80
```
But can be as advanced as specifying all the parameters:
```sh
onionjuggler-cli --on --service terminator --socket unix --version 3 --port "80,127.0.0.1:80 443,127.0.0.1:443"
```

## Featured on

* [TorBox](https://github.com/radio24/TorBox) >= v.0.5.0

## Contributors

[![Contributors graph](https://contrib.rocks/image?repo=nyxnor/onionjuggler)](https://github.com/nyxnor/onionjuggler/graphs/contributors)
