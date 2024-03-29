## Onion Services

Onion services (formerly known as "hidden services") are services (like websites) that are only accessible through the Tor network.

Onion services offer several advantages over ordinary services on the non-private web:

* Onion services’ location and IP address are hidden, making it difficult for adversaries to censor them or identify their operators.
* All traffic between Tor users and onion services is end-to-end encrypted, so you do not need to worry about connecting over HTTPS.
* The address of an onion service is automatically generated, so the operators do not need to purchase a domain name; the .onion URL also helps Tor ensure that it is connecting to the right location and that the connection is not being tampered with.

### How to access an Onion Service

Just like any other website, you will need to know the address of an onion service in order to connect to it. An onion address is a string of 56 mostly random letters and numbers, followed by ".onion".

When accessing a website that uses an onion service, Tor Browser will show in the URL bar an icon of an onion displaying the state of your connection: secure and using an onion service.
You can learn more about the onion site that you are visiting by looking at the Circuit Display.

Another way to learn about an onion site is if the website administrator has implemented a feature called Onion-Location.
Onion-Location is a non-standard HTTP header that websites can use to advertise their onion counterpart.
If the website that you are visiting has an onion site available, a purple suggestion pill will prompt at the URL bar in Tor Browser displaying ".onion available".
When you click on ".onion available", the website will be reloaded and redirected to its onion counterpart.

To prioritize an onion site version of a website, you can enable automatic Onion-Location redirects.
Click on hamburger menu (≡), go to Preferences (or Options on Windows), click on Privacy & Security, and in the Onion Services section look for the entry "Prioritize .onion sites when known." and check the option "Always".
Or, if you're already running Tor Browser, you can copy and paste this string in a new tab: `about:preferences#privacy` and change this setting.

## Onion Service Authentication

An authenticated onion service is a service like an onion site that requires the client to provide an authentication token before accessing the service.
As a Tor user, you may authenticate yourself directly in the Tor Browser.
In order to access this service, you will need access credentials from the onion service operator.
When accessing an authenticated onion service, Tor Browser will show in the URL bar an icon of a little gray key, accompanied by a tooltip.
Enter your valid private key into the input field.

### Onion Services Errors

If you can't connect to an onion site, Tor Browser will provide a specific error message informing why the website is unavailable.
Errors can happen in different layers: client errors, network errors or service errors.
Some of these errors can be fixed by following the Troubleshooting section.
The table below shows all the possible errors and which action you should take to solve the issue.

| **Code** | **Error Title** | **Short Description** |
|----------|-----------------|-----------------------|
| XF0 | Onion site Not Found | The most likely cause is that the onion site is offline or disabled. Contact the onion site administrator. |
| XF1 | Onion site Cannot Be Reached | The onion site is unreachable due to an internal error. |
| XF2 | Onion site Has Disconnected | The most likely cause is that the onion site is offline or disabled. Contact the onion site administrator. |
| XF3 | Unable to Connect to Onion site | The onion site is busy or the Tor network is overloaded. Try again later. |
| XF4 | Onion site Requires Authentication | Access to the onion site requires a key but none was provided. |
| XF5 | Onion site Authentication Failed | The provided key is incorrect or has been revoked. Contact the onion site administrator. |
| XF6 | Invalid Onion site Address | The provided onion site address is invalid. Please check that you entered it correctly. |
| XF7 | Onion site Circuit Creation Timed Out | Failed to connect to the onion site, possibly due to a poor network connection. |

### Troubleshooting

If you cannot reach the onion service you requested, make sure that you have entered the onion address correctly: even a small mistake will stop Tor Browser from being able to reach the site.

If you are still unable to connect to the onion service after verifying the address, please try again later. There may be a temporary connection issue, or the site operators may have allowed it to go offline without warning.

If the onion service you are trying to access consists of a string of 16 characters (V2 format), this type of address is [deprecated](https://support.torproject.org/onionservices/v2-deprecation/).

You can also test if you are able to access other onion services by connecting to [DuckDuckGo's Onion Service](https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion/).

## Source

https://tb-manual.torproject.org/onion-services/
