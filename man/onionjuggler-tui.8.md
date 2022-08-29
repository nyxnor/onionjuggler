% ONIONJUGGLER-TUI(8) Dinamically juggle with onion services with a POSIX compliant shell
% Written by nyxnor (nyxnor@protonmail.com)
% default_date

# NAME

onionjuggler-tui - OnionJuggler Terminal User Interface, also known as the *onionjuggler-cli wrapper menu*. Dinamically juggle with onion services with a POSIX compliant shell


# SYNOPSIS

**onionjuggler-tui** **command** [**--option**<=*ARGUMENT*>]\
**onionjuggler-tui** **[-V|--version]**
**onionjuggler-tui** **--help**

# DESCRIPTION

**onionjuggler-tui** is a part of OnionJuggler, a combination of POSIX compliant scripts helps the interaction with onion service configuration and files to speed up usage and avoid misconfiguration. The *onionjuggler-tui* wraps the *onionjuggler-cli* into a terminal dialog box.


# OPTIONS

**-V**, **-version**

: Print version information.

**-h**, **--help**

: Display a short help message and exit.

# FILES

**/etc/onionjuggler/dialogrc**

: Default dialog run commands file.


# ENVIRONMENT

**SUDO_EDITOR**, **DOAS_EDITOR**, **VISUAL**, **EDITOR**

: Use environment variables in the above order to define the editor, in case any are empty, fallback to the next. If every variable is empty, fallback to Vi(1).

**ONIONJUGGLER_SKIP_PRE_TOR_CHECK**

: If set to 1, skip pre run tor check to allow the script to start running if the tor is failing to parse its configuration. Note it does not disable the last tor check to apply configuration changes, that is, if the configuration is still invalid, nothing will be changed. This option is useful if you are certain the configuration check will be fixed by the command. As the scripts requires root and you are probably calling the script from an unpriviliged user, preserve the variable value through environment changes by assigning it after the command to run the onionjuggler script as another user and before the script name:
```
sudo ONIONJUGGLER_SKIP_PRE_TOR_CHECK=1 onionjuggler-tui
doas ONIONJUGGLER_SKIP_PRE_TOR_CHECK=1 onionjuggler-tui
```

# EXIT VALUE

**0**
: Success

**1**
: Fail


# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionjuggler/issues, if not solved, open a new one.


# SEE ALSO

onionjuggler.conf(5), onionjuggler-cli(8), onionjuggler-cli-auth-client(8), onionjuggler-cli-auth-server(8), onionjuggler-cli-web(8), tor(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
