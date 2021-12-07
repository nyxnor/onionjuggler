% onionjuggler.conf(1) Configuration file for OnionJuggler
% Written by nyxnor (nyxnor@protonmail.com)
% September 2069

# NAME

onionjuggler.conf - Configuration file for OnionJuggler


# DESCRIPTION

**onionjuggler.conf** is the configuration for for OnionJuggler, a combination of POSIX compliant scripts helps the interaction with onion service configuration and files to speed up usage and avoid misconfiguration. The system variables are defined inside the file of the environment variable *ONIONJUGGLER_CONF*, but if the variable is empty, will read /etc/onionjuggler.conf. The configuration file is then sourced be used by the program. It defines where the hidden services are located, the owner of the DataDir folder, the ControlPort to be used.

The configuration file is parsed by the shell and interpreted as variables. When assigning a value to a variable, use double quotes to avoid word splitting: **variable**=*"value"*.

# OPTIONS

## SYSTEM

**privilege_command**

: Command to run as another user, use to run as the root and the tor user. Compatible with *doas* and *sudo*. (Default: sudo).

**tor_user**

: The tor user that runs the tor process. (Default: debian-tor).

**tor_service**

: The tor service name. (Default: tor@default.service)

**service_manager_control**

: The service manager control command. Compatible with *systemctl* (Systemd), *service* (SysV init), *rcctl* (OpenRC), *sv* (Runit). (Default: systemctl).

**etc_group_owner**

: The /etc directory group owner. (Default: root)

**pkg_mngr_install**

: Install the required packages via package manager. (Default: apt install -y).

**web_server**

: Web server to serve a website. Compatible with *nginx* and *apache2*. (Default: nginx).

**dialog_box**

: Terminal User Interface dialog box. Compatible with *dialog* and *whiptail*. (Default: dialog).

**requirements**

: Necessary packages to fully control OnionJuggler. They will be checked first if installed already, if not, will install via using the *$pkg_mngr_install*. (Default: tor grep sed openssl basez git qrencode tar python3-stem dialog nginx")


## TOR DAEMON

**torrc_root**

: Root folder of torrc configuration. (Default: /etc/tor).

**torrc**

: The torrc, tor run commands file. (Default: /etc/tor/torrc).

**data_dir**

: Specify the DataDirectory for tor. (Default: /var/lib/tor).

**data_dir_services**

: Specify the HiddenServiceDir root directory, onion sevices data will be created inside this directory. (Default: /var/lib/tor/services).

**data_dir_auth**

: Specify the ClientOnionAuthDir. (Default: /var/lib/tor/onion_auth).

**control_port**

: Specify the ControlPort to use with Vanguards. (Default: 9051).


## TOR BROWSER

**tor_browser_root**

: Specify the Tor Browser root path. (Default: this is where torbrowser-launcher saves it \$\{HOME\}/.local/share/torbrowser/tbb/\$(uname -m)/tor-tor_browser_\$\{LANG%.*\}).

**tor_browser_data_dir**

: Specify the Tor Browser DataDirectory. (Default: Browser/TorBrowser/Data/Tor).

**tor_browser_torrc**

: Specify the Tor Browser torrc path. (Default: Browser/TorBrowser/Data/Tor/torrc).

**tor_browser_data_dir_auth**

: Specify the Tor Browser ClientOnionAuthDir. (Default: Browser/TorBrowser/Data/Tor/onion-auth).


## GENERAL

**website_dir**

: Specify the directory to check for website folders. (Default: /var/www).

**vanguards_commit**

: Specify the wanted commit from Vanguards repository. (Default: 10942de93f6578f8303f60014f34de2fca345545).

**DIALOGRC**

: Specify the dialog configuration file. (Default: \$\{HOME\}/.dialogrc-onionjuggler)


## BACKUP VARIABLES

**scp_target_user**

: Specify the remote user to scp to your backup.

**scp_target_ip**

: Specify the remote ip address to scp you backup.

**scp_target_path**

: Specify the remote path to save your backup.

**scp_target_full**

: Specify the complete scp remove configuration as in user@ip:/path.

**hs_bk_dir**

: Specify the local directory to save your backups.

**local_ip**

: Specify the local ip to download your backups from.


# FILES

**/etc/onionjuggler.conf**

: Default system configuration file.


# ENVIRONMENT

**ONIONJUGGLER_CONF**

: Alternative system configuration file. If variables is empty, will use /etc/onionjuggler.conf.


# EXAMPLES

* **privilege_command**=doas

* **tor_user**=tor

* **torrc**=/usr/local/etc/tor/torrc

* **data_dir**=/usr/local/var/lib/tor

* **data_dir_services**="\$\{data_dir\}/services"

# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionjuggler/issues, if not solved, open a new one.


# SEE ALSO

onionjuggler-cli(1), tor(1), sh(1), regex(7), sed(1), grep(1), shellcheck(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
