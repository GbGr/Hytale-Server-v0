# Hytale Server (Dev on localhost + Prod on Ubuntu) — Docker Compose Monorepo

This repository is built to make Hytale Server development and deployment **repeatable**:

- **Local dev** on **macOS** or **Windows** using **Docker**
- **Production** deployment on **Ubuntu** using the same Docker Compose setup
- Your **code + infra** lives in Git
- Hytale **runtime binaries/assets/world data** live in `runtime/` and are **not committed**

---

## Key points (read once)

- Hytale Server uses **QUIC over UDP** (default port **5520/udp**) — *not TCP*
- First run requires authentication via:
  - `/auth persistence Encrypted`
  - `/auth login device`
- In Docker, auth persistence requires a stable `machine-id` mounted into the container (explained below)

---

## Repository layout

```text
my-hytale/
  README.md
  .gitignore

  runtime/                 # NOT COMMITTED
    Assets.zip
    Server/                # config.json, auth.enc, mods/, universe/, logs/, ...
    machine-id             # created once (for auth persistence in Docker)

  infra/
    compose.yml            # dev + prod profiles
    env.dev
    env.prod
````

---

## Prerequisites

### macOS (local dev)

* Docker Desktop installed and running
* Hytale Launcher installed and game downloaded

### Windows 10/11 (local dev)

* Docker Desktop installed and running (WSL2 backend recommended)
* Hytale Launcher installed and game downloaded
* PowerShell (built-in)

### Ubuntu (production)

* Docker Engine + Docker Compose plugin
* Open UDP port 5520 (or the port you configured)

---

# Local development (Docker)

## Step 1 — Prepare runtime files (Server + Assets.zip)

The server requires **both**:

* `Server/` directory
* `Assets.zip`

You copy them from the Hytale Launcher install directory into `./runtime/`.

### macOS (Terminal)

Hytale Launcher install location is typically one of these:

* `~/Application Support/Hytale/install/release/package/game/latest`
* `~/Library/Application Support/Hytale/install/release/package/game/latest`

Run:

```bash
mkdir -p ./runtime

SRC="$HOME/Application Support/Hytale/install/release/package/game/latest"
[ -d "$SRC" ] || SRC="$HOME/Library/Application Support/Hytale/install/release/package/game/latest"

rm -rf ./runtime/Server
cp -R "$SRC/Server" ./runtime/Server
cp "$SRC/Assets.zip" ./runtime/Assets.zip
```

### Windows (PowerShell)

Launcher install location:

* `%APPDATA%\Hytale\install\release\package\game\latest`

Run from repo root:

```powershell
$src = Join-Path $env:APPDATA "Hytale\install\release\package\game\latest"
New-Item -ItemType Directory -Force -Path ".\runtime" | Out-Null

Remove-Item -Recurse -Force ".\runtime\Server" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force (Join-Path $src "Server") ".\runtime\Server"
Copy-Item -Force (Join-Path $src "Assets.zip") ".\runtime\Assets.zip"
```

### Verify runtime exists (macOS/Windows)

You should have:

```text
runtime/
  Assets.zip
  Server/
    HytaleServer.jar
    ...
```

macOS check:

```bash
ls -lah runtime/Server/HytaleServer.jar runtime/Assets.zip
```

Windows check:

```powershell
Get-Item .\runtime\Server\HytaleServer.jar, .\runtime\Assets.zip
```

---

## Step 2 — Fix Docker auth persistence (required)

If you authenticate and then see auth reset after container restart, or you see warnings like:

```text
Cannot save credentials - no encryption key available
```

you need a stable machine-id mounted into the container.

### 2.1 Create `runtime/machine-id` (one-time)

#### macOS (Terminal)

```bash
mkdir -p runtime
uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]' > runtime/machine-id
echo >> runtime/machine-id
```

#### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force runtime | Out-Null
([guid]::NewGuid().ToString("N")).ToLower() | Out-File -Encoding ascii runtime\machine-id
```

> Do NOT change `runtime/machine-id` later. If you do, you’ll need to re-authenticate.

### 2.2 Ensure `machine-id` is mounted in `infra/compose.yml`

Your `hytale-dev` service must include:

```yaml
volumes:
  - ../runtime:/srv/hytale
  - ../runtime/machine-id:/etc/machine-id:ro
```

---

## Step 3 — macOS-only: Docker Desktop UDP/QUIC networking fix

If the server works **natively** but **not** through Docker on macOS, switch Docker Desktop networking to `vpnkit`.

1. Quit Docker Desktop
2. Edit this file:
   `~/Library/Group Containers/group.com.docker/settings.json`
3. Set:

```json
{ "networkType": "vpnkit" }
```

4. Start Docker Desktop again

---

## Step 4 — Run the dev server (Docker)

From repo root:

```bash
docker compose -f infra/compose.yml --env-file infra/env.dev --profile dev up
```

You should see a port mapping like:

```text
0.0.0.0:5520->5520/udp
```

### Check container status

```bash
docker compose -f infra/compose.yml --profile dev ps
```

---

## Step 5 — Authenticate (first run only)

Attach to the server console:

```bash
docker compose -f infra/compose.yml --profile dev attach hytale-dev
```

Then run in the server console:

```text
/auth persistence Encrypted
/auth login device
```

Follow the URL + code shown to complete authentication.

### Verify auth file exists

After successful auth, you should see:

```text
runtime/Server/auth.enc
```

macOS:

```bash
ls -lah runtime/Server/auth.enc
```

Windows:

```powershell
Get-Item .\runtime\Server\auth.enc
```

### Verify auth survives restarts

Restart:

```bash
docker compose -f infra/compose.yml --profile dev restart
```

Re-attach and check:

```text
/auth status
```

---

## Connecting to your local server

From the same machine:

* Address: `127.0.0.1`
* Port: `5520`
* Or: `127.0.0.1:5520`

---

# Local dev on Windows: Firewall note (UDP)

If you connect from another device on the LAN to your Windows host, allow inbound UDP:

```powershell
New-NetFirewallRule -DisplayName "Hytale Server (UDP 5520)" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow
```

---

# Production on Ubuntu (Docker)

## 1) Prepare runtime

On Ubuntu you typically download runtime via the official downloader (or copy from an existing install).
Once you have runtime, the folder should look like:

```text
runtime/
  Assets.zip
  Server/
  machine-id
```

You can reuse the same `runtime/machine-id` approach (recommended for consistency).

## 2) Open UDP port

```bash
sudo ufw allow 5520/udp
```

## 3) Run prod profile

```bash
docker compose -f infra/compose.yml --env-file infra/env.prod --profile prod up -d
```

Attach console if you need to run admin/auth commands:

```bash
docker compose -f infra/compose.yml --profile prod attach hytale-prod
```

---

# Plugins / Mods workflow

Hytale loads mods/plugins from:

```text
runtime/Server/mods/
```

Typical loop:

1. Build your plugin jar
2. Copy it into `runtime/Server/mods/`
3. Restart server or use an in-server plugin reload command (if available)

Because `runtime/` is mounted into the container, changes to `mods/` persist and are visible to the server.

---

# Troubleshooting

## Client cannot connect (Docker only)

* Confirm UDP mapping exists:

  ```bash
  docker compose -f infra/compose.yml --profile dev ps
  ```

  Must show `5520->5520/udp`
* macOS only: ensure Docker Desktop `networkType` is `vpnkit`
* Ensure you are connecting to `127.0.0.1:5520` (IPv4), not just `localhost` (can resolve to IPv6)

## Auth resets after container restart

* Ensure `runtime/machine-id` exists
* Ensure compose mounts it to `/etc/machine-id:ro`
* Ensure you ran:

  ```text
  /auth persistence Encrypted
  ```
* Ensure `runtime/Server/auth.enc` exists and is not deleted

## “Cannot save credentials - no encryption key available”

* This means `machine-id` is missing/unstable inside the container
* Fix Step 2 above (create + mount `runtime/machine-id`)

---

# Notes on what is persisted

Everything under `runtime/Server/` persists across restarts:

* `universe/` (world + player data)
* `mods/` (plugins/mods)
* `logs/`
* `config.json`, `permissions.json`
* `auth.enc` (when Encrypted persistence is enabled)

Back up `runtime/Server/universe/` for production.