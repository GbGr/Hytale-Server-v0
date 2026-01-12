````md
# My Hytale Server (dev + prod) — one repo setup

This repository contains everything needed to run a **Hytale Dedicated Server** for:
- local development (macOS) on `localhost`
- production deployment (Ubuntu) via **Docker Compose**

It keeps **runtime binaries / assets / world data out of git** and stores only infrastructure + your code.

> Notes:
> - Hytale server runs **QUIC over UDP** (default port `5520/udp`), not TCP.
> - The server is a Java app and requires **Java 25** inside the container.
> - On first start (authenticated mode), you must run `/auth login device` in the server console.

---

## Repo layout

```text
my-hytale/
  runtime/                 # NOT COMMITTED: Server binaries, Assets.zip, worlds, logs
  infra/
    compose.yml            # docker compose (dev + prod profiles)
    env.dev
    env.prod
  scripts/
    bootstrap-macos.sh     # copy Server/ + Assets.zip from Hytale Launcher install
    bootstrap-linux.sh     # download Server/ + Assets.zip via official downloader
    up-dev.sh
    up-prod.sh
    auth-attach.sh
    install-plugin.sh
````

### What is **not** committed

`runtime/` contains:

* `Server/` (includes `HytaleServer.jar`, config, logs, mods, saves)
* `Assets.zip`
* `universe/`, `logs/`, etc.

These are environment-specific and can be large / license-bound.

---

## Prerequisites

### macOS (development)

* Docker Desktop installed and running

### Ubuntu (production)

* Docker Engine + Docker Compose plugin installed
* Firewall allows UDP port 5520:

  ```bash
  sudo ufw allow 5520/udp
  ```

---

## Quick start (macOS dev)

1. Prepare runtime from the installed Hytale Launcher:

```bash
./scripts/bootstrap-macos.sh
```

2. Start the dev server (attached console):

```bash
./scripts/up-dev.sh
```

3. Authenticate the server (first run, in server console):

```text
/auth login device
```

After that, your client can connect to:

* `127.0.0.1:5520` (UDP / QUIC)

Stop with `Ctrl+C`.

---

## Quick start (Ubuntu prod)

1. Prepare runtime by downloading the server package:

```bash
./scripts/bootstrap-linux.sh
```

2. Start in background:

```bash
./scripts/up-prod.sh
```

3. Attach to the server console to authenticate:

```bash
./scripts/auth-attach.sh
```

Then run in the console:

```text
/auth login device
```

To stop:

```bash
cd infra
docker compose --profile prod down
```

---

## Dev vs Prod configuration

Environment files:

* `infra/env.dev` — smaller memory, dev-friendly flags
* `infra/env.prod` — larger memory, production flags

You can edit:

* `JAVA_XMS`, `JAVA_XMX`
* `HYTALE_PORT` (remember to change firewall / port mapping if you change it)
* `HYTALE_EXTRA_ARGS` (additional server flags)

Example (dev offline auth for fully local testing):

```env
HYTALE_EXTRA_ARGS=--auth-mode offline
```

---

## Installing your plugin (.jar)

The server loads plugins/mods from `mods/`.

Copy a built plugin jar into the server mods folder:

```bash
./scripts/install-plugin.sh path/to/your-plugin.jar
```

Then restart the server (in dev: `Ctrl+C` and run `./scripts/up-dev.sh` again; in prod: restart the container).

---

## Logs, worlds, configuration

All persistent data lives under `runtime/Server/`, including:

* `runtime/Server/universe/` (world data)
* `runtime/Server/logs/`
* `runtime/Server/mods/`
* `runtime/Server/config.json`
* `runtime/Server/permissions.json`

Back up `runtime/Server/` (or at least `universe/` + configs) for production.

---

## Common issues

### “I can’t connect”

* Make sure you exposed **UDP** port `5520/udp` (not TCP).
* On Ubuntu, verify firewall:

  ```bash
  sudo ufw status
  ```
* Ensure client/server protocol versions match (use the same game release).

### “Server asks for auth every time”

* Make sure `runtime/` is mounted correctly and persists between restarts.
* Don’t delete the runtime folder between runs.

---

## Updating the server runtime

### Ubuntu

Re-run:

```bash
./scripts/bootstrap-linux.sh
./scripts/up-prod.sh
```

### macOS

If the Launcher updated the game, re-run:

```bash
./scripts/bootstrap-macos.sh
./scripts/up-dev.sh
```

---

## Security notes (prod)

* Bind to `0.0.0.0` only on servers you control.
* Only open the required UDP port.
* Consider running behind a VPN if you want a private environment.

---

## Next steps

* Add a `plugins/` folder with your plugin source (Gradle/Maven).
* Add a script to auto-build plugin and copy into `runtime/Server/mods/`.
* Add backups for `runtime/Server/universe/` on production.
