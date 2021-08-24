### Onionbalance

[Onionbalance](https://onionbalance-v3.readthedocs.io/en/latest/v3/tutorial-v3.html) allows onion service operators to achieve the property of high availability by allowing multiple machines to handle requests for an onion service.
You can use Onionbalance to scale horizontally.
The more you scale, the harder it is for attackers to overwhelm you.
Onionbalance is available for [v3 onion services](https://blog.torproject.org/cooking-onions-reclaiming-onionbalance).

### Client authorization or multiple onion addresses to compartmentalize your users

If you have users you trust, give them dedicated onion service and client authorization credentials so that it can always be available.
For users you don't trust, split them into multiple addresses.
That said, having too many onion addresses is actually bad for your security (because of the use of many guard nodes), so try to use [client authorization](https://community.torproject.org/onion-services/advanced/client-auth) when possible.

### Webserver rate limiting

If attackers are overwhelming you with aggressive circuits that perform too many queries, try to detect that overuse and kill them using the `HiddenServiceExportCircuitID` torrc option.
You can use your own heuristics or use your web server's [rate limiting module](https://www.nginx.com/blog/rate-limiting-nginx/).

The above tips should help you keep afloat in turbulent times.
At the same time [we are working on more advanced defenses](https://blog.torproject.org/stop-the-onion-denial), so that less manual configuration and tinkering is needed by onion operators.


### Source

https://community.torproject.org/onion-services/advanced/dos/