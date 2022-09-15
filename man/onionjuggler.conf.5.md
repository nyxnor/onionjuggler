% ONIONJUGGLER.CONF(5) Configuration file for OnionJuggler
% Written by nyxnor (nyxnor@protonmail.com)
% default_date

# NAME

onionjuggler.conf - Configuration file for OnionJuggler


# DESCRIPTION

**onionjuggler** environment is easily customizable to any Unix-like operating
system due to be written in POSIX compliant Shellscript and every tor
directory can be chosen via variables.

The default configuration file _/etc/onionjuggler/onionjuggler.conf_ is
replaced on every upgrade, so changes to this file are not persisted.
Because of this, it is advised not to edit this file. This is the first
configuration to file to be read and has the lowest priority.

Files in _/etc/onionjuggler/conf.d/\*.conf_ are reserved to packages that
want to customize onionjuggler without overwriting the main configuration file
to avoid conflicts. Users should avoid customizing files in this directory
because it may conflict or take lower precedence that files shipped by a
package.

The file _/usr/local/etc/onionjuggler/onionjuggler.conf_ and files in
_/usr/local/etc/onionjuggler/conf.d/\*.conf_ are reserved exclusively to the
local administrator. Any other entity must not write files to this directory.
These are the last files to be read and have the highest priority.

It is recommended to prefix all filenames in the _conf.d_
directory with a two-digit number and a dash, to simplify ordering of the files
and overrided default files with user defined setting using a higher prefix
number compared to the one shipped by the system.

Variables set to and empty string, either *var=* or *var=""*, will run with
default values, that may not be suitable for every system, so enforce the
desired values by assigning every configuration option. 

Before running any script for the first time after changing a configuration
option, it is recommended to run the onionjuggler script with the option
_--getconf_, as it will print what the onionjuggler program read as options.

### Order configuration files are sourced:

- /etc/onionjuggler/onionjuggler.conf\
- /etc/onionjuggler/conf.d/\*.conf\
- /usr/local/etc/onionjuggler/onionjuggler.conf\
- /usr/local/etc/onionjuggler/conf.d/\*.conf

### Rules for sourcing files:

- when inside the _conf.d_ directories, source files in lexical order\
- file names must end with the '.conf' extension

### Rules for writing the configuration files:

- must be POSIX compliant Shellscript, else the source will fail\
- assign all variables to the desired values, else default values will be used\
- variables should use double quotes to avoid unwanted expansions


# OPTIONS

## SYSTEM

**operating_system**

: Set operating system. Recognized values: *debian*, *tails*, *anon-gateway*, *anon-workstation*, *fedora*, *arch*, *openbsd*.

**onionjuggler_plugin**

: Only allow specified plugins to run, if empty, allow every plugin. (Default: **all plugins**).

**openssl_cmd**

: The OpenSSL command to create the certificate and private keys for Client Authorization using the x25519 algorithm. It must be the orignal OpenSSL v1.1 or later, not LibreSSL, as the latter does not support the aforementioned algorithm. (Default: **openssl**).

**webserver**

: Webserver to serve a website. Compatible with *nginx* and *apache2*. (Default: **nginx**).

**webserver_conf_dir**

: Webserver configuration directory of the virtual hosts. (Default: **/etc/${webserver}**).

**website_dir**

: Specify the directory to check for website folders. (Default: **/var/www**).

**dialog_box**

: Terminal User Interface dialog box. Compatible with *dialog* and *whiptail*. (Default: **dialog**).


## TOR DAEMON

**daemon_control**

: The service manager control command. Compatible with *systemctl* (Systemd), *service* (SysV init), *rcctl* or */etc/rc.d* (OpenRC), *sv* (Runit). (Default: systemctl).

**tor_daemon**

: The tor service name. Common names are *tor@default* and *tor*. (Default: **tor@default**)

**tor_user**

: The tor user that runs the tor process. Common usernames are *debian-tor*, *tor*, *_tor* (Default: **debian-tor**).

**tor_conf_user_group**

: The /etc directory group owner. Normally *root* or *wheel*. (Default: **root:root**)

**tor_conf_dir**

: Base folder of torrc configuration. (Default: **/etc/tor**).

**tor_conf**

: The tor configuration file that will be modified. It is recommended to a set a separate configuration file to be managed by onionjuggler, one that is included by tor, as there could be some unpredicated issues if the file is modified manually. Read about _%include_ on the _torrc(1)_ man. (Default: **${tor_conf_dir}/torrc**).

**tor_main_torrc_conf**

: The main tor configuration file that tor reads. It is the file specified to the tor daemon with the option _-f FILE_ or _--torrc-file FILE_. This file won't be modified unless it is set as value to the **tor_conf** option, its purpose is to fully verify the tor configuration. (Default: **${tor_conf_dir}/torrc**).

**tor_defaults_torrc_conf**

: The tor defaults configuration file that tor reads. It is the file specified to the tor daemon with the option _--defaults-torrc FILE_. This file won't be modified unless it is set as value to the **tor_conf** option, its purpose is to fully verify the tor configuration. (Default: **${tor_conf}-defaults**).

**tor_data_dir**

: Specify the DataDirectory for tor. (Default: /var/lib/tor).

**tor_data_dir_services**

: Specify the HiddenServiceDir base directory, onion sevices data will be created inside this directory. (Default: **${tor_data_dir}/services**).

**tor_data_dir_auth**

: Specify the ClientOnionAuthDir. (Default: **${tor_data_dir}/onion_auth**).


# FILES

**/etc/onionjuggler/onionjuggler.conf**

: Default configuration file.

**/etc/onionjuggler/conf.d/\*.conf**

: Packers configuration directory.

**/usr/local/etc/onionjuggler/onionjuggler.conf**

: Local administrator default configuration file.

**/usr/local/etc/onionjuggler/conf.d/\*.conf**

: Local administrador configuration directory.


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
