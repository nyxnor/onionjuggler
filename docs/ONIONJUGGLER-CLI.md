% onionjuggler-cli(1) onionjuggler-cli 0.0.1
% Written by nyxnor (nyxnor@protonmail.com)
% September 2069

# NAME

onionjuggler-cli - dinamically manage your onion services with a POSIX compliant shell


# SYNOPSIS

**onionjuggler-cli** command [REQUIRED] <*OPTION*>\
**onionjuggler-cli setup torrc**\
**onionjuggler-cli on** --service [SERV] --version [VERSION] --socket tcp --port "[VIRTPORT] <*TARGET*> <*VIRTPORT2*> <*TARGET2*>"\
**onionjuggler-cli on**  --service [SERV] --version [VERSION] --socket unix --port "[VIRTPORT] <*VIRTPORT2*>"\
**onionjuggler-cli off** --service [SERV1,SERV2,...] <*purge*>\
**onionjuggler-cli list** --service [@all|SERV1,SERV2,...] <*no-qr*>\
**onionjuggler-cli renew** --service [@all|SERV1,SERV2,...]\
**onionjuggler-cli auth-server on** --service [SERV] --client [CLIENT] --client-pub-key <*CLIENT_PUB_KEY*>\
**onionjuggler-cli auth-server on** --service [@all|SERV1,SERV2,...] --client [CLIENT1,CLIENT2,...]\
**onionjuggler-cli auth-server off** --service [@all|SERV1,SERV2,...] --client [@all|CLIENT1,CLIENT2,...]\
**onionjuggler-cli auth-server list** --service [@all|SERV1,SERV2,...]\
**onionjuggler-cli auth-client on** --onion [ONION] --client-priv-key <*CLIENT_PRIV_KEY*>\
**onionjuggler-cli auth-client off** --onion [ONION1,ONION2,...]\
**onionjuggler-cli auth-client list**\
**onionjuggler-cli web on** --service [SERV] --folder [FOLDER]\
**onionjuggler-cli web off** --service [SERV]\
**onionjuggler-cli web list**\
**onionjuggler-cli location** --service [SERV] [--nginx|--apache|--html]\
**onionjuggler-cli backup** [--create|--integrate]\
**onionjuggler-cli vanguards** [--install|--logs|--upgrade|--remove]\
**onionjuggler-cli** <*-h|-help|--help|help*>


# DESCRIPTION

**onionjuggler-cli** is a part of OnionJuggler, a combination of POSIX compliant scripts helps the interaction with onion service configuration and files to speed up usage and avoid misconfiguration. The project is composed by 3 scripts, one being the menu (onionjuggler-tui), one being the configuration (.onionrc) and the last one being the main handler (onionjuggler-cli). The menu is dynamically produced depending on how much services (<*HiddenServicesDataDir*>/<*HiddenServiceDir*>) or clients you have (<*HiddenServiceDir*>/authorized_clients/) or clients you are (ClientOnionAuthDir). The .onionrc is used to source the global variables to be used in the other scripts, such as where the hidden services are located, the owner of the DataDir folder, the ControlPort to be used. The main script is where all the magic happens, in fact, menu script just build the variables with a graphical interface by the user checklisting or writing with a input box to be organized to call the main script by non technical users.

The script tries its best to avoid inserting incorrect lines to torrc, that would make tor fail. Because of this, any incorrect command flagged show the error mesage to understand what is the cause of the error and display the commands help option, finally exit the script without modifying the torrc. At least two arguments are required for every command, some could have more than one required argument.


# OPTIONS

## VARIABLES

**[VAR]**
: Variable is required.

**<*VAR*>**
: Variable is optional.

**on**
: Enable by adding configuration.

**off**
: Disable by removing the configuration.

**list**
: List enabled configuration.

**purge**
: Remove permanently the data.

**@all**, **@all**
: Include all available services or clients.

**SERV1,SERV2...**, **CLIENT1,CLIENT2,...**, **ONION1,ONION2**
: List enabled option. e.g: ssh,xmpp,irc or alice,bob.

**VERSION**
: Onion service version. Currently only valid value is 3.

**SERV**
: Service name. String format.

**VIRTPORT**
: Virtual port. Integer format.

**TARGET**
: Target socket. TCP needs to be specified, the format is *addr:port*. Abscense of the address will bind to localhost using the address *127.0.0.1* for uniformity. Abscense of target and will use the same port as the virtual port, specifying just the port will bind to localhost using the address *127.0.0.1* for uniformity. Unix target is handled by the code using the format *unix:path* and does not require manual selection. Integer format.

**ONION**
: Onion address of the authenticated service for the client to connect to. Only accepted format is for onion v3 addresses, which contains 56 characters using the base32 format with the range *a-z2-7* and ending with (dot)onion. String format.

**--COMMAND <ARGS>**
: Commands that accept arguments can be specified as follow: --service ssh OR --service "ssh nextcloud" OR --service=ssh,nextcloud

**ssh**, **xmpp**, **nextcloud**
: Example of onion services directory names.

## ARGUMENTS

**setup torrc**
: Restore the latest torrc backup and reload tor. Every time onionjuggler-cli is ran, it creates a torrc.bak, with this option, it will copy the backup file to the torrc named file. File(s) modified: torrc.

**on** --service [SERV] --version 3 --socket tcp --port [VIRTPORT] <*TARGET*> <*VIRTPORT2*> <*TARGET2*>
: Enable an onion service using TCP socket (addr:port) as target. If the TARGET is only the port of it TARGET was not provided, will use the same port as VIRTPORT and bind to 127.0.0.1. TARGET examples: 127.0.0.1:80, 192.168.1.100:80, 140.82.121.3. File(s) modified: torrc.
```
onionjuggler-cli on --service ssh --version 3 --socket tcp --port 22
onionjuggler-cli on --service ssh --version 3 --socket tcp --port "22 22"
onionjuggler-cli on --service ssh --version 3 --socket tcp --port="22 22 80"
onionjuggler-cli on --service ssh --version 3 --socket tcp --port="22,22,80,80"
onionjuggler-cli on --service ssh --version 3 --socket tcp --port "22 127.0.0.1:22"
onionjuggler-cli on --service ssh --version 3 --socket tcp --port "22 127.0.0.1:22 80"
onionjuggler-cli on --service ssh --version 3 --socket tcp --port "22 127.0.0.1:22 80 127.0.0.1:80"
```

**on** --service [SERV] --version 3 --socket unix --port [VIRTPORT] <*VIRTPORT2*>
: Enable an onion service using UNIX socket (unix:path) as target. The TARGET is handled automatically by the script. This method avoids leaking the onion service address to the local network. File(s) modified: torrc.
```
onionjuggler-cli on unix 3 ssh 22
onionjuggler-cli on tcp 3 ssh 22 80
```

**off** --service [SERV1,SERV2,...] <*--purge*>
: Disable an onion service by removing it configuration lines (HiddenService) from the torrc. Optionally purge its data directory, which will delete permanently the onion service folder (HiddenServiceDir). File(s) modified: torrc and optionally HiddenServiceDir.
```
onionjuggler-cli off --service ssh
onionjuggler-cli off --service ssh,xmpp
onionjuggler-cli off --service ssh,xmpp --purge
```

**list** --service [@all|SERV1,SERV2,...] <*--no-qr*>
: List onion service information: hostname (address) and in QR encoded format, clients names and quantity, status if service is active or inactive regarding the torrc lines (un)present and the HiddenServiceDir presence, the torrc block. File(s) modified: none.
```
onionjuggler-cli list --service ssh
onionjuggler-cli list --service ssh,xmpp
onionjuggler-cli list --service @all
onionjuggler-cli list --service @all no-qr
```

**renew** --service [@all|SERV1,SERV2,...]
: Renew onion service hostname (.onion domain) and clients (inside HiddenServiceDir/authorized_clients/). The onion service keys (hs_ed25519_public_key and hs_ed25519_private_key) will be removed to override the hostname file. File(s) modified: HiddenServiceDir.
```
onionjuggler-cli renew --service ssh
onionjuggler-cli renew --service ssh,xmpp
onionjuggler-cli renew --service @all
```

**auth-server --on** --service [SERV] --client [CLIENT] --client-pub-key <*CLIENT_PUB_KEY*>
: Authorize to your service a client. If the client public key is not provided, a new key pair of public and private keys will be generated, keys are sent to stdout and you should send to the client. A $CLIENT.auth file will be created on HiddenServiceDir/authorized_clients folder. File(s) modified: HiddenServiceDir/authorized_clients/
```
onionjuggler-cli auth-server --on --service ssh --client alice
onionjuggler-cli auth-server --on --service ssh --client alice --client-pub-key ABVCL52QL6IRYIOLEAYUVTZY3AIOMDI3AIFBAALZ7HJOHIJFVBIQ
```

**auth-server --on** --service [@all|SERV1,SERV2,...] --client [CLIENT1,CLIENT2,...]
: Authorize to your service a client. A key pair of public and private keys will be generated, keys are sent to stdout and you should send to the client. A $CLIENT.auth file will be created on HiddenServiceDir/authorized_clients folder. File(s) modified: HiddenServiceDir/authorized_clients/
```
onionjuggler-cli auth-server --on --service ssh --client alice
onionjuggler-cli auth-server --on -service ssh --client alice,bob
onionjuggler-cli auth-server --on -service ssh,xmpp --client alice
onionjuggler-cli auth-server --on -service ssh,xmpp --client alice,bob
onionjuggler-cli auth-server --on -service @all --client alice,bob
onionjuggler-cli auth-server --on -service @all --client @all
```

**auth-server --off** --service [@all|SERV1,SERV2,...] --client [@all|CLIENT1,CLIENT2,...]
: Deauthorize from your service a client that is inside HiddenServiceDir/authorized_clients folder. File(s) modified: HiddenServiceDir/authorized_clients/
```
onionjuggler-cli auth-server --off --service ssh --client alice
onionjuggler-cli auth-server --off --service ssh --client alice,bob
onionjuggler-cli auth-server --off --service ssh,xmpp --client alice
onionjuggler-cli auth-server --off --service ssh,xmpp --client alice,bob
onionjuggler-cli auth-server --off --service @all --client alice,bob
onionjuggler-cli auth-server --off --service @all --client @all
```

**auth-server --list**  --service [@all|SERV1,SERV2,...]
: List authorized clients and the respective public keys that are inside HiddenServiceDir/authorized_clients folder. File(s) modified: none
```
onionjuggler-cli auth-server --list --service ssh
onionjuggler-cli auth-server --list --service ssh,xmpp
onionjuggler-cli auth-server --list --service @all
```

**auth-client --on** --onion [ONION] --client-priv-key <*CLIENT_PRIV_KEY*>
: Authenticate as a client to a remote onion serivce. If the client private keys is not provided, a new key pair of public and private keys will be generated, keys are sent to stdout and you should send to the onion service operator. Add a $ONION.auth_private to ClientOnionAuthDir. File(s) modified: ClientOnionAuthDir.
```
onionjuggler-cli auth-client --on --onion fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd.onion
onionjuggler-cli auth-client --on --onion fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd.onion --client-priv-key UBVCL52FL6IRYIOLEAYUVTZY3AIOMDI3AIFBAALZ7HJOHIJFVBIQ
```

**auth-client --off** --onion [ONION1,ONION2,...]
: Deauthenticate from a remote onion serivce. Remove the $ONION.auth_private file from ClientOnionAuthDir. File(s) modified: ClientOnionAuthDir/.
```
onionjuggler-cli auth-client --off --onion fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd.onion
onionjuggler-cli auth-client --off --onion fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd.onion,yyyzxhjk6psc6ul5jnfwloamhtyh7si74b47a3k2q3pskwwxrzhsxmad.onion
```

**auth-client --list**
: List authentication files and the respective private keys from ClientOnionAuthDir.Useful when removing files and you want to see which onions you are already authenticated with.  File(s) modified: none.
```
onionjuggler-cli auth-client --list
```

**web --on** [SERV] [FOLDER]
: Enable a website using a specific onion service by creating a configuration file inside the web server folder by default, the folder name is to be considered the wanted folder inside website_dir variable defined on .onionrc. If the path starts with forward slash "/" or tilde and slash "~/", that path will be considered instead. File(s) modified: /etc/${web_server}/sites-enabled/.
```
onionjuggler-cli web on nextcloud nextcloud-local-site
```

**web --off** --service [SERV]
: Disable a website from a specific onion service by removing its configuration file from the webserver folder. File(s) modified: /etc/${web_server}/sites-enabled/.
```
onionjuggler-cli web off nextcloud
```

**web --list**
: List enabled websites, meaning the confiuration files inside the webserver folder /etc/${web_server}/sites-enabled/. File(s) modified: none.
```
onionjuggler-cli web list
```

**location**  --service [SERV] [--nginx|--apache|--html]
: Guide to add onion location to your plainnet website when using the webserver Nginx or Apache2 or an HTML header. It does not modify any configuration by itself, the instructions to do so are send to stdout. File(s) modified: none.
```
onionjuggler-cli location --service nextcloud --nginx
onionjuggler-cli location --service nextcloud --apache
onionjuggler-cli location --service nextcloud --html
```

**backup** [--create|--integrate]
: Backup all of the torrc, DataDir/services and ClientOnionAuthDir either by creating a backup file or integrating to the system from a backup made before. File(s) modified: torrc, DataDir/services, ClientOnionAuthDir.
```
onionjuggler-cli backup --create
onionjuggler-cli backup --integrate
```

**restore** *torrc*
: Before every change to the torrc state, a backup is saved on the same folder named torrc.bak. This option restore the latest torrc change to revert the last change to the configuration.

**vanguards** [--install|--logs|--upgrade|--remove]
: Manage Vanguards addon using the repository https://github.com/mikeperry-tor/vanguards. This addon protects against guard discovery and related traffic analysis attacks.
A guard discovery attack enables an adversary to determine the guard node(s) that are in use by a Tor client and/or Tor onion service. Once the guard node is known, traffic analysis attacks that can deanonymize an onion service (or onion service user) become easier.
Installation (git clone) and Upgrade (git pull) are bound to a commit hash set on the .onionrc (git reset --hard vanguards_commit). Remove will delete the vanguards directory. Logs follow the service logs. When installing, it create a service called vanguards@default, which you can stop and start. File(s) modified: DataDir/vanguards/vanguards.conf.
```
onionjuggler-cli vanguards --install
onionjuggler-cli vanguards --logs
onionjuggler-cli vanguards --upgrade
onionjuggler-cli vanguards --remove
```

<*-h|-help|--help|help*>
: Display the script help message. Abscense of any parameter will also have the same effect.
```
onionjuggler-cli
onionjuggler-cli -h
onionjuggler-cli -help
onionjuggler-cli --help
onionjuggler-cli help
```


# FILES

**.onionrc**
: Default configuration file

**onionjuggler-cli**
: Command Line Interface to interact directly with onion services.

**onionjuggler-tui**
: Terminal User Interface that wraps the CLI in a dialog box.

**install/setup.sh**
: Prepares the environment for tor and download requirements for OnionJugglers.

**docs/**
: Contain documentation regarding onion services.

**etc/**
: Contain files that can optionally be placed inside the user */etc* folder.


# ENVIRONMENT

**ONIONJUGGLER_PWD**
: OnionJuggler repository path. Used to run the scripts from any directory.

**EDITOR**
: Use the default editor, else will fallback to Vi.

**DIALOGRC**
: Source the dialog box run commands file.

# EXIT VALUE

**0**
: Success

**1**
: Fail


# BUGS

Bugs you may find. First search for related issues on https://github.com/nyxnor/onionservice/issues, if not solved, open a new one.


# SEE ALSO

tor(1), sh(1), regex(7), sed(1), grep(1)


# COPYRIGHT

Copyright  ©  2021  OnionJuggler developers (MIT)
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.
