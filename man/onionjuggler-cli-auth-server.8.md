% ONIONJUGGLER-CLI-AUTH0-SERVER(8) Manage onion service server side authorization
% Written by nyxnor (nyxnor@protonmail.com)
% default_date

# NAME

onionjuggler-cli-auth-server - Manage onion service server side authorization


# SYNOPSIS

**onionjuggler-cli-auth-server** [**--option**<=*ARGUMENT*>]\
**onionjuggler-cli-auth-server** [**--on**] [**--service**=<*SERVICE*>] [**--client-pub-file**=<*CLIENT_PUB_FILE*>]\
**onionjuggler-cli-auth-server** [**--on**] [**--service**=<*SERVICE*>] [**--client**=<*CLIENT*>] [**--client-pub-config**=<*CLIENT_PUB_CONFIG*>]\
**onionjuggler-cli-auth-server** [**--on**] [**--service**=<*SERVICE*>] [**--client**=<*CLIENT*>] [**--client-pub-key**=<*CLIENT_PUB_KEY*>]\
**onionjuggler-cli-auth-server** [**--off**] [**--service**=<*@all*|*SERV1*,*SERV2*,*...*>] [**--client**=<*@all*|*CLIENT1*,*CLIENT2*,*...*>]\
**onionjuggler-cli-auth-server** [**--list**] [**--service**=<*@all*|*SERV1*,*SERV2*,*...*>]\
**onionjuggler-cli-auth-server** [**--signal**=<*reload*|*restart*|*none*>]\
**onionjuggler-cli-auth-server [--getconf]**\
**onionjuggler-cli-auth-server [--getopt]** [**--service**=<*SERVICE*>]\
**onionjuggler-cli-auth-server** [**-V**|**--version**]\
**onionjuggler-cli-auth-server** [**-h**|**--help**]


# DESCRIPTION

**onionjuggler-cli-auth-server** helps manage server side onion authorization.


# OPTIONS

**--on** **--service**=<*SERVICE*> **--client-pub-file**=<*CLIENT_PUB_FILE*> **--replace-file**\
**--on** **--service**=<*SERVICE*> **--client-pub-config**=<*CLIENT_PUB_CONFIG*> **--client** **--replace-file**\
**--on** **--service**=<*SERVICE*> **--client**=<*CLIENT*> **--client-pub-key**=<*CLIENT_PUB_KEY*> **--replace-file**\

**--on** **--service**=<*SERVICE*> **--client**=<*CLIENT*>

: Authorize a client to your service. A key pair of public and private keys will be generated, keys are sent to stdout and you should send to the client. A CLIENT.auth file will be created on HiddenServiceDir/authorized_clients folder. If no key is specified, then a key pair will be generated.File(s) modified: HiddenServiceDir/authorized_clients/
```
onionjuggler-cli-auth-server --on --service=ssh --client-pub-file=/home/user/bob.auth
onionjuggler-cli-auth-server --on --service=ssh --client=bob --client-pub-config=descriptor:x25519:UQYM2MJ4CKZU25JABR3Z5L2QP3552EH2BUOIZC2XVULY2QRGXUVQ
onionjuggler-cli-auth-server --on --service=ssh --client=bob --client-pub-key=UQYM2MJ4CKZU25JABR3Z5L2QP3552EH2BUOIZC2XVULY2QRGXUVQ
onionjuggler-cli-auth-server --on --service=ssh --client=bob
```

**--off** **--service**=<*@all*|*SERV1*,*SERV2*,*...*> **--client**=<*@all*|*CLIENT1*,*CLIENT2*,*...*>

: Deauthorize from your service a client that is inside HiddenServiceDir/authorized_clients folder. File(s) modified: HiddenServiceDir/authorized_clients/
```
onionjuggler-cli-auth-server --off --service=ssh --client=alice
onionjuggler-cli-auth-server --off --service=ssh --client=alice,bob
onionjuggler-cli-auth-server --off --service=ssh,xmpp --client=alice
onionjuggler-cli-auth-server --off --service=ssh,xmpp --client=alice,bob
onionjuggler-cli-auth-server --off --service=@all --client=alice,bob
onionjuggler-cli-auth-server --off --service=@all --client=@all
```

**--list**  **--service**=<*@all*|*SERV1*,*SERV2*,*...*>

: List authorized clients and the respective public keys that are inside HiddenServiceDir/authorized_clients folder. File(s) modified: none
```
onionjuggler-cli-auth-server --list --service=ssh
onionjuggler-cli-auth-server --list --service=ssh,xmpp
onionjuggler-cli-auth-server --list --service=@all
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
onionjuggler-cli-auth-server -h
onionjuggler-cli-auth-server --help
```


# ENVIRONMENT

**ONIONJUGGLER_SKIP_PRE_TOR_CHECK**

: If set to 1, skip pre run tor check to allow the script to start running if the tor is failing to parse its configuration. Note it does not disable the last tor check to apply configuration changes, that is, if the configuration is still invalid, nothing will be changed. This option is useful if you are certain the configuration check will be fixed by the command. As the scripts requires root and you are probably calling the script from an unpriviliged user, preserve the variable value through environment changes by assigning it after the command to run the onionjuggler script as another user and before the script name:
```
sudo ONIONJUGGLER_SKIP_PRE_TOR_CHECK=1 onionjuggler-cli-auth-server
doas ONIONJUGGLER_SKIP_PRE_TOR_CHECK=1 onionjuggler-cli-auth-server
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

onionjuggler.conf(5), onionjuggler-tui(8), onionjuggler-cli-auth-client(8), onionjuggler-cli-web(8), onionjuggler-cli(8), tor(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
