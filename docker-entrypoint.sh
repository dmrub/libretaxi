#!/bin/bash

set -eo pipefail

message() {
    echo >&2 "[entrypoint.sh] $*"
}

info() {
    message "info: $*"
}

error() {
    echo >&2 "* [entrypoint.sh] Error: $*"
}

fatal() {
    error "$@"
    exit 1
}

message "info: EUID=$EUID args: $*"

usage() {
    echo "Entrypoint Script"
    echo ""
    echo "$0 [options]"
    echo "options:"
    echo "      --print-env            Display environment"
    echo "      --help"
    echo "      --help-entrypoint      Display this help and exit"
}

RUN_AS=

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help | --help-entrypoint)
            usage
            exit
            ;;
        --print-env)
            env >&2
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            break
            ;;
        *)
            break
            ;;
    esac
done

# Initialization
info "Preparing container ..."

echo "127.0.0.1   localhost.firebaseio.test" >>/etc/hosts

mkdir -p "$(dirname "$LT_STATEFUL_CREDENTIALS_FILE")"
mkdir -p "$(dirname "$LT_LOG_FILE")"

if [[ -n "$LT_STATEFUL_CREDENTIALS" ]]; then
    echo "$LT_STATEFUL_CREDENTIALS" >"$LT_STATEFUL_CREDENTIALS_FILE"
    chmod ugo+r "$LT_STATEFUL_CREDENTIALS_FILE"
fi
touch "$LT_LOG_FILE"
chown libretaxi:libretaxi "$LT_LOG_FILE"
chmod u+rw "$LT_LOG_FILE"

WORKDIR=/usr/src/app

cat >"$WORKDIR/settings.js" <<EOF
import appRoot from 'app-root-path';

/**
 * Settings
 */
export default class Settings {

  /**
   * Constructor.
   *
   * @param {Object} overrides - settings overrides. Useful for testing.
   */
  constructor(overrides) {
    // Firebase connection string
    this.STATEFUL_CONNSTR = '${LT_STATEFUL_CONNSTR}';

    // path to Firebase credentials file
    this.STATEFUL_CREDENTIALS_FILE = '${LT_STATEFUL_CREDENTIALS_FILE}';

    // Telegram token
    this.TELEGRAM_TOKEN = '${LT_TELEGRAM_TOKEN}';

    // default language
    this.DEFAULT_LANGUAGE = '${LT_DEFAULT_LANGUAGE}';

    // log file
    this.LOG_FILE = '${LT_LOG_FILE}';

    // maximum allowed radius for drivers
    this.MAX_RADIUS = ${LT_MAX_RADIUS};

    // geocoding api key, see
    // https://developers.google.com/maps/documentation/geocoding/intro
    this.GEOCODING_API_KEY = '${LT_GEOCODING_API_KEY}';

    Object.assign(this, overrides);
  }
}
EOF
chown libretaxi:libretaxi "$WORKDIR/settings.js"
cd "${WORKDIR}"

if [[ "$1" == 'npm' && "$(id -u)" == '0' ]]; then
    RUN_AS=libretaxi
fi

echo "Run: $*"
set -x
set -- /usr/local/bin/tini -- "$@"

# allow the container to be started with `--user`
if [[ -n "$RUN_AS" ]]; then
    if command -v su-exec >/dev/null 2>&1; then
        set -- su-exec "$RUN_AS" "$@"
    elif command -v gosu >/dev/null 2>&1; then
        set -- gosu "$RUN_AS" "$@"
    else
        fatal "Neither su-exec nor gosu program in path. Exiting"
    fi
fi

exec "$@"
