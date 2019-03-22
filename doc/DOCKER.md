# Docker

You can use [Docker](https://www.docker.com/) for running LibreTaxi in container.

# Installation

To install Docker you can follow [installation instructions](https://docs.docker.com/install/).

# Usage

After you have installed Docker you can just `cd` into the project directory
```bash
cd libertaxi
```

To build container
```bash
docker build -t libretaxi  .
```

Note that container does not contain Redis server, you need either to run Redis container separately and connect it with libretaxi container with [bridge networks](https://docs.docker.com/network/bridge/) or to run container in the host network (works only on Linux):

```bash
docker run -ti --rm --net host libretaxi npm run telegram
```

Configuration variables can be specified as docker environment variables with `LT_` prefix:
```bash
docker run -ti --rm --net host \
  -e LT_STATEFUL_CONNSTR="https://your-firebase-project.firebaseio-id.com/" \
  -e LT_STATEFUL_CREDENTIALS="$(< "./libretaxi-development-credentials.json")" \
  -e LT_TELEGRAM_TOKEN="YOUR TELEGRAM TOKEN" \
  -e LT_DEFAULT_LANGUAGE="en" \
  -e LT_LOG_FILE="PATH TO LOG FILE" \
  -e LT_MAX_RADIUS=10 \
   libretaxi npm run telegram
```

After that you can use all needed commands described in
[Getting Started](GETTING-STARTED.md) section.

