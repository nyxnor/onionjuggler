# ONION-CLI

**An easy to use Tor Hidden Service (Onion Services) manager**

The goal is to manage services on the the tor configuration level, not the web server level. Also need to be as portable as possible, so the variables for paths are only container inside onion.lib.

If you want extra functionalities to be a relay, bridge or connect to a bridge easily, you should check out [Torbox](https://github.com/radio24/TorBox).

**WARNING: `do not trust this repo yet`, backup your hs keys in another location**

## INSTRUCTIONS

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

### TECHNICAL

Now that you have read the manual, the insructions and optionally tested the menu, you are prepared to understand what it does behind the curtains.
Read [TECHNICAL.md](https://github.com/nyxnor/onion-cli/tree/main/TECHNICAL.md) for advanced usage.

## GOAL

* KYSS, portability to different systems, customize path, ports.
* The [library](onion.lib) and [main script](onion-service.sh) is aiming to be fully POSIX compliant studying the [pure-sh-bible](https://github.com/dylanaraps/pure-sh-bible)
* The [menu](onion-menu.sh) will never be POSIX compliant as it uses bashism such as whiptail, it follows the [pure-bash-bible](https://github.com/dylanaraps/pure-bash-bible).
* The [library](onion.lib) and [main script](onion-service.sh) can run entirely by themselves, menu if just an addon that calls the main script.
* Shell synxtax verification being done with [shellcheck](https://github.com/koalaman/shellcheck)

## BUGS

There are no accidents - Master Oogway
Bugs, you may find - Master Yoda

* Please report the bug, open an issue with enough description to reproduce the steps and solve the problem.

## TODO

* Bash completion [official package](https://github.com/scop/bash-completion/) [debian guide](http://web.archive.org/web/20200507173259/https://debian-administration.org/article/317/An_introduction_to_bash_completion_part_2)
* [Whonix HS Guide](https://www.whonix.org/wiki/Onion_Services#Security_Recommendations). Important: This is not whonix and whonix is more secure as it has different access control over workstation and gateway, use that for maximum security and anonymity. This is just to get the best I can and implement it. Also, Whonix-anon is no Tails, check it out too.
* [Vanguards](https://github.com/mikeperry-tor/vanguards) menu option
* [Ronn-ng](https://github.com/apjanke/ronn-ng/) to build man pages from markdown instead of writing them manually :(
* Something you would like to see to manage onion services? Please open an issue with `[Feature Request] something` on the title.