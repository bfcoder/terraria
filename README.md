# terraria

A vanilla Terraria dedicated server in Docker, built from the official server download on terraria.org.

Image: `ghcr.io/bfcoder/terraria`. Tags are `latest` and the Terraria version, for example `1.4.6.1`.

## Quick start

```sh
docker run -d --name terraria \
  -p 7777:7777 \
  -v "$PWD/data:/data" \
  -e WORLD_NAME=myworld \
  ghcr.io/bfcoder/terraria:latest
```

You can also use the included `docker-compose.yml` with `docker compose up -d`.

If the world doesn't exist yet, the server creates it on first start. A medium world takes a few minutes. Follow progress with `docker logs -f terraria`.

## Configuration

On first start, the server writes `/data/serverconfig.txt` from these environment variables. To change settings later, edit that file, or set `REGENERATE_CONFIG=1` to rebuild it from the environment variables. You can also mount your own `serverconfig.txt` at `/data/serverconfig.txt`.

| Variable | Default | Description |
|---|---|---|
| `WORLD_NAME` | `world` | World file name, stored as `/data/worlds/<name>.wld` |
| `WORLD_SIZE` | `2` | Size used if the world must be created: 1=small, 2=medium, 3=large |
| `DIFFICULTY` | `0` | 0=classic, 1=expert, 2=master, 3=journey |
| `SEED` | | World seed, used only when the world is created |
| `MAX_PLAYERS` | `8` | Maximum number of players, 1 to 255 |
| `PORT` | `7777` | Port the server listens on |
| `PASSWORD` | | Server password |
| `MOTD` | | Message of the day |
| `SECURE` | `1` | Extra cheat protection |
| `LANGUAGE` | `en-US` | Server language |
| `NPC_STREAM` | `60` | NPC streaming value; lower it to reduce enemy skipping |
| `PRIORITY` | `1` | Process priority |
| `UPNP` | `0` | Automatic port forwarding |

To use a world you already have, copy the `.wld` file into `data/worlds/` and set `WORLD_NAME` to its name without `.wld`.

## Console commands

The server reads its stdin from a FIFO, so it runs without a TTY. To send console commands:

```sh
docker exec terraria terraria-cmd say Hello everyone
docker exec terraria terraria-cmd save
```

When the container receives `docker stop`, it sends `exit` to the server, which saves the world before shutting down. Allow enough stop time with `docker stop -t 60` or `stop_grace_period`.

## Building

```sh
docker build --build-arg TERRARIA_VERSION=1461 -t terraria .
```

The official server is x86_64 only. On Apple Silicon the build succeeds, but under Rosetta the Mono runtime crashes at startup. Run it on an amd64 host.

The GitHub Actions workflow builds and smoke-tests the image on every push to `main`, then publishes it to GHCR. It also rebuilds weekly to pick up new Terraria releases. To build a specific version, run the workflow manually.
