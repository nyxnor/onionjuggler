## WHAT'S A CLIENT OR ONION AUTHENTICATION

An authenticated onion service is an onion service that requires the client to provide an authentication credential to connect to the onion service. For v3 onion services, this method works with a pair of keys (a public and a private). The service side is configured with a public key and the client can only access it with a private key. The client private key is not transmitted to the service, and it's only used to decrypt its descriptor locally.

### ONION SERVICE OPERATOR

Once you have configured client authorization, anyone with the address will not be able to access it from this point on. If no authorization is configured, the service will be accessible to anyone with the onion address.

### ONION SERVICE CLIENT

You can get the access credentials from the onion service operator. Reach out to the operator and request access. You may authenticate yourself directly in the Tor Browser. When accessing an authenticated onion service, Tor Browser will show in the URL bar an icon of a little gray key, accompanied by a tooltip. Enter your valid client private key into the input field.


### SOURCE:

Synopsis - https://support.torproject.org/onionservices/client-auth/

Setup client auth - https://community.torproject.org/onion-services/advanced/client-auth/

Use keys on Tor Browser - https://tb-manual.torproject.org/onion-services/#onion-service-authentication
