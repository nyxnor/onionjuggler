# onion-cli

**An easy to use Tor Hidden Service (Onion Services) manager**

The goal is to manage services on the the tor configuration level, not the web server level. Also need to be as portable as possible, so the variables for paths are only container inside onion.lib.

If you want extra functionalities to be a relay, bridge or connect to a bridge easily, you should check out [Torbox](https://github.com/radio24/TorBox).

**WARNING: `do not trust this repo yet`, backup your hs keys in another location**

## Usage

### Instructions

Clone the repository:
```sh
cd
git clone https://github.com/nyxnor/onion-cli.git
cd onion-cli
```

Use the menu (only bash):
```sh
bash onion-menu.sh
```

Read the manual:
```sh
man ./text/onion-cli.man
```

Read a small description of the main script:
```sh
bash onion-service.sh
```

### Technical

Now that you have read the [manual](text/onion-cli.man), the [insructions](README.md#INSTRUCTIONS) and optionally tested the [bash menu](onion-menu.sh), you are prepared to understand what it does behind the curtains.
Read [TECHNICAL.md](https://github.com/nyxnor/onion-cli/tree/main/TECHNICAL.md) for advanced usage.

### Requirements

* Unix system (paths break on windows cause they use \ for path)
* tor >= 0.3.5
  * HiddenServiceVersion 3 (for onion authentication)
* openssl >= 1.1+ (for onion authentication)
* basez >= 1.6.2 (for onion authentication)
* git >= 2.0+ (for cloning the repo and vanguards)
* qrencode >= 4.1.1 (for printing the hostname)
* bash under /bin/bash (soon the [main script](onion-service.sh) aims to be POSIX compliant)
* leave blank lines between Hidden Services torrc lines - script create it correctly, no change needed when using this script, just be aware when importing your torrc and deactivating a service, it will delete every line within the same block
* systemd for vanguards control
* user with root privileges
* Reserved words and Utilities - function, printf, command, while, for, do, done, case, esac, in, IFS, if, elif, else, fi, cp, mv, rm, sed, cut, grep, tail, tee.

##

## Goal

* **KISS** - Keep It Simple Stupid
* **Portability** - POSIXE compliant to work on different shells, customize path, ports.
* **POSIX compliant** - The [library](onion.lib) and [main script](onion-service.sh) is aiming to be fully POSIX compliant studying the [pure-sh-bible](https://github.com/dylanaraps/pure-sh-bible). The hard part is not using arrays cause it is not compliant to the spec.
* **Bashism** - The [menu](onion-menu.sh) will never be POSIX compliant as it uses bashism such as whiptail, it follows the [pure-bash-bible](https://github.com/dylanaraps/pure-bash-bible).
* **Autonomy** - The [library](onion.lib) and [main script](onion-service.sh) can run entirely by themselves, menu if just an addon that calls the main script.
* **Correct syntax** - [shellcheck](https://github.com/koalaman/shellcheck) for synxtax verification.

## Bugs

* There are no accidents - Master Oogway
* Bugs, you may find - Master Yoda
* It is the program that should fear your commands and not the other way aroung - Mix of Pai Mei with Richard M. Stallman

* Please report the bug, open an issue with enough description to reproduce the steps and solve the problem.

## To-do

* Bash completion [official package](https://github.com/scop/bash-completion/) [debian guide](http://web.archive.org/web/20200507173259/https://debian-administration.org/article/317/An_introduction_to_bash_completion_part_2)
* [Whonix HS Guide](https://www.whonix.org/wiki/Onion_Services#Security_Recommendations). Important: This is not whonix and whonix is more secure as it has different access control over workstation and gateway, use that for maximum security and anonymity. This is just to get the best I can and implement it. Also, Whonix-anon is no Tails, check it out too.
* [Vanguards](https://github.com/mikeperry-tor/vanguards) menu option
* [Ronn-ng](https://github.com/apjanke/ronn-ng/) to build man pages from markdown instead of writing them manually :(
* Something you would like to see to manage onion services? Please open an issue with `[Feature Request] something` on the title.