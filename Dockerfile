FROM node:8.15-stretch

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r libretaxi && useradd -m -s /bin/bash -r -g libretaxi libretaxi

# grab gosu for easy step-down from root
RUN set -eux; \
    apt-get update; \
    apt-get install -y gosu; \
    rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
    gosu nobody true

# grab tini for signal processing and zombie killing
ENV TINI_VERSION v0.18.0
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget ca-certificates; \
    rm -rf /var/lib/apt/lists/*; \
    wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini"; \
    wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    for server in $(shuf -e ha.pool.sks-keyservers.net \
                                hkp://p80.pool.sks-keyservers.net:80 \
                                keyserver.ubuntu.com \
                                hkp://keyserver.ubuntu.com:80 \
                                pgp.mit.edu) ; do \
        gpg --no-tty --keyserver "$server" --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 && break || : ; \
    done; \
    gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
    { command -v gpgconf > /dev/null && gpgconf --kill all || :; }; \
    rm -rf "$GNUPGHOME" /usr/local/bin/tini.asc; \
    chmod +x /usr/local/bin/tini; \
    tini -h

ENV LT_STATEFUL_CONNSTR=https://libretaxi-development.firebaseio.com/ \
    LT_STATEFUL_CREDENTIALS_FILE=/var/lib/libretaxi/libretaxi-development-credentials.json \
    LT_STATEFUL_CREDENTIALS="" \
    LT_TELEGRAM_TOKEN="" \
    LT_DEFAULT_LANGUAGE="en" \
    LT_LOG_FILE="/var/log/libretaxi.log" \
    LT_MAX_RADIUS=10 \
    LT_GEOCODING_API_KEY=""

WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json .babelrc .eslintrc LICENSE settings-sample.js ./
COPY src ./src/
COPY test ./test/
COPY locales ./locales/
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eux; \
    chmod +x /usr/local/bin/entrypoint.sh; \
    npm install

CMD [ "npm", "run", "telegram" ]
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
