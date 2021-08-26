# ONION-CLI

**An easy to use Tor Hidden Service (Onion Services) manager**

The goal is to manage services on the the tor configuration level, not the web server level. Also need to be as portable as possible, so the variables for paths are only container inside onion.lib.

If you want extra functionalities to be a relay, bridge or connect to a bridge easily, you should check out [Torbox](https://github.com/radio24/TorBox).

Stage is `do not trust this repo yet`.

## INSTRUCTIONS

Use the menu:

```bash
bash onion-menu.sh
```

Read the manual:

```bash
man ./text/onion-cli.man
```

Read a small description of the script:

```bash
bash onion-service.sh
```

More detailed description of each functionality coming soon.

## BUGS

There are no accidents - Master Oogway

* Please report the bug, open an issue with enough description to reproduce the steps and solve the problem.

## TODO

* [Vanguards](https://github.com/mikeperry-tor/vanguards)
* [Ronn-ng](https://github.com/apjanke/ronn-ng/) to build man pages from markdown instead of writing them manually :(
* Something you would like to see to manage onion services? Please open an issue with `[Feature Request] something` on the title.