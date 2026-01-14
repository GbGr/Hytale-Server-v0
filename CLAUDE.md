# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Template repository for Hytale plugin development. Supports local development on macOS/Windows and production deployment on Ubuntu. Uses QUIC over UDP (port 5520), not TCP.

## Quick Start

### 1. Initialize Plugin (first time only)

```bash
# macOS/Linux
./scripts/init.sh

# Windows (PowerShell)
.\scripts\init.ps1
```

This will prompt for plugin name and create the project structure with Group `com.endoworlds`.

### 2. Build & Deploy (one command)

```bash
# macOS/Linux
./gradlew deploy        # or ./scripts/deploy.sh

# Windows
.\gradlew.bat deploy    # or .\scripts\deploy.ps1
```

Builds plugin → copies to mods/ → auto-reloads on server.

### 3. Watch Mode (auto-deploy on save)

```bash
# macOS/Linux
./scripts/watch.sh

# Windows
.\scripts\watch.ps1
```

Watches `src/` for changes and auto-deploys. Press `Ctrl+C` to stop.

### 4. Manual Commands

```bash
./gradlew build         # Just build
./gradlew deploy        # Build + deploy + reload
./scripts/deploy.sh     # Same as above with colored output
```

## Commands

### Development Server

```bash
# Start dev server (interactive)
docker compose -f infra/compose.yml --env-file infra/env.dev --profile dev up

# Attach to server console (for running /auth commands)
docker compose -f infra/compose.yml --profile dev attach hytale-dev

# Restart dev server
docker compose -f infra/compose.yml --profile dev restart

# Check container status
docker compose -f infra/compose.yml --profile dev ps
```

### Production Server

```bash
# Start production (detached)
docker compose -f infra/compose.yml --env-file infra/env.prod --profile prod up -d

# Attach to console
docker compose -f infra/compose.yml --profile prod attach hytale-prod
```

## Architecture

```
scripts/                  # Automation scripts
  init.sh / init.ps1      # Project initialization (creates plugin structure)
  deploy.sh / deploy.ps1  # Build + deploy + reload plugin
  watch.sh / watch.ps1    # Watch mode (auto-deploy on file changes)

infra/                    # Docker Compose configuration
  compose.yml             # Main compose with dev/prod profiles
  env.dev                 # Dev environment (4G max heap)
  env.prod                # Prod environment (8G max heap)

docker/server/            # Custom Dockerfile (if building image)
  Dockerfile              # Eclipse Temurin 25 JRE base
  entrypoint.sh

# GENERATED AFTER INIT (not in git):
src/                      # Plugin source code
  main/java/              # Java source files
  main/resources/
    manifest.json         # Plugin manifest
build.gradle.kts          # Gradle build config
settings.gradle.kts       # Gradle settings

runtime/                  # NOT COMMITTED - game binaries and data
  Assets.zip              # Game assets (~3.3GB)
  Server/
    HytaleServer.jar      # Server binary
    config.json           # Server configuration
    mods/                 # Plugin JARs loaded from here
    universe/             # World and player data
  machine-id              # Stable ID for Docker auth persistence
```

## Plugin Development

Plugins extend `com.hypixel.hytale.server.core.plugin.JavaPlugin`:

```java
public class MyPlugin extends JavaPlugin {
    private static final HytaleLogger LOGGER = HytaleLogger.forEnclosingClass();

    public MyPlugin(@Nonnull JavaPluginInit init) {
        super(init);
    }

    @Override
    protected void setup() {
        // Plugin initialization
    }
}
```

**Required:** `src/main/resources/manifest.json` with Group, Name, Version, Main class, Description, Authors.

**Dependency:** Uses `compileOnly(files("runtime/Server/HytaleServer.jar"))` in Gradle.

## Plugin Server Commands

```bash
/plugin list                    # List all loaded plugins
/plugin load <Group:Name>       # Load a plugin
/plugin unload <Group:Name>     # Unload a plugin
/plugin reload <Group:Name>     # Reload plugin (unload + load)
```

## Key Technical Details

- **Java Version:** 25 (Eclipse Temurin JRE) - server runs on Java 25, but Gradle build uses Java 24
- **Protocol:** QUIC over UDP, not TCP
- **First Run Auth:** Run `/auth persistence Encrypted` then `/auth login device` in server console
- **macOS Docker:** Requires `vpnkit` network type in Docker Desktop settings for UDP/QUIC to work
- **Auth Persistence:** Requires stable `runtime/machine-id` mounted to `/etc/machine-id:ro` in container
