````md
# Hytale Server Monorepo (Dev on localhost + Prod on Ubuntu) — Docker Compose

This repo is designed so you can:
- run a **local dev server** on **macOS / Windows / Linux** with the same commands
- deploy the same setup to an **Ubuntu** host for production
- keep **your code + infra** in git, while keeping **Hytale runtime binaries/assets/world data** out of git

> Networking note: Hytale Server uses **QUIC over UDP** (default `5520/udp`), not TCP.

---

## Repository layout

```text
my-hytale/
  README.md
  runtime/                 # NOT COMMITTED: Server/, Assets.zip, worlds, logs, downloader creds
    .keep
  infra/
    compose.yml            # dev + prod profiles
    env.dev
    env.prod
  scripts/                 # optional convenience scripts (later)
  plugins/                 # (optional) your plugin source code
````

### What is NOT committed (by design)

`runtime/` is your local / server state:

* `runtime/Server/` (includes `HytaleServer.jar`, configs, `mods/`, `universe/`, logs, etc.)
* `runtime/Assets.zip`
* downloader credentials file (if you use the downloader)

Add these to `.gitignore`.

---

## Prerequisites

### macOS / Windows (local dev)

* Docker Desktop installed and running
* If you use bind mounts on Windows/macOS, ensure Docker Desktop has permission to share the drive/folder containing this repo.

### Ubuntu (prod)

* Docker Engine + Docker Compose plugin
* Open UDP port `5520`:

  ```bash
  sudo ufw allow 5520/udp
  ```

---

## 1) Prepare `runtime/` (get `Server/` and `Assets.zip`)

The server needs both:

* `Server/` folder
* `Assets.zip`

You have two ways to get them.

### Option A — Copy from your installed Hytale Launcher (macOS + Windows + Linux)

Find the launcher install directory, then copy `Server/` and `Assets.zip` into `./runtime/`.

#### Windows (PowerShell)

```powershell
$src = Join-Path $env:APPDATA "Hytale\install\release\package\game\latest"
New-Item -ItemType Directory -Force -Path ".\runtime" | Out-Null

Remove-Item -Recurse -Force ".\runtime\Server" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force (Join-Path $src "Server") ".\runtime\Server"
Copy-Item -Force (Join-Path $src "Assets.zip") ".\runtime\Assets.zip"
```

#### macOS (bash)

```bash
SRC="$HOME/Application Support/Hytale/install/release/package/game/latest"

mkdir -p ./runtime
rm -rf ./runtime/Server
cp -R "$SRC/Server" ./runtime/Server
cp "$SRC/Assets.zip" ./runtime/Assets.zip
```

#### Linux (bash)

```bash
SRC="${XDG_DATA_HOME:-$HOME/.local/share}/Hytale/install/release/package/game/latest"

mkdir -p ./runtime
rm -rf ./runtime/Server
cp -R "$SRC/Server" ./runtime/Server
cp "$SRC/Assets.zip" ./runtime/Assets.zip
```

### Option B — Use the official Hytale Downloader (Windows + Linux)

This is recommended for servers because it makes updates easier.

> The downloader is not available for macOS in the official distribution, so macOS typically uses Option A.

#### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force -Path ".\runtime" | Out-Null
New-Item -ItemType Directory -Force -Path ".\.tools" | Out-Null

Invoke-WebRequest "https://downloader.hytale.com/hytale-downloader.zip" -OutFile ".\.tools\hytale-downloader.zip"
Expand-Archive ".\.tools\hytale-downloader.zip" -DestinationPath ".\.tools\hytale-downloader" -Force

# Run the downloader (first run will prompt you to authenticate in a browser)
& ".\.tools\hytale-downloader\hytale-downloader-windows-amd64.exe" -download-path ".\runtime\game.zip"

# Extract the package and copy runtime files
Expand-Archive ".\runtime\game.zip" -DestinationPath ".\runtime\game" -Force
Remove-Item -Recurse -Force ".\runtime\Server" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force ".\runtime\game\Server" ".\runtime\Server"
Copy-Item -Force ".\runtime\game\Assets.zip" ".\runtime\Assets.zip"
```

#### Linux (bash)

```bash
mkdir -p ./.tools ./runtime

curl -L "https://downloader.hytale.com/hytale-downloader.zip" -o ./.tools/hytale-downloader.zip
unzip -o ./.tools/hytale-downloader.zip -d ./.tools/hytale-downloader
chmod +x ./.tools/hytale-downloader/hytale-downloader-linux-amd64

./.tools/hytale-downloader/hytale-downloader-linux-amd64 -download-path ./runtime/game.zip

unzip -o ./runtime/game.zip -d ./runtime/game
rm -rf ./runtime/Server
cp -R ./runtime/game/Server ./runtime/Server
cp ./runtime/game/Assets.zip ./runtime/Assets.zip
```

---

## 2) Run the server (Docker Compose)

### Dev (localhost, interactive console)

Works the same on macOS / Windows / Linux:

```bash
docker compose -f infra/compose.yml --env-file infra/env.dev --profile dev up
```

On the first run, authenticate the server in the console:

```text
/auth login device
```

Stop with `Ctrl+C`.

### Prod (Ubuntu, background)

```bash
docker compose -f infra/compose.yml --env-file infra/env.prod --profile prod up -d
```

Attach to the console (to run auth or admin commands):

```bash
docker compose -f infra/compose.yml --profile prod attach hytale-prod
```

Stop:

```bash
docker compose -f infra/compose.yml --profile prod down
```

---

## 3) Firewall / Port forwarding (UDP only)

### Ubuntu (ufw)

```bash
sudo ufw allow 5520/udp
```

### Windows Firewall (PowerShell)

```powershell
New-NetFirewallRule -DisplayName "Hytale Server" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow
```

If you are hosting from home behind a router, forward **UDP 5520**.

---

## 4) Plugins / Mods

Place plugin/mod files into:

```text
runtime/Server/mods/
```

Typical formats:

* `.jar` (server plugins)
* `.zip` (mods)

Restart the server after adding/updating plugins unless you have a proven hot-reload workflow.

---

## 5) Persistent data (worlds, logs, config)

Everything persists under:

```text
runtime/Server/
  universe/        # world / player data
  mods/            # plugins/mods
  logs/            # logs
  config.json      # server config
  permissions.json # permissions
```

Back up `runtime/Server/universe/` and your configs for production.

---

## 6) Updating the server runtime

### Windows / Linux (Downloader)

Re-run the downloader steps, then restart the container.

### macOS (Launcher copy)

Re-copy `Server/` and `Assets.zip` from the launcher install directory, then restart the container.

---

## Troubleshooting

### “Client can’t connect”

* Verify you exposed **UDP** `5520/udp` (not TCP).
* Check firewall rules and router forwarding.
* Ensure your client and server are on compatible versions.

### “Changes don’t persist”

* Confirm `runtime/` is mounted correctly and not being overwritten.
* Don’t delete `runtime/` between runs.
