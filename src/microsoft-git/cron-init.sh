#!/usr/bin/env bash
set -e 

sudoIf()
{
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

sudoIf /etc/init.d/cron start 2>&1 | sudoIf tee /tmp/cron.log > /dev/null

set +e
exec "$@"