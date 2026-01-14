#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Hytale Plugin Deploy                ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if project is initialized
if [ ! -f "$PROJECT_ROOT/build.gradle.kts" ]; then
    echo -e "${RED}Error: Project not initialized.${NC}"
    echo "Run ./scripts/init.sh first."
    exit 1
fi

# Find compatible Java (Gradle 8.14 has issues with Java 25)
find_compatible_java() {
    # On macOS, use java_home to find Java 24 or 21
    if [ "$(uname)" = "Darwin" ] && command -v /usr/libexec/java_home &> /dev/null; then
        for version in 24 23 22 21; do
            local java_path=$(/usr/libexec/java_home -v $version 2>/dev/null)
            if [ -n "$java_path" ] && [ -d "$java_path" ]; then
                echo "$java_path"
                return
            fi
        done
    fi
    # Fallback: check common paths
    for version in 24 23 22 21; do
        for base in "/Library/Java/JavaVirtualMachines" "$HOME/Library/Java/JavaVirtualMachines" "/usr/lib/jvm"; do
            for dir in "$base"/temurin-$version* "$base"/openjdk-$version* "$base"/java-$version*; do
                if [ -d "$dir/Contents/Home" ]; then
                    echo "$dir/Contents/Home"
                    return
                elif [ -d "$dir" ] && [ -x "$dir/bin/java" ]; then
                    echo "$dir"
                    return
                fi
            done
        done
    done
}

# Check current Java version
JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -ge 25 ] 2>/dev/null; then
    COMPATIBLE_JAVA=$(find_compatible_java)
    if [ -n "$COMPATIBLE_JAVA" ]; then
        echo -e "${YELLOW}Note: Using Java 24 for Gradle (Java 25 has compatibility issues)${NC}"
        export JAVA_HOME="$COMPATIBLE_JAVA"
    fi
fi

# Step 1: Build the plugin
echo -e "${GREEN}[1/3] Building plugin...${NC}"
./gradlew build --quiet

# Find the built JAR
JAR_FILE=$(find "$PROJECT_ROOT/build/libs" -name "*.jar" -type f | head -1)

if [ -z "$JAR_FILE" ]; then
    echo -e "${RED}Error: No JAR file found in build/libs/${NC}"
    exit 1
fi

JAR_NAME=$(basename "$JAR_FILE")
echo -e "      Built: ${YELLOW}$JAR_NAME${NC}"

# Step 2: Copy to mods folder
echo -e "${GREEN}[2/3] Copying to mods folder...${NC}"
MODS_DIR="$PROJECT_ROOT/runtime/Server/mods"

if [ ! -d "$MODS_DIR" ]; then
    mkdir -p "$MODS_DIR"
fi

# Remove old versions of this plugin
PLUGIN_BASE_NAME=$(echo "$JAR_NAME" | sed 's/-[0-9].*\.jar$//')
rm -f "$MODS_DIR/$PLUGIN_BASE_NAME"*.jar 2>/dev/null || true

cp "$JAR_FILE" "$MODS_DIR/"
echo -e "      Copied to: ${YELLOW}runtime/Server/mods/$JAR_NAME${NC}"

# Step 3: Reload plugin on server
echo -e "${GREEN}[3/3] Checking server status...${NC}"

# Read plugin identifier from manifest.json
MANIFEST_FILE="$PROJECT_ROOT/src/main/resources/manifest.json"
if [ -f "$MANIFEST_FILE" ]; then
    # Use head -1 to get only the first match (top-level Name, not Authors.Name)
    PLUGIN_GROUP=$(grep -o '"Group"[[:space:]]*:[[:space:]]*"[^"]*"' "$MANIFEST_FILE" | head -1 | cut -d'"' -f4)
    PLUGIN_NAME=$(grep -o '"Name"[[:space:]]*:[[:space:]]*"[^"]*"' "$MANIFEST_FILE" | head -1 | cut -d'"' -f4)
    PLUGIN_ID="${PLUGIN_GROUP}:${PLUGIN_NAME}"
else
    PLUGIN_ID="<Group:Name>"
fi

# Try to find the running container
CONTAINER_NAME=""
PROFILE=""
if docker compose -f "$PROJECT_ROOT/infra/compose.yml" --profile dev ps --quiet hytale-dev 2>/dev/null | grep -q .; then
    CONTAINER_NAME="hytale-dev"
    PROFILE="dev"
elif docker compose -f "$PROJECT_ROOT/infra/compose.yml" --profile prod ps --quiet hytale-prod 2>/dev/null | grep -q .; then
    CONTAINER_NAME="hytale-prod"
    PROFILE="prod"
fi

if [ -n "$CONTAINER_NAME" ]; then
    echo -e "      Found running server: ${YELLOW}$CONTAINER_NAME${NC}"
    echo ""

    # Try to send reload command using expect
    RELOAD_CMD="/plugin reload $PLUGIN_ID"

    if command -v expect &> /dev/null; then
        echo -e "${GREEN}Reloading plugin...${NC}"

        # Use expect to send command and detach (Ctrl+P Ctrl+Q)
        expect -c "
            set timeout 5
            log_user 0
            spawn docker compose -f $PROJECT_ROOT/infra/compose.yml --profile $PROFILE attach $CONTAINER_NAME
            sleep 0.5
            send \"$RELOAD_CMD\r\"
            sleep 0.5
            send \"\x10\x11\"
            expect eof
        " 2>/dev/null

        echo -e "      Sent: ${GREEN}$RELOAD_CMD${NC}"
        echo ""
        echo -e "${YELLOW}Plugin reload initiated. Check server logs for status.${NC}"
    else
        # Fallback to manual instructions
        echo -e "${BLUE}Run in server console:${NC}"
        echo -e "  ${GREEN}$RELOAD_CMD${NC}"
        echo ""
        echo -e "${BLUE}Attach:${NC} docker compose -f infra/compose.yml --profile $PROFILE attach $CONTAINER_NAME"
    fi
else
    echo -e "      ${YELLOW}Server not running.${NC}"
    echo ""
    echo -e "${BLUE}Start server:${NC}"
    echo "  docker compose -f infra/compose.yml --env-file infra/env.dev --profile dev up"
    echo ""
    echo -e "${BLUE}Then reload plugin with:${NC}"
    echo -e "  ${GREEN}/plugin reload $PLUGIN_ID${NC}"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Deploy complete!                    ${NC}"
echo -e "${GREEN}======================================${NC}"
