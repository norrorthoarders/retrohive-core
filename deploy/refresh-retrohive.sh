#!/bin/sh
# Redeploys both halves that live on this vhost: the core engine under
# retrohive/, and the web client under retrohive-web/. Two separate checkouts
# with two separate lifecycles - the core engine owns a database and gets
# reinstalled from scratch every time, then migrated; the web client owns
# nothing and is just a clone plus a chown, the same as the iOS and Android
# apps talking to the same API from somewhere else entirely.
#
# The repository is retrohive-core, and every project sits in a retrohive
# subgroup on GitLab: norrorthoarders/retrohive/<project>.git.
#
# The checkout directories keep the names the vhost config expects. They are
# paths on a server, not repository names, and renaming one means editing the
# vhost in the same breath or serving a 404 until somebody notices.

set -e

# --- Core engine --------------------------------------------------------
rm -Rf /srv/www/vhosts/retrohive.noh.nu/retrohive
git clone git@gitlab.kladhest.se:norrorthoarders/retrohive/retrohive-core.git /srv/www/vhosts/retrohive.noh.nu/retrohive
chown -R wwwrun:www /srv/www/vhosts/retrohive.noh.nu/retrohive

# Migrations run after the install.
#
# The comment that used to sit at the top of this file said db/migrations/ was
# deliberately empty until a real version shipped. There are thirteen now, and
# `migrate.php up` applies whatever a fresh schema did not already carry.
php /srv/www/vhosts/retrohive.noh.nu/retrohive/bin/install.php --answers /srv/www/vhosts/retrohive-install.rsp
php /srv/www/vhosts/retrohive.noh.nu/retrohive/bin/migrate.php up
chown -R wwwrun:www /srv/www/vhosts/retrohive.noh.nu/retrohive

# --- Web client ----------------------------------------------------------
# No install.php, no migrate.php, no config.local.php: nothing here owns a
# database or a secret. APP_BASE_PATH, CORE_ENGINE_URL and
# CORE_ENGINE_UPLOADS_URL are set in the vhost, not here - this script's job
# ends at "the right code is in the right place, owned by the right user."
rm -Rf /srv/www/vhosts/retrohive.noh.nu/retrohive-web/
git clone git@gitlab.kladhest.se:norrorthoarders/retrohive/retrohive-clients-web.git /srv/www/vhosts/retrohive.noh.nu/retrohive-web
chown -R wwwrun:www /srv/www/vhosts/retrohive.noh.nu/retrohive-web

# --- This script -------------------------------------------------------
#
# It is a copy on the server, not something either checkout deploys - so a fix
# made in the repository never arrived, and a deploy went on reporting a fault
# that had been corrected two builds earlier.
#
# The engine's checkout carries it, so the newest one is right here. Compared
# rather than copied: overwriting a running script mid-run is how a shell reads
# half of one file and half of another.
mine="/srv/www/vhosts/retrohive.noh.nu/retrohive/deploy/refresh-retrohive.sh"
if [ -f "$mine" ] && ! cmp -s "$mine" "$0"; then
    echo "this script is out of date - the checkout has a newer one:"
    echo "  cp $mine $0"
fi

# --- Post-deploy check -----------------------------------------------------
# /status.json needs no token - it exists specifically so a check like this has
# nothing to authenticate and nothing to leak if it ends up in a log.
#
# There was a `curl .../auth/login` here that fetched a token into the
# environment and was never read by anything. It is gone: it put an
# administrator's password in a deploy script and a live token in the shell for
# no purpose. If a check needs one later, it belongs next to whatever uses it.
# The answer is kept, so a failure can say what came back.
#
# "NOT operational - check manually" said nothing about what to check: a
# connection refused, an HTML error page and a JSON body saying "unavailable" all
# printed the same line, and the next line was `jq` failing on whichever it was.
#
# No `-f`: the engine answers 503 when it cannot reach its database, and `-f`
# throws that body away - so the one case worth reading turned into an empty
# string indistinguishable from the host being down.
status="$(curl -s https://retrohive.noh.nu/status.json || true)"
if printf '%s' "$status" | grep -q '"operational"'; then
    echo "core engine: operational"
else
    echo "core engine: NOT operational after deploy - check manually" >&2
    if [ -z "$status" ]; then
        echo "  /status.json returned nothing - the engine is not answering" >&2
    else
        # `why` when the engine has one - it says which of "no configuration",
        # "a configuration nobody can read" and "the database is unreachable"
        # this is, and those want three different things done.
        why="$(printf '%s' "$status" | sed -n 's/.*"why" *: *"\([^"]*\)".*/\1/p')"
        if [ -n "$why" ]; then
            echo "  $why" >&2
        else
            echo "  it said: $status" >&2
        fi
    fi
fi

# The detailed status, when it is switched on.
#
# `/status/debug` 404s with a plain-text body unless `debug_status` is set, and
# piping that into `jq` produced "Invalid numeric literal at line 1, column 20" -
# which is jq reading the word "found." and is not a fault in anything it was
# meant to be checking.
#
# Asked for as JSON, and only printed when that is what came back.
debug="$(curl -s -H 'Accept: application/json' https://retrohive.noh.nu/status/debug || true)"
if printf '%s' "$debug" | head -c 1 | grep -q '{'; then
    printf '%s' "$debug" | jq
else
    echo "detailed status is off - set debug_status to switch it on"
fi
