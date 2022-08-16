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

# EXIT VALUE

**0**
: Success

**1**
: Fail


# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionjuggler/issues, if not solved, open a new one.


# SEE ALSO

onionjuggler-cli(8), onionjuggler.conf(5), vitor(8), tor(1), sh(1), regex(7), sed(1), grep(1), shellcheck(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
