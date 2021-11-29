# TORRC

This list of torrc commands explains only the specific configuration options that are managed by OnionJuggler. Consult the full source on https://github.com/torproject/tor/blob/main/doc/man/tor.1.txt.

## COMMMAND-LINE OPTIONS

List all onion services options:
```
sudo -u "${tor_user}" tor --list-torrc-options | grep "HS\|HiddenService"
```

Verify the configuration file is valid:
```
sudo -u "${tor_user}" tor --verify-config
```

## THE CONFIGURATION FILE FORMAT

All configuration options in a configuration are written on a single line by default. They take the form of an option name and a value, or an option name and a quoted value (option value or option "value"). Anything after a # character is treated as a comment. Options are case-insensitive. C-style escaped characters are allowed inside quoted values. To split one configuration entry into multiple lines, use a single backslash character (\) before the end of the line. Comments can be used in such multiline entries, but they must start at the beginning of a line.

Configuration options can be imported from files or folders using the %include option with the value being a path. If the path is a file, the options from the file will be parsed as if they were written where the %include option is. If the path is a folder, all files on that folder will be parsed following lexical order. Files starting with a dot are ignored. Files on subfolders are ignored. The %include option can be used recursively.

By default, an option on the command line overrides an option found in the configuration file, and an option in a configuration file overrides one in the defaults file.

This rule is simple for options that take a single value, but it can become complicated for options that are allowed to occur more than once: if you specify four SocksPorts in your configuration file, and one more SocksPort on the command line, the option on the command line will replace all of the SocksPorts in the configuration file. If this isn’t what you want, prefix the option name with a plus sign (+), and it will be appended to the previous set of options instead. For example, setting SocksPort 9100 will use only port 9100, but setting +SocksPort 9100 will use ports 9100 and 9050 (because this is the default).

Alternatively, you might want to remove every instance of an option in the configuration file, and not replace it at all: you might want to say on the command line that you want no SocksPorts at all. To do that, prefix the option name with a forward slash (/). You can use the plus sign (+) and the forward slash (/) in the configuration file and on the command line.

## HiddenServiceDir *DIRECTORY*

Store data files for a hidden service in DIRECTORY. Every hidden service must have a separate directory. You may use this option multiple times to specify multiple services. If DIRECTORY does not exist, Tor will create it. Please note that you cannot add new Onion Service to already running Tor instance if Sandbox is enabled. (Note: in current versions of Tor, if DIRECTORY is a relative path, it will be relative to the current working directory of Tor instance, not to its DataDirectory. Do not rely on this behavior; it is not guaranteed to remain the same in future versions.)

## HiddenServiceVersion 2|3

A list of rendezvous service descriptor versions to publish for the hidden service. Currently, versions 2 and 3 are supported. (Default: 3)

## HiddenServicePort *VIRTPORT* [TARGET]

Configure a virtual port VIRTPORT for a hidden service. You may use this option multiple times; each time applies to the service using the most recent HiddenServiceDir. By default, this option maps the virtual port to the same port on 127.0.0.1 over TCP. You may override the target port, address, or both by specifying a target of addr, port, addr:port, or unix:path. (You can specify an IPv6 target as [addr]:port. Unix paths may be quoted, and may use standard C escapes.) You may also have multiple lines with the same VIRTPORT: when a user connects to that VIRTPORT, one of the TARGETs from those lines will be chosen at random. Note that address-port pairs have to be comma-separated.

## ClientOnionAuthDir *path*

Path to the directory containing v3 hidden service authorization files. Each file is for a single onion address, and the files MUST have the suffix ".auth_private" (i.e. "bob_onion.auth_private"). The content format MUST be:
<*onion-address*>:descriptor:x25519:<*base32-encoded-privkey*>
The <*onion-address*> MUST NOT have the ".onion" suffix. The <*base32-encoded-privkey*> is the base32 representation of the raw key bytes only (32 bytes for x25519). See Appendix G in the rend-spec-v3.txt file of torspec for more information.

## HashedControlPassword *hashed_password*

Allow connections on the control port if they present the password whose one-way hash is hashed_password. You can compute the hash of a password by running "tor --hash-password password". You can provide several acceptable passwords by using more than one HashedControlPassword line.

## CookieAuthentication 0|1

If this option is set to 1, allow connections on the control port when the connecting process knows the contents of a file named "control_auth_cookie", which Tor will create in its data directory. This authentication method should only be used on systems with good filesystem security. (Default: 0)
