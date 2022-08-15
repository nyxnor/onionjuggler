% onionjuggler.conf(5) Configuration file for OnionJuggler
% Written by nyxnor (nyxnor@protonmail.com)
% September 2069

# NAME

onionjuggler.conf - Configuration file for OnionJuggler


# DESCRIPTION

**onionjuggler.conf** is the configuration for for OnionJuggler, a combination of POSIX compliant scripts helps the interaction with onion service configuration and files to speed up usage and avoid misconfiguration. The system variables are defined by the default configuration file */etc/onionjuggler/onionjuggler.conf*. The configuration file is then sourced be used by the program. It defines where the hidden services are located, the owner of the DataDirectory older, the ControlPort to be used.
Variables defined inside _/etc/onionjuggler/conf.d/*.conf_ are parsed in lexical order and overwrite the default configuration.

The configuration file is parsed by the shell and interpreted as variables. When assigning a value to a variable, use double quotes to avoid word splitting: **variable**=*"value"*.

Variables set to and empty string, either *var=* or *var=""*, will run with default values.

# OPTIONS

## SYSTEM

**operating_system**

: Set operating system.

**onionjuggler_plugin**

: Only install specified plugins, else install everything. (Default: all plugins).

**pkg_mngr_install**

: Install the required packages via package manager. (Default: apt install -y).

**openssl_cmd**

: The OpenSSL command to create the certificate and private keys for Client Authorization using the x25519 algorithm. It must be the orignal OpenSSL v1.1 or later, not LibreSSL, as the latter does not support the aforementioned algorithm. (Default: openssl).

**webserver**

: Web server to serve a website. Compatible with *nginx* and *apache2*. (Default: nginx).

**webserver_conf**

: Web server configuration of the virtual hosts. With nginx and apache2 it must be a directory (sites-enabled, conf.d, conf, vhosts). With openbsd-httpd it is /etc/httpd.conf{.local}.

**website_dir**

: Specify the directory to check for website folders. (Default: /var/www).

**dialog_box**

: Terminal User Interface dialog box. Compatible with *dialog* and *whiptail*. (default: dialog).

**requirements**

: Necessary packages to fully control OnionJuggler. They will be checked first if installed already, if not, will install via using the *$pkg_mngr_install*. (Default: tor grep sed openssl basez qrencode dialog nginx")


## TOR DAEMON

**daemon_control**

: The service manager control command. Compatible with *systemctl* (Systemd), *service* (SysV init), *rcctl* or */etc/rc.d* (OpenRC), *sv* (Runit). (Default: systemctl).

**tor_daemon**

: The tor service name. Common names are *tor@default* and *tor*. (Default: tor@default)

**tor_user**

: The tor user that runs the tor process. Common usernames are *debian-tor*, *tor*, *_tor* (Default: debian-tor).

**tor_conf_user_group**

: The /etc directory group owner. Normally *root* or *wheel*. (Default: root:root)

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

**tor_hiddenserviceport_target_addr**

: Specify default HiddenServicePort target address. Useful for when the server is running on an external host related to the tor process. On Qubes-Whonix, you should set the Whonix Workstation Qubes IP address (Default: 127.0.0.1).


# FILES

**/etc/onionjuggler/onionjuggler.conf**

: Default system configuration file.

# EXAMPLES

* **tor_user**=tor

* **tor_conf**=/usr/local/etc/tor/torrc

* **tor_data_dir**=/usr/local/var/lib/tor

* **tor_data_dir_services**="\$\{tor_data_dir\}/services"

# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionjuggler/issues, if not solved, open a new one.


# SEE ALSO

onionjuggler-tui(1), onionjuggler-cli(1), vitor(8), tor(1), sh(1), regex(7), sed(1), grep(1), shellcheck(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
