% ONIONJUGGLER-CLI(8) Dinamically juggle with onion services with a POSIX compliant shell
% Written by nyxnor (nyxnor@protonmail.com)
% default_date

# NAME

onionjuggler-cli - Dinamically juggle with onion services with a POSIX compliant shell


# SYNOPSIS

**onionjuggler-cli** [**--option**<=*ARGUMENT*>]\
**onionjuggler-cli --on** [**--service**=<*SERVICE*>] [**--hs-version**=<*VERSION*>] [**--socket**=<*tcp*>] [**--port**=<*VIRTPORT*[:*TARGET*],[*VIRTPORTn*][:*TARGETn*]>] [**--gateway**]\
**onionjuggler-cli --on**  [**--service**=<*SERVICE*>] [**--version**=<*VERSION*>] [**--socket**=<*unix*>] [**--port**=[*VIRTPORT*,[*VIRTPORT2*]>]\
**onionjuggler-cli --off** [**--service**=<*SERV1*,*SERV2*,*...*>] [**--purge**]\
**onionjuggler-cli --list** [**--service**=<*@all*|*SERV1*,*SERV2*,*...*>] [**--quiet**]\
**onionjuggler-cli --renew** [**--service**=<*@all*|*SERV1*,*SERV2*,*...*>]\
**onionjuggler-cli** [**--signal**=<*reload*|*restart*|*none*>]\
**onionjuggler-cli [--getconf]**\
**onionjuggler-cli [--getopt]** [**--service**=<*SERVICE*>]\
**onionjuggler-cli [-V|--version]**\
**onionjuggler-cli** [**-h**|**--help**]


# DESCRIPTION

**onionjuggler-cli** helps onion service creation, deletion, listing.


# OPTIONS

**--on** **--service**=<*SERV*> **--version**=*3* **--socket**=*tcp* **--port**=<*VIRTPORT*:<*TARGET*>,<*VIRTPORTn*>:<*TARGETn*>> **--gateway**

: Enable an onion service using TCP socket (addr:port) as target. If the TARGET is only the port of it TARGET was not provided, will use the same port as VIRTPORT and bind to 127.0.0.1. TARGET examples: 127.0.0.1:80, 192.168.1.100:80. File(s) modified: torrc.
```
onionjuggler-cli --on --service=ssh --version=3 --socket=tcp --port=22
onionjuggler-cli --on --service=ssh --port=22:127.0.1:22
onionjuggler-cli --on --service=ssh --port="80:127.0.0.1:80 443:127.0.0.1:443"
onionjuggler-cli --on --service=ssh --port="80:127.0.0.1:80,443:127.0.0.1:443"
onionjuggler-cli --on --service=ssh --port="80,443"
```
By default, services created on a Qubes-Whonix Gateway uses the Whonix Workstation qube IP address, services created on a Non-Qubes-Whonix uses the IP address 10.152.152.11. If you are on Whonix Gateway want to enforce the creation of a service to be running on the Whonix-Gateway (for itself), for example and onion service to ssh to the Gateway, and you haven't set the target, just the virtual port, use the option *--gateway*:
```
onionjuggler-cli --on --service=ssh --socket=tcp --port=22 --gateway
```

**--on** **--service**=<*SERV*> **--version**=*3* **--socket**=*unix* **--port**=<*VIRTPORT*,<*VIRTPORT2*>>

: Enable an onion service using UNIX socket (unix:path) as target. The TARGET is handled automatically by the script. This method avoids leaking the onion service address to the local network. File(s) modified: torrc.
```
onionjuggler-cli --on --service=ssh --version=3 --socket=unix --port=22
onionjuggler-cli --on --service=ssh --version=3 --socket=unix --port=22,80
```

**--off** **--service**=<*SERV1*,*SERV2*,*...*> <*--purge*>

: Disable an onion service by removing it configuration lines (HiddenService) from the torrc. Optionally purge its data directory, which will delete permanently the onion service folder (HiddenServiceDir). File(s) modified: torrc and optionally HiddenServiceDir.
```
onionjuggler-cli --off --service=ssh
onionjuggler-cli --off --service=ssh,xmpp
onionjuggler-cli --off --service=ssh,xmpp --purge
```

**--list** **--service**=<*@all*|*SERV1*,*SERV2*,*...*> <*--quiet*>

: List onion service information: hostname (address) and in QR encoded format, clients names and quantity, status if service is active or inactive regarding the torrc lines (un)present and the HiddenServiceDir presence, the torrc block. File(s) modified: none.
```
onionjuggler-cli --list --service=ssh
onionjuggler-cli --list --service=ssh,xmpp
onionjuggler-cli --list --service=@all
onionjuggler-cli --list --service=@all --quiet
```

**--renew** **--service**=<*@all*|*SERV1*,*SERV2*,*...*>

: Renew onion service hostname (.onion domain) and clients (inside HiddenServiceDir/authorized_clients/). The onion service keys (hs_ed25519_public_key and hs_ed25519_private_key) will be removed to override the hostname file. File(s) modified: HiddenServiceDir.
```
onionjuggler-cli --renew --service=ssh
onionjuggler-cli --renew --service=ssh,xmpp
onionjuggler-cli --renew --service=@all
```

**-V**, **--version**

: Print version information.

**--getconf**

: Print configuration in the format **key**="*val*".

**--getopt**

: Print option parsing results.

**--signal**=<*reload*|*hup*|*restart*|*int*|*no*|*none*>

: Send specific signal commands to the tor daemon. Sending the _restart|int_ signal is useful for correcting a previously broken tor configuration. Sending _no|none_ signal is useful when running consecutive commands to avoid tor signaling newnym everytime tor is hupped, then at last signal tor hup to tor reload its configuration and apply changes. (Default: reload|hup).

**-h**, **--help**
: Display the script help message. Abscense of any parameter will also have the same effect.
```
onionjuggler-cli -h
onionjuggler-cli --help
```

# ENVIRONMENT

**ONIONJUGGLER_SKIP_PRE_TOR_CHECK**

: If set to 1, skip pre run tor check to allow the script to start running if the tor is failing to parse its configuration. Note it does not disable the last tor check to apply configuration changes, that is, if the configuration is still invalid, nothing will be changed. This option is useful if you are certain the configuration check will be fixed by the command. As the scripts requires root and you are probably calling the script from an unpriviliged user, preserve the variable value through environment changes by assigning it after the command to run the onionjuggler script as another user and before the script name:
```
sudo ONIONJUGGLER_SKIP_PRE_TOR_CHECK=1 onionjuggler-cli
doas ONIONJUGGLER_SKIP_PRE_TOR_CHECK=1 onionjuggler-cli
```

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

onionjuggler.conf(5), onionjuggler-TUI(8), onionjuggler-cli-auth-client(8), onionjuggler-cli-auth-server(8), onionjuggler-cli-web(8), tor(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
