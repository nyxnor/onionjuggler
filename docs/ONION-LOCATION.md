## Onion-Location

Onion-Location is an easy way to advertise an onion site to the users.
You can either configure a web server to show an Onion-Location Header or add an HTML meta attribute in the website.

For the header to be valid the following conditions need to be fulfilled:

 * The Onion-Location value must be a valid URL with http: or https: protocol and a .onion hostname.
 * The webpage defining the Onion-Location header must be served over HTTPS.
 * The webpage defining the Onion-Location header must not be an onion site.

In this page, the commands to manage the web server are based Debian-like operating systems and may differ from other systems.
Check your web server and operating system documentation.

### Apache

To configure this header in Apache 2.2 or above, you will need to enable a `headers` and `rewrite` modules and edit the website Virtual Host file.

**Step 1.** Enable headers and rewrite modules and reload Apache2

```
sudo a2enmod headers rewrite
sudo systemctl reload apache2
```

If you get an error message, something has gone wrong and you cannot continue until you've figured out why this didn't work.

**Step 2.** Add the Onion-Location header to your Virtual Host configuration file

```
Header set Onion-Location "http://your-onion-address.onion%{REQUEST_URI}s"
```

Where `your-onion-address.onion` is the onion service address you want to redirect and `{REQUEST_URI}` is the [path component of the requested URI](https://httpd.apache.org/docs/2.4/mod/mod_rewrite.html), such as "/index.html".

Virtual Host example:

```
     <VirtualHost *:443>
       ServerName <your-website.tld>
       DocumentRoot /path/to/htdocs

       Header set Onion-Location "http://your-onion-address.onion%{REQUEST_URI}s"

       SSLEngine on
       SSLCertificateFile "/path/to/www.example.com.cert"
       SSLCertificateKeyFile "/path/to/www.example.com.key"
     </VirtualHost>
```

**Step 3.** Reload Apache

Reload the apache2 service, so your configuration changes take effect:
```
sudo systemctl reload apache2
```

If you get an error message, something has gone wrong and you cannot continue until you've figured out why this didn't work.

**Step 4.** Testing your Onion-Location

To test if Onion-Location is working, fetch the website HTTP headers, for example:

```
wget --server-response --spider your-website.tld
```

Look for `onion-location` entry and the onion service address.
Or open the website in Tor Browser and a purple pill will appear in the address bar.

### Nginx

To configure an Onion-Location header, the service operator should first configure an Onion service.

**Step 1.** Create an Onion service by setting the following in `torrc`:

```
HiddenServiceDir /var/lib/tor/hs-my-website/
HiddenServiceVersion 3
HiddenServicePort 80 unix:/var/run/tor-hs-my-website.sock
```

**Step 2.** Edit website configuration file

In `/etc/nginx/conf.d/<your-website>.conf` add the Onion-Location header and the onion service address.
For example:

```
    add_header Onion-Location http://your-onion-address.onion$request_uri;
```


The configuration file with the Onion-Location should look like this:

```
server {
    listen 80;
    listen [::]:80;

    server_name <your-website.tld>;

    location / {
       return 301 https://$host$request_uri;
    }

}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name <your-website.tld>;

    # managed by Certbot - https://certbot.eff.org/
    ssl_certificate /etc/letsencrypt/live/<hostname>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/<hostname>/privkey.pem;

    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header Onion-Location http://<your-onion-address>.onion$request_uri;

    # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    access_log /var/log/nginx/<hostname>-access.log;

    index index.html;
    root /path/to/htdocs;

    location / {
            try_files $uri $uri/ =404;
    }
}

server {
        listen unix:/var/run/tor-hs-my-website.sock;

        server_name <your-onion-address>.onion;

        access_log /var/log/nginx/hs-my-website.log;

        index index.html;
        root /path/to/htdocs;
}
```

**Step 3.** Test website configuration

```
sudo nginx -t
```

The web server should confirm that the new syntax is working:

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Step 4.** Restart nginx

```
sudo nginx -s reload
```

If you get an error message, something has gone wrong and you cannot continue until you've figured out why this didn't work.

**Step 5.** Testing your Onion-Location

To test if the Onion-Location is working, fetch the web site HTTP headers, for example:

```
wget --server-response --spider your-website.tld
```

Look for `onion-location` entry and the onion service address.
Or, open the web site in Tor Browser and a purple pill will appear in the address bar.

### Caddy

Caddy features [automatic HTTPS](https://caddyserver.com/docs/automatic-https) by default, so it provisions your TLS certificate and takes care of HTTP-to-HTTPS redirection for you.
If you're using Caddy 2, to include an Onion-Location header, add the following declaration in your Caddyfile:

```
header Onion-Location http://your-onion-address.onion{path}
```

If you're running a static site and have the onion address in a `$TOR_HOSTNAME` environment variable, your Caddyfile will look like this:

```
your-website.tld

header Onion-Location http://your-onion-address.onion{path}
root * /var/www
file_server
```

**Testing it out:** Test it out with:

```
wget --server-response --spider your-website.tld
```

Look for `onion-location` entry and the onion service address.
Or, open the web site in Tor Browser and a purple pill will appear in the address bar.

### Using an HTML `<meta>` attribute

The identical behaviour of Onion-Location includes the option of defining it as a HTML `<meta>` http-equiv attribute.
This may be used by websites that prefer (or need) to define an Onion-Location by modifying the served HTML content instead of adding a new HTTP header.
The Onion-Location header would be equivalent to a `<meta http-equiv="onion-location" content="http://your-onion-address.onion" />` added in the HTML head element of the webpage. Replace `your-onion-address.onion` with the onion service that you want to redirect.

### More information

Read the [Onion-Location spec](https://gitweb.torproject.org/tor-browser-spec.git/tree/proposals/100-onion-location-header.txt).

## Source

https://community.torproject.org/onion-services/advanced/onion-location/
