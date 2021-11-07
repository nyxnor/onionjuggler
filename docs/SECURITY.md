# Security Policy

## Supported Versions

No upgrade is enforced and will never be. If there is a security update, upgrades will be recommended to avoid greater risks.

## What is vulnerable?

* Unwanted deletion of the onion service `hs_ed25519_secret_key`.
* Extravagantly `high permissions` for files and folders that are not tor's default and are modified by this project. Defaults:
  * 600 -  `HiddenServiceDir/hostname`, `HiddenServiceDir/hs_ed25519_public_key`, `HiddenServiceDir/hs_ed25519_secret_key` (HiddenService files)
  * 644 - `torrc` (Configuration file)
  * 700 - `/var/lib/tor|DataDirectory`, `DataDirectory/services/*`, `DataDirectory/onion_auth` (DataDirectory, HiddenServiceDir and ClientOnionAuthDir)
  * 755 - `/etc/tor/` (Configuration directory)

## Reporting a Vulnerability

A vulnerability must be reported immediately. If there is no reply after 7 (seven) days, please reinforce the communication. If after 14 (fourteen) days no change is made, advertising a public is the recommended.

## Changelog

If there was a security vulnerability, the next release changelog must contain a changelog referencing the commit that fixed it.

## Contact

Please, communicate using cryptography.

* Email: nyxnor@protonmail.com
* PGP fingerprint: `A5FF74AB7F092BABB55DF1A96B6586CDC9BC8836`
* PGP public key:
```
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=ZJiS
-----END PGP PUBLIC KEY BLOCK-----
```
