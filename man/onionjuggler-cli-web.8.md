% ONIONJUGGLER-CLI-WEB(8) Manage webserver for onion services
% Written by nyxnor (nyxnor@protonmail.com)
% default_date

# NAME

onionjuggler-cli-web - Manage webserver for onion services


# SYNOPSIS

**onionjuggler-cli-web** [**--option**<=*ARGUMENT*>]\
**onionjuggler-cli-web [--getconf]**\
**onionjuggler-cli-web [--getopt]** [**--service** <*SERVICE*>]\
**onionjuggler-cli-web** [**--on**] [**--service** <*SERVICE*>] [**--folder** <*FOLDER*>]\
**onionjuggler-cli-web** [**--on**] [**--service** <*SERVICE*>] [**--folder** <*FOLDER*>] [**--no-check-service**] [**--port** <*VIRTPORT[:TARGET]*>]\
**onionjuggler-cli-web** [**--off**] [**--service** <*SERVICE*>]\
**onionjuggler-cli-web** [**--list**]\
**onionjuggler-cli-web** [**-V**|**--version**]
**onionjuggler-cli-web** [**-h**|**--help**]


# DESCRIPTION

**onionjuggler-cli-web** helps manage webserver configuration for onion services.


# OPTIONS

**--on** **--service** <*SERV*> **--folder** <*FOLDER*>

: Enable a website using a specific onion service by creating a configuration file inside the web server folder by default, the folder name is to be considered the wanted folder inside website_dir variable defined on /etc/onionjuggler. If the path starts with forward slash "/" or tilde and slash "~/", that path will be considered instead. File(s) modified: $webserver_conf_dir.
```
onionjuggler-cli-web --on --service nextcloud --folder nextcloud-local-site
```

**--off** **--service** <*SERV*>

: Disable a website from a specific onion service by removing its configuration file from the webserver folder. File(s) modified: $webserver_conf_dir
```
onionjuggler-cli-web --off --service nextcloud
```

**--list**

: List enabled websites, meaning the configuration files inside the webserver folder /etc/${webserver}/sites-enabled/. File(s) modified: none.
```
onionjuggler-cli-web --list
```

**-V**, **--version**

: Print version information.

**--getconf**

: Print configuration in the format **key**="*val*".

**--getopt**

: Print option parsing results.

**-h**, **--help**
: Display the script help message. Abscense of any parameter will also have the same effect.
```
onionjuggler-cli-web -h
onionjuggler-cli-web --help
```

**-R**, **--restart**, **-r**, **--reload**
: Signal tor daemon to restart or reload after the CLI edits tor's configuration files. (Default: reload)


# FILES

**/usr/share/onionjuggler/defaults.sh**

: Default library

**/etc/onionjuggler/onionjuggler.conf**

: Default system configuration file.

**/etc/onionjuggler/conf.d/\*.conf**

: Local configuration files that overrrite the default one.


# EXIT VALUE

**0**
: Success

**>0**
: Fail


# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionjuggler/issues, if not solved, open a new one.


# SEE ALSO

onionjuggler-tui(8), onionjuggler.conf(5), vitor(8), tor(1), sh(1), regex(7), sed(1), grep(1), shellcheck(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
