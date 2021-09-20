# onionservice

### An easy to use Tor Hidden Service (Onion Services) manager

**WARNING: `do not trust this repo yet`, backup your hs keys in another location**

The goal is to manage services on the the tor configuration level, not the web server level. Also need to be as portable as possible, so the variables for paths are only contained inside onion.lib.

## Shells

Work on various operating systems and shells, not only one function, but all of the scripts.
Tested shells:
* (d)ash - to be close to POSIX compliant
* bash
* zsh - currently not working with the TUI

Abanon arrays to be posix compliant is not easy, but if it runs the fastest, therefore having the best performand, mostly because it is calling a light shell such as dash (/bin/sh symlinked to /bin/dash) on the shebang of the scripts.

## Usage

### Instructions

Clone the repository:
```sh
cd
git clone https://github.com/nyxnor/onionservice.git
cd onionservice
```

#### Setup

This step is necessary. It is ready for debian users, other distro may need to edit the `required` variables section inside `onionservice-cli`. For the menu, you also need to edit `onion.lib`.
Setup custom tor enviroment:
```sh
sh onionservice-cli setup env
```

#### Easy menu

Use the menu (not working with `zsh` currently):
```sh
sh onionservice-tui
```

#### Understanding

Read the manual:
```sh
man text/onionservice.man
```

Read a small description of the main script:
```sh
sh onionservice-cli
```

#### Recovery

Restore the latest torrc backup:
```sh
sh onionservice-cli setup torrc
```

#### Nice to have

If you want to call the script as you would call any program, from any folder just tiping its name, you should add the script to path:

Export script to path:
```sh
mkdir ~/scripts
ls -s onionservice-cli ~/scripts/
ls -s onion.lib ~/scripts/
ls -s onionservice-cli.bash_completion ~/scripts/
printf "PATH=\$PATH:~scripts\n" >> ~/.${SHELL##*/}rc
. ~/scripts
```

Now you can call the `onionservice-cli` from any directory you are without prepending with the shell name:
Try it out, go to any folder call the script:
```sh
cd
onionservice-cli
```

### Technical

Now that you have read the [manual](text/onionservice.man), the [insructions](README.md#INSTRUCTIONS) and optionally tested the [whiptail menu](onionservice-tui), you are prepared to understand what it does behind the curtains.
Read [TECHNICAL.md](https://github.com/nyxnor/onionservice/tree/main/TECHNICAL.md) for advanced usage.

### Requirements

* Unix system (paths break on windows cause they use \ for path)
* tor >= 0.3.5 (HiddenServiceVersion 3 for onion authentication)
* openssl >= 1.1+ (for onion authentication)
* basez >= 1.6.2 (for onion authentication)
* git >= 2.0+ (for cloning the repo and vanguards)
* qrencode >= 4.1.1 (for printing the hostname)
* sh under /bin/sh (or the closest to POSIX complian shell you want, ash, dash)
* systemd (for vanguards control)
* user with root privileges
* leave blank lines between Hidden Services torrc lines - the cli script create it correctly, no change needed when using this project, just be aware when editing your torrc or importing your torrc and deactivating a service, it will delete every line within the same block
* HiddenServiceDir different root path than DataDir (facilitates a lot backup and other detections, else would need to prefix every HiddenServiceDir with hs_*)

## Goal

* **Autonomy** - The onion service operator should have full control of tor functionalities and if he does not know how, he can learn reading the scripts. It also helps typing less commands and when not remembering full directories paths or file syntax. Client option to add '.auth_private' option also possible.
* **KISS** - Keep It Simple Stupid (At least I try). [Source](https://en.wikipedia.org/wiki/KISS_principle).
* **Portability** - POSIX compliant to work on different shells, customize path and ports with a sourced library. The [library](onion.lib) and the [cli]](onionservice-cli) and the [menu](onionservice-tui) are [POSIX compliant](https://www.gnu.org/software/guile/manual/html_node/POSIX.html), made possible studying the [pure-sh-bible](https://github.com/dylanaraps/pure-sh-bible). CLI tests pass on `sh`,`bash` and `zsh`. TUI tests pass on `sh` and `bash`, but not on `zsh`.
* **TUI** - The [menu](onionservice-tui) will have a hard time to make it POSIX compliant as it uses arrays for whiptail (arrays are undefined in POSIX), so it follows the [pure-bash-bible](https://github.com/dylanaraps/pure-bash-bible), but making some adjustments to fit `zsh` in the for loop as an example.
* **Standalone** - The [cli](onionservice-cli) can run standalone, menu is just an addon that calls the main script.
* **Correct syntax** - [shellcheck](https://github.com/koalaman/shellcheck) for synxtax verification.

## Features

* **Activate service** - Create directory if not existent, activate with custom socket type (unix or tcp) virtual port, target (localhost or remote).
* **Deactivate service** - Remove service configuration from the torrc, the service will not be acessible anymore, but you can activate it again any time you want. Optionally purge the service, deleting its configuration and directory, which will delete its keys permanently.
* **Renew service address** - Focused on private onion services, if you ever leak its address, you can change its hostname, beware all of your authorized clients will be disconnected and the service keys will be permanently deleted.
* **Credentials** - Show hostname, clients, torrc block, qrencoded hostname.
* **Onion authentication** - For v3 onion services only. This depends on client and server side configuration and works with a key pair, the client holds the private key part either generate by him (more safe) or given by the service operator and the onion service operator holds the public part. If any if
  * **Server** - Generate key pair or add public part, list client names and their public keys from `<HiddenServiceDir>/authorized_clients/<client>.auth`. If any client is configured, the service will not be acessible without authentication.
  * **Client** - Generate key pair or add public part, list your `<ClientOnionAuthDir>/<SOME_ONION>.auth_private`.
* **Onion-Location** - For public onion services You can redirect your plainnet users to your onion service with this guide for nginx, apache2 and html header attributes.
* **Backup** - Better be safe.
  * **Create** -  Backup of your `torrc` lines containing hidden service configuration, all of your directories of `HiddenServiceDir` and `ClientOnionAuthDir`. Guide to export the backup to a remote host with scp.
  * **Integrate** - Integrate hidden serivces lines configuration from `torrc` and the directories `HiddenServiceDir` and `ClientOnionAuthDir` to your current system. This option should be used after creating a backup and importing to the current host. Guide to import backup to the current host with scp.
* **Vanguards** - This addon protects against guard discovery and related traffic analysis attacks. A guard discovery attack enables an adversary to determine the guard node(s) that are in use by a Tor client and/or Tor onion service. Once the guard node is known, traffic analysis attacks that can deanonymize an onion service (or onion service user) become easier.
* **Bulk** - Some commands can be bulked with `all-clients`, `all-services`, `[SERV1,SERV2,...]` and `[CLIENT1,CLIENT2,...]`, the command will loop the variables and apply the combination.
* **Optional** - Some commands are optional so less typing. Also they may behave differently depending on how much information was given to be executed and that is expected. They are specified inside `<>` (e.g. `<VIRTPORT2>`)
* **Fool-proof** - The script tries to filter invalid commands and incorrect syntax. The commands are not difficult but the first look may scare you. Don't worry, if it is invalid, it won't run to avoid tor daemon failing to reload because of invalid configuration. If an invalid command runs, please open an issue.

## Bugs

* There are no accidents - Master Oogway
* Bugs, you may find - Master Yoda
* It is the program that should fear your commands and not the other way around - Mix of Pai Mei with Richard M. Stallman
* Please report the bug, open an issue with enough description to reproduce the steps and solve the problem.

## To-do

* Shellcheck the tui, it burns shellcheck brain.
* Bash completion [official package](https://github.com/scop/bash-completion/) and [debian guide](http://web.archive.org/web/20200507173259/https://debian-administration.org/article/317/An_introduction_to_bash_completion_part_2)
* [Whonix HS Guide](https://www.whonix.org/wiki/Onion_Services#Security_Recommendations). Important: This is not whonix and whonix is more secure as it has different access control over workstation and gateway, use that for maximum security and anonymity. This is just to get the best I can and implement it. Also, Whonix-anon is no Tails, check it out too.
* [Vanguards](https://github.com/mikeperry-tor/vanguards) menu option
* [Ronn-ng](https://github.com/apjanke/ronn-ng/) to build man pages from markdown instead of writing them manually :(