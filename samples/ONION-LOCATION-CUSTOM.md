# Onion-Location guided steps

Notes:

* The below output is merely an example, no web server config file or index.html is overwritten.
* for web servers, include header line inside the plainnet ssl block (port 443).

# Method

## NGINX

Config:
```
        server {
            listen 443 ssl http2;
            listen [::]:443 ssl http2;
            add_header Onion-Location http://TOR_HOSTNAME$request_uri;
        }
```


## APACHE

Enable headers and rewrite modules:
```
        sudo a2enmod headers rewrite
```

Config:
```
        <VirtualHost *:443>
            Header set Onion-Location "http://TOR_HOSTNAME%{REQUEST_URI}s"
        </VirtualHost>
```


## HTML

Config
```
  <meta http-equiv="onion-location" content="http://TOR_HOSTNAME" />
```

# Apply

## Reload web server
```
        sudo nginx -t && sudo nginx -s reload

        sudo systemctl reload apache
```

# Verify

## Test if the Onion-Location is working

Open the web site in Tor Browser and a purple pill will appear in the address bar or fetch the web site HTTP headers and look for onion-location entry and the onion service address:
```
        wget --server-response --spider your-website.tld
```