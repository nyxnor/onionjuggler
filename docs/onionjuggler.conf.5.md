% onionjuggler.conf(5) Configuration file for OnionJuggler
% Written by nyxnor (nyxnor@protonmail.com)
% September 2069

# NAME

onionjuggler.conf - Configuration file for OnionJuggler


# DESCRIPTION

**onionjuggler.conf** is the configuration for for OnionJuggler, a combination of POSIX compliant scripts helps the interaction with onion service configuration and files to speed up usage and avoid misconfiguration. The system variables are defined by the environment variable *ONIONJUGGLER_CONF*, but if it is empty, will read */etc/onionjuggler/onionjuggler.conf*. The configuration file is then sourced be used by the program. It defines where the hidden services are located, the owner of the DataDir folder, the ControlPort to be used.

The configuration file is parsed by the shell and interpreted as variables. When assigning a value to a variable, use double quotes to avoid word splitting: **variable**=*"value"*.

Variables set to and empty string, either *var=* or *var=""*, will run with default values.

# OPTIONS

## SYSTEM

**exec_cmd_alt_user**

: Command to run as another user, use to run as the root and the tor user. Compatible with *doas* and *sudo*. (Default: sudo).

**pkg_mngr_install**

: Install the required packages via package manager. (Default: apt install -y).

**openssl_cmd**

: The OpenSSL command to create the certificate and private keys for Client Authorization using the x25519 algorithm. It must be the orignal OpenSSL v1.1 or later, not LibreSSL, as the latter does not support the aforementioned algorithm. (Default: openssl).

**web_server**

: Web server to serve a website. Compatible with *nginx* and *apache2*. (Default: nginx).

**dialog_box**

: Terminal User Interface dialog box. Compatible with *dialog* and *whiptail*. (default: whiptail).

**requirements**

: Necessary packages to fully control OnionJuggler. They will be checked first if installed already, if not, will install via using the *$pkg_mngr_install*. (Default: tor grep sed openssl basez git qrencode tar python3-stem dialog nginx")


## TOR DAEMON

**daemon_control**

: The service manager control command. Compatible with *systemctl* (Systemd), *service* (SysV init), *rcctl* or */etc/rc.d* (OpenRC), *sv* (Runit). (Default: systemctl).

**tor_daemon**

: The tor service name. Common names are *tor@default* and *tor*. (Default: tor@default)

**tor_user**

: The tor user that runs the tor process. Common usernames are *debian-tor*, *tor*, *_tor* (Default: debian-tor).

**tor_conf_group**

: The /etc directory group owner. Normally *root* or *wheel*. (Default: root)

**tor_conf_dir**

: Base folder of torrc configuration. (Default: /etc/tor).

**tor_conf**

: The torrc, tor run commands file. (Default: /etc/tor/torrc).

**tor_data_dir**

: Specify the DataDirectory for tor. (Default: /var/lib/tor).

**tor_data_dir_services**

: Specify the HiddenServiceDir base directory, onion sevices data will be created inside this directory. (Default: /var/lib/tor/services).

**tor_data_dir_auth**

: Specify the ClientOnionAuthDir. (Default: /var/lib/tor/onion_auth).

**tor_control_port**

: Specify the ControlPort to use with Vanguards. (Default: 9051).

**tor_backup_dir**

: Specify the local directory to save your backups. (Default: $HOME/.onionjuggler/backup)

## TOR BROWSER

**tor_browser_dir**

: Specify the Tor Browser root path. (Default: this is where torbrowser-launcher saves it \$\{HOME\}/.local/share/torbrowser/tbb/\$(uname -m)/tor-browser_\$\{LANG%.*\}).

**tor_browser_data_dir**

: Specify the Tor Browser DataDirectory. (Default: Browser/TorBrowser/Data/Tor).

**tor_browser_conf**

: Specify the Tor Browser torrc path. (Default: Browser/TorBrowser/Data/Tor/torrc).

**tor_browser_data_dir_auth**

: Specify the Tor Browser ClientOnionAuthDir. (Default: Browser/TorBrowser/Data/Tor/onion-auth).


## GENERAL

**website_dir**

: Specify the directory to check for website folders. (Default: /var/www).

**vanguards_commit**

: Specify the wanted commit from Vanguards repository. (Default: 10942de93f6578f8303f60014f34de2fca345545).

# ENVIRONMENT

**ONIONJUGGLER_CONF**

: Use the environment variable to search for the configuration file, if the variable is empty, use the default confiugration on */etc/onionjuggler/onionjuggler.conf*.

# FILES

**/etc/onionjuggler/onionjuggler.conf**

: Default system configuration file.

# EXAMPLES

* **exec_cmd_alt_user**=doas

* **tor_user**=tor

* **tor_conf**=/usr/local/etc/tor/torrc

* **tor_data_dir**=/usr/local/var/lib/tor

* **tor_data_dir_services**="\$\{tor_data_dir\}/services"

# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionjuggler/issues, if not solved, open a new one.


# SEE ALSO

onionjuggler-tui(1), onionjuggler-cli(1), tor(1), sh(1), regex(7), sed(1), grep(1), shellcheck(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
