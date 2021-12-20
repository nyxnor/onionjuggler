% onionjuggler-tui(1) Dinamically juggle with onion services with a POSIX compliant shell
% Written by nyxnor (nyxnor@protonmail.com)
% September 2069

# NAME

onionjuggler-tui - OnionJuggler Terminal User Interface, also known as the *onionjuggler-cli wrapper menu*. Dinamically juggle with onion services with a POSIX compliant shell


# SYNOPSIS

**onionjuggler-tui** **command** [**--option**<=*ARGUMENT*>]\
**onionjuggler-tui** [**--config** *ONIONJUGGLER_CONF*]\
**onionjuggler-tui** **--help**

# DESCRIPTION

**onionjuggler-tui** is a part of OnionJuggler, a combination of POSIX compliant scripts helps the interaction with onion service configuration and files to speed up usage and avoid misconfiguration. The *onionjuggler-tui* wraps the *onionjuggler-cli* into a terminal dialog box.


# OPTIONS

**-h**, **--help**

: Display a short help message and exit.

**-C**, **--config** *ONIONJUGGLER_CONF*

: Specify and alternative configuration file to override default configuration.


# FILES

**/usr/local/bin/onionjuggler-cli**

: OnionJuggler TUI will call the CLI to execute the tasks after the dialog options have been selected.

**/etc/onionjuggler/dialogrc**

: Default dialog run commands file.


# ENVIRONMENT

**ONIONJUGGLER_CONF**

: The environmental variable will override all previous options.

**VISUAL**, **EDITOR**

: Use the default text editor when editing files on the TUI, else will fallback to Vi(1).

# EXIT VALUE

**0**
: Success

**1**
: Fail


# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionjuggler/issues, if not solved, open a new one.


# SEE ALSO

onionjuggler-cli(1), onionjuggler.conf(5), tor(1), sh(1), regex(7), sed(1), grep(1), shellcheck(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
