# TECHNICAL OVERVIEW

## Important files:

You can run all of this standalone with these files below:

* the library -> `onion.lib`
* the main script -> `onionservice-cli`

## Variables description:

* **[VAR]** = Variable is required
* **< VAR >** = Variable is optional
* **SERV** = service name
* **SERV1,SERV2,..** = listed service names (ssh,xmpp,nextcloud)
* **CLIENT** = client name
* **CLIENT1,CLIENT2,...** = listed service names (alice,bob)
* **VIRTPORT** = virtual port
* **TARGET** = target can be tcp or unix socket that will receive requests from the VIRTPORT
* **all-services** = run the command for all services existent
* **all-clients** = run the command for all clients of the indicated services (can be combine with all-services or a list)
* **unix** = unix sockets
* **tcp** = tcp sockets

## Variables example:

As an example, we will be using:
* SERVICE=ssh,xmpp,nextcloud
* VIRTPORT=80
* TARGET=127.0.0.1:80

## Automatic corrections

The script tries its best to avoid inputting incorrect lines to torrc, that would make tor fail. Because of this, any incorrect command flagged show the error mesage to understand what is the cause of the error and display the commands help option, finally exit the script without modifying the torrc.

#  Activation

## tcp

Activates a service by inserting the HiddenService configuration lines (HiddenServiceDir and HiddenServicePort) in the torrc.
Deletes previous HiddenService lines which refers to a service with the same name.
The only file edited is the `torrc`.

HiddenServicePort's target will use tcp sockets. This socket type **leaks** the onion address to the local network.
The TARGET port does not need to be the same as the VIRTPORT (virtual port).

The correct way to indicate target for IPV4 is `addr:port` and IPV6 is `[addr]:port` (IPV6 support coming soon).
* 127.0.0.1:80
* 192.168.0.10:80
* [IPV6]:80

If the TARGET is not specified in the above format, it will autocorrect to localhost with the following procedures:
* TARGET=80            then TARGET=127.0.0.1:80
* TARGET=localhost:80  then TARGET=127.0.0.1:80
* TARGET="0"           then TARGET=127.0.0.1:VIRTPORT

torrc syntax: `HiddenServicePort VIRTPORT TARGET` (TARGET=addr:port)
```
HiddenServicePort 80 127.0.0.1:80
```

**Usage:**

Syntax: *on tcp [SERV] [VIRTPORT] < TARGET > < VIRTPORT2 > < TARGET2 >*

1. Localhost with one virtual port (the commands below will have the same effect):
```sh
bash onionservice-cli on tcp ssh 22
bash onionservice-cli on tcp ssh 22 22
bash onionservice-cli on tcp ssh 22 localhost:22
bash onionservice-cli on tcp ssh 22 127.0.0.1:22
```
```
HiddenServiceDir /var/lib/tor/services/ssh
HiddenServicePort 22 127.0.0.1:22
```

2. Localhost with two virtual ports (the commands above will have the same effect):
```sh
bash onionservice-cli on tcp ssh 22 22 80
bash onionservice-cli on tcp ssh 22 22 80 80
bash onionservice-cli on tcp ssh 22 localhost:22 80 localhost:80
bash onionservice-cli on tcp ssh 22 127.0.0.1:22 80 127.0.0.1:80
```
```
HiddenServiceDir /var/lib/tor/services/ssh
HiddenServicePort 22 127.0.0.1:22
HiddenServicePort 80 127.0.0.1:80
```

3. Remote target with one virtual port
```sh
bash onionservice-cli on tcp ssh 22 192.168.0.10:22
```
```
HiddenServiceDir /var/lib/tor/services/ssh
HiddenServicePort 22 192.168.0.10:22
```

4. Remote target with two virtual ports:
```sh
bash onionservice-cli on tcp ssh 22 192.168.0.10:22 80 192.168.0.10:80
```
```
HiddenServiceDir /var/lib/tor/services/ssh
HiddenServicePort 22 192.168.0.10:22
HiddenServicePort 80 192.168.0.10:80
```

## unix

HiddenServicePort's target will use unix sockets. It **does not leak** the onion address to the local network.

You do not need to specify the TARGET, it is already chosen for you and it is unique for every combination of SERV and VIRTPORT

torrc syntax: `HiddenServicePort VIRTPORT` (TARGET=unix:path)
```
HiddenServicePort 80 unix:/var/run/tor-hs-SERVICE-VIRTPORT.sock
```

**Usage:**

Syntax: *on unix [SERV] [VIRTPORT] < VIRTPORT2 >*

* Target with one virtual ports:
```sh
bash onionservice-cli on unix ssh 22
```
```
HiddenServiceDir /var/lib/tor/services/ssh
HiddenServicePort 22 /var/run/tor-hs-ssh-22.sock
```

* Target with two virtual ports:
```sh
bash onionservice-cli on unix ssh 22 80
```
```
HiddenServiceDir /var/lib/tor/services/ssh
HiddenServicePort 22 /var/run/tor-hs-ssh-22.sock
HiddenServicePort 80 /var/run/tor-hs-ssh-80.sock
```

# Deactivation

Dectivates a service by deleting the HiddenService configuration lines (HiddenServiceDir and HiddenServicePort) in the torrc.

**WARNING**: HiddenService lines should be in block between empty lines. The script automatically insert the configuration lines in the correct format. If it is not between empty lines, other configuration lines might be deleted. The format is:

**Note**: The Hidden Service directory will not be deleted by default, if you want to delete the entire folder (hostname, hs_ed25519_public_key, hs_ed25519_secret_key, authorized_clients/), you must give the argument **purge**. If you want to activate the service with the same keys, you must backup the `hs_ed25519_secret_key`.

```

HiddenServiceDir /var/lib/tor/services/test
HiddenServicePort 80 /var/run/tor-hs-test-5000.sock
HiddenServicePort 443 /var/run/tor-hs-ssh-50001.sock

HiddenServiceDir /var/lib/tor/services/ssh
HiddenServicePort 22 /var/run/tor-hs-ssh-22.sock
HiddenServicePort 80 /var/run/tor-hs-ssh-80.sock

```

**Usage:**

Syntax: *off [SERV1,SERV2,...] < purge >*

Deactivate the service (delete torrc's lines which are in the same block as the service):
```sh
bash onionservice-cli off ssh,xmpp,nextcloud
```

Deactivate the service and delete the service directory (keys will be deleted):
* delete torrc's lines which are in the same block as the service.
* delete the Hidden Service directory.
```sh
bash onionservice-cli off ssh,xmpp,nextcloud purge
```

# Renewal of service address

Renew the hostname (onion address or .onion domain) by deleting the public and private keys (hd_ed25119_public_key and hs_ed25519_secret_key). Reloads tor and it will automatically generate new keys and replacing the hostname file.

Although only the keys removal are needed to renew the service address, the script also renews the authorized clients keys. It reads the service names and generate new public and private keys for them sending to stdout so you can promptly send to your clients.

It is posible to renew:
* a list of services (ssh,xmpp,nextcloud)
* all services (all-services)

**Usage:**

Syntax: *renew [all-services|SERV1,SERV2,...]*

Renew one or a list of services:
```sh
bash onionservice-cli renew ssh,xmpp,nextcloud
```

Renew all services:
```sh
bash onionservice-cli renew all-services
```

# Onion authentication/authorization

An authenticated onion service is an onion service that requires the client to provide an authentication credential to connect to the onion service. For v3 onion services, this method works with a pair of keys (a public and a private). The service side is configured with a public key and the client can only access it with a private key. The client private key is not transmitted to the service, and it's only used to decrypt its descriptor locally. Source ([1]( https://support.torproject.org/onionservices/client-auth/)) ([2](https://community.torproject.org/onion-services/advanced/client-auth/))

## Onion service operator

Once you have configured client authorization, anyone with the address will not be able to access it from this point on. If no authorization is configured, the service will be accessible to anyone with the onion address.

### Authorize a client

It is posible to add to:
* a list of services (ssh,xmpp,nextcloud)
* all services (all-services)
* a list of clients (alice,bob)

#### Server adding public part

If you do not specify the public key, a the key pair will be generated, but if CLIENT_PUB_KEY is not null, add the public key to your HiddenServiceDir/authorized_clients/ with the client name suffixed with '.auth'.

The client can keep his private key hidden by creating the key pair privately and then sharing with the onion service operator only the public part.

**Usage:**

Syntax: *auth server on [SERV] [CLIENT] < CLIENT_PUB_KEY >*

Client sent you his public key `5BMZSEZCMD7XUWC4UQITPDZAFP322ZNNJXHYISUWALNVJCOH3FCA` for the `xmpp` service:
```shell
bash onionservice-cli auth server on xmpp 5BMZSEZCMD7XUWC4UQITPDZAFP322ZNNJXHYISUWALNVJCOH3FCA
```

#### Server creating key pair

You can create the public and private keys for your client to use. This is not as self as the client creating the key by himslef and keeping the private key hidden (which is possible with auth client option on this script).

**Usage:**

Syntax: *auth server on [all-services|SERV1,SERV2,...] [CLIENT1,CLIENT2,...]*

Add authorization of one or a list of services and one or a list of clients:
```sh
bash onionservice-cli auth server on ssh,xmpp,nextcloud alice,bob
```

Add authorization of all services and one or a list of clients:
```sh
bash onionservice-cli auth server on all-services alice,bob
```

Example:
```sh
bash onionservice-cli auth server on test,xmpp alice,bob
```
Effect:
```
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Declare the variables
SERVICE=xmpp
CLIENT=bob
TOR_HOSTNAME=vrekvygmdtz7i3uxrxrj3mu4shtsu4fwoz3li2r2hxsnijjq6p2rfcyd.onion
PRIV_KEY=BBGUMZUTT6GXP2WURAG3UYZQABRGRBDO2LHSZGZ5HB5GVKJ2VVXA
PRIV_KEY_CONFIG=vrekvygmdtz7i3uxrxrj3mu4shtsu4fwoz3li2r2hxsnijjq6p2rfcyd:descriptor:x25519:BBGUMZUTT6GXP2WURAG3UYZQABRGRBDO2LHSZGZ5HB5GVKJ2VVXA
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Declare the variables
SERVICE=xmpp
CLIENT=alice
TOR_HOSTNAME=vrekvygmdtz7i3uxrxrj3mu4shtsu4fwoz3li2r2hxsnijjq6p2rfcyd.onion
PRIV_KEY=QAXRTA7H72HLFIAWU3J7J3WPVHIDL43X2FP3EP4W2UNXM4H4RFRQ
PRIV_KEY_CONFIG=vrekvygmdtz7i3uxrxrj3mu4shtsu4fwoz3li2r2hxsnijjq6p2rfcyd:descriptor:x25519:QAXRTA7H72HLFIAWU3J7J3WPVHIDL43X2FP3EP4W2UNXM4H4RFRQ
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Declare the variables
SERVICE=test
CLIENT=bob
TOR_HOSTNAME=xap5clrt4eaqglov72qxwih4lq4yagguzmln2kaw42xye4txfgyrfiid.onion
PRIV_KEY=OAXP3EYJYUIWHNNVCVR5R3DSH7WPCPI6XRZYDT5Y7KCJQ7GERJDA
PRIV_KEY_CONFIG=xap5clrt4eaqglov72qxwih4lq4yagguzmln2kaw42xye4txfgyrfiid:descriptor:x25519:OAXP3EYJYUIWHNNVCVR5R3DSH7WPCPI6XRZYDT5Y7KCJQ7GERJDA
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Declare the variables
SERVICE=test
CLIENT=alice
TOR_HOSTNAME=xap5clrt4eaqglov72qxwih4lq4yagguzmln2kaw42xye4txfgyrfiid.onion
PRIV_KEY=JBIAPK63HAVUYLDUGXJOCO4THIIPH42GROFWBIRGTFZIZQRDMF2Q
PRIV_KEY_CONFIG=xap5clrt4eaqglov72qxwih4lq4yagguzmln2kaw42xye4txfgyrfiid:descriptor:x25519:JBIAPK63HAVUYLDUGXJOCO4THIIPH42GROFWBIRGTFZIZQRDMF2Q
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Instructions client side:

# Check if <ClientOnionAuthDir> was configured in the <torrc>, if it was not, insert it: ClientOnionAuthDir /var/lib/tor/onion_auth
[ $(grep -c 'ClientOnionAuthDir' /etc/tor/torrc) -eq 0 ] && { printf 'ClientOnionAuthDir /var/lib/tor/onion_auth' | sudo tee -a /etc/tor/torrc ; }

# Create the auth file inside <ClientOnionAuthDir>
printf ${PRIV_KEY_CONFIG} | sudo tee -a /var/lib/tor/onion_auth/${SERVICE}-${TOR_HOSTNAME}.auth_private

# Reload tor
sudo chown -R debian-tor:debian-tor /var/lib/tor
sudo pkill -sighup tor
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# Done
```

### Remove authorization of a client

It is posible to remove from:
* a list of services (ssh,xmpp,nextcloud)
* all services (all-services)
* a list of clients (alice,bob)
* all clients (all-clients)

**Usage:**

Syntax: *auth server off [all-services|SERV1,SERV2,...] [all-clients|CLIENT1,CLIENT2,...]*

Remove authorization of one or a list of services and one or a list of clients:
```sh
bash onionservice-cli auth server off ssh,xmpp,nextcloud alice,bob
```

Remove authorization of all services and one or a list of clients:
```sh
bash onionservice-cli auth server off all-services alice,bob
```

Remove authorization of all services and all clients:
```sh
bash onionservice-cli auth server off all-services all-clients
```

Remove authorization of one or a list of services and all clients from them:
```sh
bash onionservice-cli auth server off ssh,xmpp,nextcloud all-clients
```

## Onion service client

You can get the access credentials from the onion service operator. Reach out to the operator and request access. You may authenticate yourself directly in the Tor Browser. When accessing an authenticated onion service, Tor Browser will show in the URL bar an icon of a little gray key, accompanied by a tooltip. Enter your valid client private key into the input field. [TPO guide](https://tb-manual.torproject.org/onion-services/#onion-service-authentication).

### Add your authorization as client

#### Insert the client private key

If you already have the private key, given by the onion service operator or generated by you separetely, you can insert the private key to your ClietOnionAuthDir with this option.

**Usage:**

Syntax: *auth client on [ONION_DOMAIN] < AUTH_PRIV_KEY >*

```sh
bash onionservice-cli auth client on fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd.onion VCICPGI65GPP2BZECMO4M3J63WREWWUAO2PJA6TXMWZB5D4XQZJA
```

This will create a '.auth_private' file inside ClietOnionAuthDir named with the onion domain for uniqueness.

#### Client create key pair

Create a key pair and write the private key to ClietOnionAuthDir.
Public key and server side instruction are sent to stdout so you can inform the onion service operator how to authorize you.

**Usage:**

Syntax: *auth client on [ONION_DOMAIN]*

Private key example:
```
5BMZSEZCMD7XUWC4UQITPDZAFP322ZNNJXHYISUWALNVJCOH3FCA
```

Key config example:
```
fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd:descriptor:x25519:UBVCL52FL6IRYIOLEAYUVTZY3AIOMDI3AIFBAALZ7HJOHIJFVBIQ
```

The onion address in the name of the file for uniqueness. To add your key to authentication with tor (daemon):
```sh
bash onionservice-cli auth client on fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd.onion UBVCL52FL6IRYIOLEAYUVTZY3AIOMDI3AIFBAALZ7HJOHIJFVBIQ
```

This will create a '.auth_private' file inside ClietOnionAuthDir named with the onion domain for uniqueness.
```
fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd:descriptor:x25519:UBVCL52FL6IRYIOLEAYUVTZY3AIOMDI3AIFBAALZ7HJOHIJFVBIQ
```

### Remove your authorization as a client

To remove your key that authenticated you tor (daemon) normally to a site no more operational or keys expired (note you only need to speficy the file name when deleting).

**Usage:**

Syntax: *auth client [off] [ONION_DOMAIN]*

Remove your authentication file:
```sh
bash onionservice-cli auth client off fritz-culinaire-blog
```

### List your authorization as client

Send to stdout the file name and its content.
Use case is when removing files and you want to see which onions you are already authenticated with.

**Usage:**

Syntax: *auth client list*

See all your '.auth_private' files and its contents:
```sh
bash onionservice-cli auth client list
```
Effect:
```
# ClientOnionAuthDir /var/lib/tor/onion_auth

# File name: ssh-alice.auth_private
fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd:descriptor:x25519:XBQ3LRLWJ5TGM5G6QQNMU555WL6DXVQ2TAV22Q7MDY342KXPLV2Qfe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd:descriptor:x25519:XBQ3LRLWJ5TGM5G6QQNMU555WL6DXVQ2TAV22Q7MDY342KXPLV2Q

# File name: ssh-bob.auth_private
fe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd:descriptor:x25519:IB6SVMXLB777M6JC5SYEOQOXPX6ZKGIC4QZ5ZS4IADTKX33NYFPAfe4avn4qtxht5wighyii62n2nw72spfabzv6dyqilokzltet4b2r4wqd:descriptor:x25519:IB6SVMXLB777M6JC5SYEOQOXPX6ZKGIC4QZ5ZS4IADTKX33NYFPA


# Done
```


# View services credentials

Print to stdout relevant information about the service configuration:
* QR encoded hostname
* Hostname
* Clients names and quantity if configured with the `auth` command
* status `active` if torrc block exists and service directory does exist
* stauts `inactive` if torrc block does not exist but service directory does exist

**Usage:**

Syntax: *credentials [all-services|SERV1,SERV2,...]*

View credentials of one or a list of services:
```sh
bash onionservice-cli credentials ssh,xmpp,nextcloud
```

View credentials of all services:
```sh
bash onionservice-cli credentials all-services
```

```
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
█████████████████████████████████████
██ ▄▄▄▄▄ █▀▀ ██▄▄ ▀▄ ▄▀█▀ ██ ▄▄▄▄▄ ██
██ █   █ █▄▀██▀█ ▄█▄  ▀█▀ ▀█ █   █ ██
██ █▄▄▄█ █ ▄ █ █▄  ▄▄▀▀▀ ▄██ █▄▄▄█ ██
██▄▄▄▄▄▄▄█ █ ▀▄█ █▄▀ █▄▀▄▀▄█▄▄▄▄▄▄▄██
██▄▄▀ ██▄ █▀█  ▄▄▄ ██▄   █ █ ▄▄█▄▄▀██
██ ▀▀▄  ▄█ ▀▀  ▀▀█▀▄▄  ▀▄▀█ ▀▄█▀██▄██
██▀▀██▄▀▄▀▀█▄ █▀▄▄ ▄█   ▀█▀  ▄▀ ▀█▀██
███▄ ▀██▄▀ ▀█ █▄▄▀ ▀▄██ █  ▀▀ ██▄▄███
██▀██   ▄▀ ▄▀█  ▀█▀▄▀▄▀  ▀██▄ ▄▀█▀▄██
██▀█▀▄▄▀▄█▄▀█▄ █ ▀▀▀ ▀▄ █▀▀██ ▄▄█▄ ██
███ ██▄▄▄▀█▄ ▀██▀▄▀▀ █ ▄█▄▀▄▀██▄▀█▀██
██▄  ▄▀▄▄▀▀▄ ███▀█▄▄█▄   █▀ ▄▄▄ ▄▀▄██
██▄█▄▄█▄▄█ ▄█▀ ███▄ ▀▀█▄█  ▄▄▄ ██  ██
██ ▄▄▄▄▄ █▄███ ▀▀█  ▄▀▄ ▄█ █▄█ ▄▄ ▀██
██ █   █ █▀▄█▄█▄▄█▀▄ █▄ ▀▀ ▄ ▄  █████
██ █▄▄▄█ █▀ █▀█ ██  ▄█  ▄█ █▀▀▄█▄█▄██
██▄▄▄▄▄▄▄█▄▄█▄▄█▄████▄█▄█▄▄█▄████▄███
█████████████████████████████████████
Address    = vrekvygmdtz7i3uxrxrj3mu4shtsu4fwoz3li2r2hxsnijjq6p2rfcyd.onion
Name       = xmpp
Clients    = alice,bob (2)
Status     = active
HiddenServiceDir /var/lib/tor/services/xmpp
HiddenServicePort 5222 127.0.0.1:5222
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
█████████████████████████████████████
██ ▄▄▄▄▄ █▀ █▀▀▄█▀▄▄▀▄▄▀▄▄▀█ ▄▄▄▄▄ ██
██ █   █ █▀ ▄ █▀ █▄▀█▀▀▄ ███ █   █ ██
██ █▄▄▄█ █▀█ █▄ ▀▀ █▄▄▄ █▄▄█ █▄▄▄█ ██
██▄▄▄▄▄▄▄█▄█▄█ █ █ █▄▀▄▀ █ █▄▄▄▄▄▄▄██
██▄    ▀▄▄  ▄█▄ ▄█▀▄▄▀▄▀▄▀█ ▀▄█▄▀▄▀██
██▄ ▄▄ ▄▄ ▀ ▀ ▄▄▄▄▀█▀█▀▀ █▄▄▀█  ▀ ███
██▀▄█ ▀ ▄▀█ ▀▄▀▀███▄█▀▄▀▄ ▄▀▀▄▄▀█ ▀██
██▀ █ █▄▄▄▀ ██▀ ▄ ▀█▀▀ ▀ █▄ ▀▄▀▀ ████
██▄▄▀███▄▀ ▄██▄█▄▄▀ █▀ ▀ ▀▀▀▀▄▄▄▀▀▀██
██▀▀▄ ▀▄▄█▀▀█ ▄█▀ ▄█ █▄  █ █▀█▄▀▀ ███
██ ██ ██▄▄ ▄ ▄▀▀▀█▀▄▀▀▀█  ▄ ▀▄▄ ▀█▀██
██ █████▄▄▀█ █▀ ▄ ▄▄▀▀▄▀██▀▀█▀██ ▄███
██▄███▄█▄█ ▄ █▄█▄█▀▄▀ ▀█▄▄ ▄▄▄  ▀▀ ██
██ ▄▄▄▄▄ █▄▄▀ ▄█▀▄▀▄█▀█    █▄█ ▀ ▄▀██
██ █   █ █ ▄▀▄▀▀▀▄▀ █▀▄█▄▀▄ ▄▄ ▀▀  ██
██ █▄▄▄█ █  ▀█▀ ▄▄██▄▀▀ ▄ ▄▄ ██  ████
██▄▄▄▄▄▄▄█▄███▄█▄▄▄▄█▄██▄▄▄██▄███▄███
█████████████████████████████████████
Address    = xap5clrt4eaqglov72qxwih4lq4yagguzmln2kaw42xye4txfgyrfiid.onion
Name       = test
Clients    = alice,bob (2)
Status     = inactive
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
```


# Onion-Location

Guide to add onion-location to your plainnet site, referring to your own onion service so a tor user can be redirected at will or automatically. The guide will use the indicated service hostname to facilitate copy and pasting the headers with your onion serivce already filled. It succintly describes, but enough to configure, the web servers Nginx and Apache2 and the file in HTML, depending on which one you chose to view.

**Usage:**

Syntax: *location [SERV] [nginx|apache|html]*

View onion location guide for your test hidden service:
```sh
bash onionservice-cli location torbox.ch nginx
```

# Backup

There are two functionalities available for backup:
* create a backup
* integrate backup

Syntax: *backup [create|integrate]*

## Create backup

Create backup that contains:
* All of the Hidden Service blocks inside `torrc`
* All of the services directories (to also include the authorized_clients) inside `HiddenServiceDir`
* All of your client authentication inside `ClientOnionAuthDir`

Print to stdout the how to transfer via `scp` to a remote host by:
* running scp from remote to import to local machine
* running scp from local to export to remote machine

**Usage:**

Create a backup:
```sh
bash onionservice-cli backup create
```

## Integrate backup

Import backup from specified directory. Will place the files/folders in the correct place:
* `torrc`
* `HiddenServiceDir`
* `ClientOnionAuthDir`

Print to stdout the how to transfer via `scp` from a remote host by:
* running scp from remote to export to operating machine
* running scp from local to import to remote machine

Integrate a backup:
```sh
bash onionservice-cli backup integrate
```

# Vanguards

[Vanguards TECHNICAL.md](https://github.com/mikeperry-tor/vanguards/blob/master/README_TECHNICAL.md)
This addon protects against guard discovery and related traffic analysis attacks.
A guard discovery attack enables an adversary to determine the guard node(s) that are in use by a Tor client and/or Tor onion service.
Once the guard node is known, traffic analysis attacks that can deanonymize an onion service (or onion service user) become easier.

**Syntax:** *vanguards [install|logs|upgrade|remove]*

## Install vanguards

As there is no recent Vanguards release and the debian package is old, will clone the repository `git reset --hard VANGUARDS_COMMIT_HASH`, the commit hash being set inside `onion.lib`.

**Usage:**

```sh
bash onionservice-cli vanguards intall
```

## Log vanguards

Print to stdout vanguards logs.
Vanguards running by itself already protect against onion service deanonymization attacks, but for some people this might not be enough and is recommended to monitor your onion service reachiability.

Best documentation is the official one:
* [Security recommendations](https://github.com/mikeperry-tor/vanguards/blob/master/README_SECURITY.md)
* [Technical details](https://github.com/mikeperry-tor/vanguards/blob/master/README_TECHNICAL.md)

**Usage:**

```sh
bash onionservice-cli vanguards logs
```

## Upgrade vanguards

As explained on vanguards installation above, vanguards "version" is a commit hash. If there is a new commit, you may edit `onion.lib` and sed a new `VANGUARDS_COMMIT_HASH` first.

**Usage:**

```sh
bash onionservice-cli vanguards upgrade
```

## Remove vanguards

"Uninstall" vanguards by removing its git directory.

**Usage:**

```sh
bash onionservice-cli vanguards remove
```