% ONIONJUGGLER.CONF(5) Configuration file for OnionJuggler
% Written by nyxnor (nyxnor@protonmail.com)
% default_date

# NAME

onionjuggler.conf - Configuration file for OnionJuggler


# DESCRIPTION

**onionjuggler.conf** is the configuration for OnionJuggler. The default configuration file */etc/onionjuggler/onionjuggler.conf* is replaced on every upgrade user should assign variables inside _/etc/onionjuggler/conf.d/*.conf_, files in this directory are parsed in lexical order and overwrite the default configuration.

The configuration file is parsed by the shell and interpreted as variables. When assigning a value to a variable, use double quotes to avoid word splitting: **variable**=*"value"*.

Variables set to and empty string, either *var=* or *var=""*, will run with default values.

# OPTIONS

## SYSTEM

**operating_system**

: Set operating system. Recognized values: debian, tails, anon-gateway, anon-workstation, fedora, arch, openbsd.

**onionjuggler_plugin**

: Only allow specified plugins to run, if empty, allow every plugin. (Default: all plugins).

**openssl_cmd**

: The OpenSSL command to create the certificate and private keys for Client Authorization using the x25519 algorithm. It must be the orignal OpenSSL v1.1 or later, not LibreSSL, as the latter does not support the aforementioned algorithm. (Default: openssl).

**webserver**

: Webserver to serve a website. Compatible with *nginx* and *apache2*. (Default: nginx).

**webserver_conf_dir**

: Webserver configuration directory of the virtual hosts. (Default: /etc/nginx).

**website_dir**

: Specify the directory to check for website folders. (Default: /var/www).

**dialog_box**

: Terminal User Interface dialog box. Compatible with *dialog* and *whiptail*. (Default: dialog).


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


# FILES

**/etc/onionjuggler/onionjuggler.conf**

: Default system configuration file. Replaced on every upgrade.

**/etc/onionjuggler/conf.d/\*.conf**

: User configuration file. Create files in the _conf.d_ directory with the extension _.conf_.


# EXAMPLES

* **tor_user**=tor

* **tor_conf**=/usr/local/etc/tor/torrc

* **tor_data_dir**=/usr/local/var/lib/tor

* **tor_data_dir_services**="\$\{tor_data_dir\}/services"

# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionjuggler/issues, if not solved, open a new one.


# SEE ALSO

onionjuggler-tui(8), onionjuggler-cli(8), onionjuggler-cli-auth-client(8), onionjuggler-cli-auth-server(8), onionjuggler-cli-web(8), tor(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
