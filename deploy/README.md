# Deploying

`refresh-retrohive.sh` redeploys both halves that live on the vhost: this engine
under `retrohive/`, and the web client under `retrohive-web/`.

It runs **from the server**, not from a checkout, because it deletes and replaces
the checkout it would otherwise be running inside. So it is a copy:

    cp deploy/refresh-retrohive.sh /srv/www/vhosts/refresh-retrohive.sh

It ships here so that copy has somewhere to be compared against. The script says
so itself when the two differ - a fix made in the repository and never copied is
a fix that goes on not working, which is how a corrected deploy check kept
reporting a fault that had already been fixed.
