# Deploying RetroHive across three machines

The target layout: HAProxy facing clients, Apache on its own VM, MariaDB on
another.

**Two applications, not one.** `retrohive-core` is the engine - `/api/v1` and a
short list of paths that cannot be anything else. `retrohive-clients-web` is the
browser interface, and it is a client: it holds no database credentials and makes
no database call, reaching the data over the same HTTP API a phone uses. They can
share an Apache instance, but they are two document roots and two names, and the
engine has to be told where the client is or a browser arriving at the engine's
address gets a 503 saying it has not been configured.

```
                    internet / clients
                            |
                     [ HAProxy VM ]          TLS terminates here
                      10.0.0.10              X-Forwarded-* added
                            |
                            |  plain HTTP, internal network
                            v
   internal browsers -> [ Apache VM ]        both applications live here
                          10.0.0.20          retro.example.com  -> core/public
                                             app.example.com    -> clients-web/public
                            |
                            |  TCP 3306, internal only
                            v
                      [ MariaDB VM ]
                          10.0.0.30
```

Four things must line up or the install will look subtly broken rather than
plainly broken:

1. Apache must be told which proxy to believe (`trusted_proxies`)
2. The engine must know its public address (`base_url`)
3. MariaDB must accept connections from the Apache VM and nowhere else
4. The engine must know where the web client is (`client_url`), and the web
   client must know where the engine is (`CORE_ENGINE_URL`)

The fourth is the one the split added, and it fails in a way worth recognising:
finishing first-run setup ends by handing the browser to the client, and with
`client_url` unset that is a 503 headed "Not configured" **after** the
administrator account has been created successfully. Nothing is wrong with the
account; the engine simply has nowhere to send them.

---

## 1. MariaDB VM (10.0.0.30)

```bash
apt install mariadb-server            # or: zypper install mariadb
```

Bind to the internal interface only — never `0.0.0.0` unless a firewall is
doing the work instead:

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
bind-address            = 10.0.0.30
character-set-server    = utf8mb4
collation-server        = utf8mb4_unicode_ci
max_connections         = 100
innodb_buffer_pool_size = 1G          # tune to the VM, roughly 60% of RAM
```

Create the database and a user restricted to the Apache VM's address:

```sql
CREATE DATABASE retrohive CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'retrohive'@'10.0.0.20' IDENTIFIED BY 'a-long-random-password';
GRANT SELECT, INSERT, UPDATE, DELETE ON retrohive.* TO 'retrohive'@'10.0.0.20';
FLUSH PRIVILEGES;
```

`GRANT ALL` is not needed at runtime; the app never issues DDL. Load the schema
as root instead:

```bash
# from the Apache VM, or copy the .sql files over
mariadb -h 10.0.0.30 -u root -p retrohive < db/schema.sql
mariadb -h 10.0.0.30 -u root -p retrohive < db/seed.sql
```

Firewall it so only the web VM can reach 3306:

```bash
ufw allow from 10.0.0.20 to any port 3306 proto tcp
ufw deny 3306
```

**Timezone tables.** The app sets its session timezone by numeric offset, which
works without them, but loading them is worth doing anyway:

```bash
mariadb-tzinfo-to-sql /usr/share/zoneinfo | mariadb -u root -p mysql
```

**TLS between the VMs** is worth enabling if the network is shared. Point
`ssl-ca`, `ssl-cert` and `ssl-key` at your certificates in the server config,
then require it for the account:

```sql
ALTER USER 'retrohive'@'10.0.0.20' REQUIRE SSL;
```

---

## 2. Apache VM (10.0.0.20)

```bash
apt install apache2 php php-mysql php-gd php-mbstring php-ldap php-curl
a2enmod rewrite headers remoteip
```

`php-ldap` is only needed if you plan to use directory sign-in, but installing
it now saves a second maintenance window later.

Install the application:

```bash
mkdir -p /opt/retrohive
tar -xzf retrohive.tar.gz --strip-components=1 -C /opt/retrohive
cd /opt/retrohive
cp src/config.local.php.example src/config.local.php
chown -R root:root /opt/retrohive
chown -R www-data:www-data /opt/retrohive-core/public/uploads
chmod 775 /opt/retrohive-core/public/uploads
chgrp www-data src/config.local.php && chmod 640 src/config.local.php
```

### Configuration

```php
// /opt/retrohive-core/src/config.local.php
return [
    'timezone' => 'Europe/Stockholm',
    'currency' => 'SEK',
    'debug'    => false,

    'db' => [
        'host' => '10.0.0.30',          // the MariaDB VM
        'port' => 3306,
        'name' => 'retrohive',
        'user' => 'retrohive',
        'pass' => 'a-long-random-password',
    ],

    // The address clients actually use. Without this the API hands phones
    // http:// image URLs, which iOS App Transport Security refuses to load.
    'base_url' => 'https://retro.example.com',

    // Only HAProxy may set X-Forwarded-*. Anything else is treated as a
    // direct client and its headers ignored.
    'trusted_proxies' => ['10.0.0.10'],
];
```

### Virtual host

```apache
<VirtualHost *:80>
    ServerName retro.example.com
    DocumentRoot /opt/retrohive-core/public

    <Directory /opt/retrohive-core/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Log the client's address rather than HAProxy's. Purely cosmetic for the
    # application - it does its own resolution - but it makes the access log
    # readable.
    RemoteIPHeader X-Forwarded-For
    RemoteIPTrustedProxy 10.0.0.10
    LogFormat "%a %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" proxy
    CustomLog /var/log/apache2/retrohive-access.log proxy
    ErrorLog  /var/log/apache2/retrohive-error.log
</VirtualHost>
```

### The web client's virtual host

A second name and a second document root on the same Apache. It needs no database
access and no `config.local.php`; it is told where the engine is through the
environment, the same way the test runner tells it.

```apache
<VirtualHost *:80>
    ServerName app.example.com
    DocumentRoot /opt/retrohive-clients-web/public

    <Directory /opt/retrohive-clients-web/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Where the engine is. Over the internal network rather than back out
    # through HAProxy: the client is on the same machine, and a request that
    # leaves to come straight back is two TLS handshakes for nothing.
    SetEnv CORE_ENGINE_URL         http://127.0.0.1/api/v1
    SetEnv CORE_ENGINE_UPLOADS_URL https://retro.example.com/uploads

    RemoteIPHeader X-Forwarded-For
    RemoteIPTrustedProxy 10.0.0.10
    CustomLog /var/log/apache2/retrohive-web-access.log proxy
    ErrorLog  /var/log/apache2/retrohive-web-error.log
</VirtualHost>
```

`CORE_ENGINE_UPLOADS_URL` is a public address and `CORE_ENGINE_URL` is not,
which looks inconsistent and is not: the client *fetches* from the API itself,
and the browser fetches the photographs. An internal address in an `<img>` is a
broken image on every device outside the network.

And the engine has to be told the way back:

```sql
-- or through Settings once an administrator exists
INSERT INTO settings (`key`, value) VALUES ('client_url', 'https://app.example.com')
    ON DUPLICATE KEY UPDATE value = VALUES(value);
```

Without it, `https://retro.example.com/` answers 503 rather than sending a
browser to the interface - which is the correct refusal and a confusing one if
nobody has read this far.

### Reaching it internally

Internal browsers can reach `http://10.0.0.20/` directly. Requests arriving that
way carry no forwarded headers, the proxy logic ignores them, and everything
still works — the only difference is that session cookies will not be marked
`Secure`, which is correct for a plain HTTP request.

If you would rather internal users also went through HTTPS, give the Apache VM
its own certificate and serve 443 as well; nothing in the app needs changing.

### PHP settings

```ini
; /etc/php/8.3/apache2/conf.d/99-retrohive.ini
upload_max_filesize = 16M
post_max_size = 128M
max_file_uploads = 30
memory_limit = 512M
max_execution_time = 120
expose_php = Off
session.cookie_httponly = 1
session.use_strict_mode = 1
```

---

## 3. HAProxy VM (10.0.0.10)

```haproxy
global
    log /dev/log local0
    tune.ssl.default-dh-param 2048

defaults
    mode http
    log global
    option httplog
    option forwardfor                 # adds X-Forwarded-For
    timeout connect 5s
    timeout client  60s
    timeout server  60s

frontend retro_https
    bind *:443 ssl crt /etc/haproxy/certs/retro.example.com.pem
    bind *:80
    http-request redirect scheme https unless { ssl_fc }

    # The application reads these. option forwardfor covers X-Forwarded-For.
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    http-request set-header X-Forwarded-Proto http  unless { ssl_fc }
    http-request set-header X-Forwarded-Host %[req.hdr(host)]
    http-request set-header X-Forwarded-Port %[dst_port]

    # Photo uploads from a phone are several megabytes.
    http-request set-var(txn.body_size) req.body_size

    default_backend retro_web

backend retro_web
    option httpchk GET /api/v1/meta
    http-check expect status 200
    server web1 10.0.0.20:80 check inter 10s fall 3 rise 2
```

Three details that matter here:

**Strip incoming forwarded headers.** A client can send its own
`X-Forwarded-For` and, if HAProxy simply appends, the chain starts with a value
the client chose. RetroHive walks the chain from the right and stops at the
first address that is not a trusted proxy, so a forged prefix cannot become the
recorded IP — but deleting the header is cheaper than relying on that:

```haproxy
    http-request del-header X-Forwarded-For
    http-request del-header X-Forwarded-Proto
    http-request del-header X-Forwarded-Host
```

Put these *before* the `set-header` lines above.

**Health check.** `/api/v1/meta` is the right endpoint: it needs no
authentication, it touches the database, and it returns 200 only when the
application is actually able to answer. Checking `/` would follow a redirect to
the sign-in page and tell you nothing about the database.

**Body size.** HAProxy does not limit request bodies by default, so uploads pass
through. If you have added a limit elsewhere, make sure it exceeds
`post_max_size`.

### Sticky sessions

Not needed with one backend server. If you add a second Apache VM later, PHP
sessions are stored on local disk, so you would need either cookie-based
stickiness or shared session storage:

```haproxy
    cookie RVSRV insert indirect nocache
    server web1 10.0.0.20:80 check cookie web1
    server web2 10.0.0.21:80 check cookie web2
```

The API needs no stickiness at all — bearer tokens live in the database.

---

## Verifying the chain

From the Apache VM, confirm the database:

```bash
mariadb -h 10.0.0.30 -u retrohive -p retrohive -e "SELECT COUNT(*) FROM platforms;"
```

From anywhere, confirm the proxy is being believed. Sign in on the web client,
then look at **Manage → Authentication**: the recent sign-in table shows the
client IP. If it
shows `10.0.0.10`, `trusted_proxies` is not configured and the app is recording
HAProxy instead of the client.

Confirm the generated URLs:

```bash
curl -s https://retro.example.com/api/v1/items?per_page=1 \
     -H "Authorization: Bearer rvt_..." | grep -o 'https://[^"]*uploads[^"]*' | head -1
```

That must come back as `https://retro.example.com/uploads/...`. If it is
`http://` or an internal hostname, set `base_url`.

Confirm the session cookie — from the **client**, which is where sessions live
now. The engine has no `/login`; it went with the screens.

```bash
curl -sD- -o /dev/null https://app.example.com/login | grep -i set-cookie
```

It should include `secure`. If it does not, the `X-Forwarded-Proto` header is
not arriving or `trusted_proxies` does not include the HAProxy address.

Confirm the two halves can see each other:

```bash
# the engine sends a browser to the client rather than refusing
curl -sD- -o /dev/null https://retro.example.com/ | grep -i '^location'

# the client can reach the engine: a sign-in page rather than "did not answer"
curl -s https://app.example.com/login | grep -o '<title>[^<]*'
```

A 503 from the first is `client_url` unset. An error banner from the second is
`CORE_ENGINE_URL` wrong, and it will say the server did not answer while the API
is up and the phones are working.

---

## What breaks without each setting

| Missing | Symptom |
|---|---|
| `trusted_proxies` | Session cookies lack `Secure`; every audit entry records HAProxy's IP; API image URLs use `http://` |
| `base_url` | Mobile apps show broken images; iOS blocks the requests outright under App Transport Security |
| `X-Forwarded-Proto` from HAProxy | Same as missing `trusted_proxies` — the app cannot tell the request was HTTPS |
| MariaDB `bind-address` | Either the app cannot connect, or the database is reachable from the whole network |
| `fastcgi_param HTTP_AUTHORIZATION` (nginx only) | Every API call returns 401, so the phones fail and so does the web client, which is one |
| `client_url` on the engine | First-run setup succeeds and then answers 503 "Not configured"; `/` never reaches the interface |
| `CORE_ENGINE_URL` on the client | Every page reports that the server did not answer, while the API is up and the phones are fine |
| `CORE_ENGINE_UPLOADS_URL` pointing somewhere internal | Photographs load on the office network and nowhere else |

---

## Backups

Run them from the Apache VM; the script reads the database credentials out of
`config.local.php` and connects over the network like the app does.

```bash
/opt/retrohive-core/bin/backup.sh /srv/backups/retrohive
```

```cron
30 3 * * * /opt/retrohive-core/bin/backup.sh /srv/backups/retrohive >> /var/log/retrohive-backup.log 2>&1
```

### Housekeeping

Two tables and one directory grow on their own: `auth_log` gains a row per
sign-in attempt, the notification queue keeps what it has sent, and
`public/uploads` keeps photos whose entry has since been deleted. Nothing trims
them unless something is scheduled to.

```bash
./bin/maintenance.sh              # prune the sign-in log, report orphaned files
./bin/maintenance.sh --delete     # and delete the orphans
```

```cron
15 4 * * * /opt/retrohive-core/bin/maintenance.sh >> /var/log/retrohive-maintenance.log 2>&1
```

Queued notification mail is separate, because it wants sending promptly rather
than nightly:

```cron
*/5 * * * * cd /opt/retrohive && php bin/notify.php send >/dev/null
```

The photos live only on the Apache VM, the data only on the MariaDB VM, and a
restore needs both from the same run — `item_images` rows reference filenames on
disk.
