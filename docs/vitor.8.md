% vitor(8) Edit tor configuration files safely
% Written by nyxnor (nyxnor@protonmail.com)
% September 2069

# NAME

vitor - Is a visudo/vidoas but for tor configuration files written in POSIX compliant shell.


# SYNOPSIS

**vitor** [**-h**] [**-f** *tor_conf*] [**-t** *tor_user*]\

# DESCRIPTION

*vitor** is a part of OnionJuggler, a combination of POSIX compliant scripts helps the interaction with onion service configuration and files to speed up usage and avoid misconfiguration. *vitor* creates a temporary copy of the file specified on *tor_conf* and if file doesn't exist, the editor will create one. To get the editor value, it is checked for the environment variables to open the editor with the *SUDO_EDITOR*/*DOAS_EDITOR*, if they are empty try *VISUAL*, if it is also empty try *EDITOR*, if it is also empty fallback to Vi(1). After exiting the editor, the temporary copy is checked with *tor -f temp_file --verify-config* and if it is invalid, warn the user about the errors and press enter to continue (loop opens the editor again) or ^C to interrupt which will delete the temporary file. If the configuration if valid, save the temporary copy to its original location.


# OPTIONS

**-h**

: Display a short help message and exit.

**-f** *tor_conf*

: Specify the configuration file to open. If *tor_conf* is not set, default to /etc/tor/torrc.

**-u** *tor_user*

: Specify the tor user to run the daemon as. If *tor_user* is not set, the *tor_conf* must contain the \"User\" option already.


# ENVIRONMENT

**SUDO_USER**, **DOAS_USER**

: Used to check where its not only running *vitor* as root but also specifying the command to runuser tor.

**SUDO_EDITOR**, **DOAS_EDITOR**, **VISUAL**, **EDITOR**

: Use environment variables in the above order to define the editor, in case any are empty, fallback to the next. If every variable is empty, fallback to Vi(1).


# EXIT VALUE

**0**
: Success only if the *tor_conf* has been modified and the configuration is valid.

**1**
: Fail in any invalid configuration or unmodified file.


# BUGS

It is not possible to edit the "User" option on the tor configuration file.


# SEE ALSO

onionjuggler-cli(1), onionjuggler-tui(1), onionjuggler.conf(5), tor(1), sh(1), regex(7), sed(1), grep(1), shellcheck(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
