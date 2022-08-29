## What's a client or onion authentication?

An authenticated onion service is an onion service that requires the client to provide an authentication credential to connect to the onion service. For v3 onion services, this method works with a pair of keys (a public and a private). The service side is configured with a public key and the client can only access it with a private key. The client private key is not transmitted to the service, and it's only used to decrypt its descriptor locally.

Onion services authentication is only possible for private onion services with a limited number of visitors. This is impossible for a public onion service. For a public onion service this step should be skipped. Each visitor needs to be provided with a key file.

With v3 onions addresses it is no longer possible for adversaries to learn about their existence if they are not published -- this was not the case previously with v2 onion addresses. Therefore, some readers might wonder what is the purpose of onion services authentication for v3 onions.

Authentication for v3 onions exists to eliminate the side risks of the onion address accidentally being leaked. This is feasible due to human error, a bug in the software using the onion address, or other yet unknown possibilities. By using onion services authentication, the onion service could not be accessed even if the onion address was leaked.

[Quote](https://lists.torproject.org/pipermail/tor-dev/2019-December/014106.html):

<blockquote>
Also, if you have multiple users, having one v3 address with authentication is much better than multiple addresses, for the following reasons:

* easier management

*	easier to configure and easier to maintain the application behind it (web server or whatever it is)

* less resources needed by the Tor daemon

*	less load on your guard(s) / bridge(s), thus more capacity and better experience for your clients / visitors (if you have multiple addresses you need to maintain active introduction point circuits for all of them, publish descriptors, etc.)
</blockquote>


### Onion Service Operator

Once you have configured client authorization, anyone with the address will not be able to access it from this point on. If no authorization is configured, the service will be accessible to anyone with the onion address.

To configure client authorization on the service side, the <*HiddenServiceDir*>/authorized_clients/ directory needs to exist. Creating an onion service using the HiddenServiceDir and HiddenServicePort on torrc and reloading or restarting tor will automatically create this directory. Client authorization will only be enabled for the service if tor successfully loads at least one authorization file.

For now, you need to create the keys yourself with a script (like these written in Bash, Rust or Python) or manually.

To manually generate the keys, you need to install openssl version 1.1+ and basez.

1. Generate a key using the algorithm x25519:
```sh
openssl genpkey -algorithm x25519 -out /tmp/k1.prv.pem
```

If you get an error message, something has gone wrong and you cannot continue until you've figured out why this didn't work.

2. Format the keys into base32:

Private key
```sh
cat /tmp/k1.prv.pem | grep -v " PRIVATE KEY" | base64pem -d | tail --bytes=32 | base32 | sed 's/=//g' > /tmp/k1.prv.key
```

Public key
```sh
openssl pkey -in /tmp/k1.prv.pem -pubout | grep -v " PUBLIC KEY" | base64pem -d | tail --bytes=32 | base32 | sed 's/=//g' > /tmp/k1.pub.key
```

3. Copy the public key:
```sh
cat /tmp/k1.pub.key
```

4. Create an authorized client file:

Format the client authentication and create a new file in <*HiddenServiceDir*>/authorized_clients/ directory. Each file in that directory should be suffixed with ".auth" (i.e. "alice.auth"; the file name is irrelevant) and its content format must be:
`<auth-type>:<key-type>:<base32-encoded-public-key>`

The supported values for <*auth-type*> are: "descriptor".

The supported values for <*key-type*> are: "x25519".

The <*base32-encoded-public-key*> is the base32 representation of the raw key bytes only (32 bytes for x25519).

For example, the file `/var/lib/tor/services/hidden_service/authorized_clients/alice.auth` should look like:
`descriptor:x25519:N2NU7BSRL6YODZCYPN4CREB54TYLKGIE2KYOQWLFYC23ZJVCE5DQ`

If you are planning to have more authenticated clients, each file must contain one line only. Any malformed file will be ignored.

5. Reload the tor service:
```
systemctl reload tor
```

If you get an error message, something has gone wrong and you cannot continue until you've figured out why this didn't work.

Important: Revoking a client can be done by removing their ".auth" file, however the revocation will be in effect only after the tor process gets restarted.


### Onion Service Client

You can get the access credentials from the onion service operator. Reach out to the operator and request access. You may authenticate yourself directly in the Tor Browser. When accessing an authenticated onion service, Tor Browser will show in the URL bar an icon of a little gray key, accompanied by a tooltip. Enter your valid client private key into the input field.

To access a version 3 onion service with client authorization as a client, make sure you have ClientOnionAuthDir set in your torrc. For example, add this line to /etc/tor/torrc:
```
ClientOnionAuthDir /var/lib/tor/onion_auth
```
Then, in the <*ClientOnionAuthDir*> directory, create an .auth_private file for the onion service corresponding to this key (i.e. 'bob_onion.auth_private'). The content of the <*ClientOnionAuthDir*>/<*user*>.auth_private file should look like this:

`<56-char-onion-addr-without-.onion-part>:descriptor:x25519:<*x25519 private key in base32*>`

For example:
`rh5d6reakhpvuxe2t3next6um6iiq4jf43m7gmdrphfhopfpnoglzcyd:descriptor:x25519:ZDUVQQ7IKBXSGR2WWOBNM3VP5ELNOYSSINDK7CAUN2WD7A3EKZWQ`

If you manually generated the key pair following the instructions in this page, you can copy and use the private key created in Step 2. Then restart tor and you should be able to connect to the onion service address.

If you are generating a private key for an onion site, the user does not necessarily need to edit Tor Browser's torrc. It is possible to enter the private key directly in the Tor Browser interface.

For more information about client authentication, please see Tor manual.

## Source

Synopsis - https://support.torproject.org/onionservices/client-auth/

Setup client auth - https://community.torproject.org/onion-services/advanced/client-auth/

Use keys on Tor Browser - https://tb-manual.torproject.org/onion-services/#onion-service-authentication
