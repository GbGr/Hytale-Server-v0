# Hytale Plugin Development Template

Template repository for **Hytale plugin development** with Docker-based server. Supports local development on **macOS/Windows** and production deployment on **Ubuntu**.

## Features

- One-command project initialization
- Hot-reload plugins without server restart
- Watch mode for auto-deploy on file save
- Docker Compose for dev/prod environments
- Cross-platform (macOS, Windows, Ubuntu)

---

## Quick Start

### 1. Clone & Initialize

```bash
git clone <this-repo> my-plugin
cd my-plugin

# macOS/Linux
./scripts/init.sh

# Windows (PowerShell)
.\scripts\init.ps1
```

Enter your plugin name (e.g., `MyAwesomePlugin`) — creates full project structure.

### 2. Setup Runtime (first time)

Copy Hytale server files to `runtime/`:

**macOS:**
```bash
SRC="$HOME/Library/Application Support/Hytale/install/release/package/game/latest"
cp -R "$SRC/Server" runtime/Server
cp "$SRC/Assets.zip" runtime/Assets.zip
```

**Windows:**
```powershell
$src = "$env:APPDATA\Hytale\install\release\package\game\latest"
Copy-Item -Recurse "$src\Server" runtime\Server
Copy-Item "$src\Assets.zip" runtime\Assets.zip
```

### 3. Create machine-id (for auth persistence)

**macOS/Linux:**
```bash
uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]' > runtime/machine-id
```

**Windows:**
```powershell
([guid]::NewGuid().ToString("N")).ToLower() | Out-File -Encoding ascii runtime\machine-id
```

### 4. Start Server

```bash
docker compose -f infra/compose.yml --env-file infra/env.dev --profile dev up
```

### 5. Authenticate (first run only)

```bash
docker compose -f infra/compose.yml --profile dev attach hytale-dev
```

In console:
```
/auth persistence Encrypted
/auth login device
```

---

## Plugin Development

### Build & Deploy (one command)

```bash
# macOS/Linux
./gradlew deploy

# Windows
.\gradlew.bat deploy
```

Builds plugin → copies to mods/ → auto-reloads on running server.

### Watch Mode (auto-deploy on save)

```bash
# macOS/Linux
./scripts/watch.sh

# Windows
.\scripts\watch.ps1
```

Edit code → save → plugin auto-deploys. Press `Ctrl+C` to stop.

For better watch performance on macOS:
```bash
brew install fswatch
```

### Manual Reload

In server console:
```
/plugin reload <Group:Name>
```

Example: `/plugin reload com.endoworlds:MyAwesomePlugin`

---

## Project Structure

```
scripts/                  # Automation
  init.sh / init.ps1      # Initialize new plugin project
  deploy.sh / deploy.ps1  # Build + deploy + reload
  watch.sh / watch.ps1    # Watch mode (auto-deploy)

infra/                    # Docker configuration
  compose.yml             # Dev + prod profiles
  env.dev / env.prod      # Environment configs

# GENERATED (after init, not in git):
src/main/java/            # Plugin source code
src/main/resources/
  manifest.json           # Plugin manifest
build.gradle.kts          # Gradle build config

runtime/                  # NOT IN GIT - server files
  Assets.zip              # Game assets (~3.3GB)
  Server/
    HytaleServer.jar      # Server binary
    mods/                 # Plugin JARs here
    universe/             # World data
  machine-id              # Auth persistence
```

---

## Server Commands

### Docker Commands

```bash
# Start dev server
docker compose -f infra/compose.yml --env-file infra/env.dev --profile dev up

# Attach to console
docker compose -f infra/compose.yml --profile dev attach hytale-dev

# Detach: Ctrl+P, Ctrl+Q

# Restart
docker compose -f infra/compose.yml --profile dev restart

# Stop
docker compose -f infra/compose.yml --profile dev down
```

### Plugin Commands (in server console)

```
/plugin list                    # List loaded plugins
/plugin reload <Group:Name>     # Hot-reload plugin
/plugin load <Group:Name>       # Load plugin
/plugin unload <Group:Name>     # Unload plugin
```

---

## Production Deployment (Ubuntu)

### 1. Setup

```bash
# Copy runtime files (Server/, Assets.zip, machine-id)
# Open UDP port
sudo ufw allow 5520/udp
```

### 2. Run

```bash
docker compose -f infra/compose.yml --env-file infra/env.prod --profile prod up -d
```

### 3. Manage

```bash
# View logs
docker compose -f infra/compose.yml --profile prod logs -f

# Attach console
docker compose -f infra/compose.yml --profile prod attach hytale-prod
```

---

## Technical Details

- **Java:** 25 (server) / 21+ (build)
- **Protocol:** QUIC over UDP (port 5520)
- **Group:** `com.endoworlds` (configured in init)

### macOS Docker Fix

If server works natively but not in Docker, set Docker Desktop to use `vpnkit`:

1. Quit Docker Desktop
2. Edit `~/Library/Group Containers/group.com.docker/settings.json`
3. Set: `{ "networkType": "vpnkit" }`
4. Restart Docker Desktop

---

## Troubleshooting

### Client can't connect
- Check UDP port mapping: `docker compose ... ps` should show `5520->5520/udp`
- macOS: ensure `networkType: vpnkit` in Docker settings
- Connect to `127.0.0.1:5520` (not `localhost`)

### Auth resets after restart
- Ensure `runtime/machine-id` exists
- Check compose mounts it to `/etc/machine-id:ro`
- Verify `runtime/Server/auth.enc` exists

### Plugin not loading
- Check `src/main/resources/manifest.json` format
- Verify JAR is in `runtime/Server/mods/`
- Check server logs for errors

---

## License

Unlicensed