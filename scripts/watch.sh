#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Hytale Plugin Watch Mode            ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${YELLOW}Watching for changes in src/...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Find compatible Java
JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -ge 25 ] 2>/dev/null; then
    if [ "$(uname)" = "Darwin" ]; then
        for v in 24 23 22 21; do
            JP=$(/usr/libexec/java_home -v $v 2>/dev/null)
            if [ -n "$JP" ]; then
                export JAVA_HOME="$JP"
                break
            fi
        done
    fi
fi

# Function to run deploy
do_deploy() {
    echo ""
    echo -e "${GREEN}[$(date +%H:%M:%S)] Change detected, deploying...${NC}"
    ./gradlew deploy --quiet 2>&1 | grep -v "^WARNING:"
    echo -e "${GREEN}[$(date +%H:%M:%S)] Done${NC}"
}

# Check for fswatch (macOS) or inotifywait (Linux)
if command -v fswatch &> /dev/null; then
    # macOS with fswatch
    fswatch -o src/ | while read; do
        do_deploy
    done
elif command -v inotifywait &> /dev/null; then
    # Linux with inotify-tools
    while inotifywait -r -e modify,create,delete src/ 2>/dev/null; do
        do_deploy
    done
else
    # Fallback: polling
    echo -e "${YELLOW}Note: Install 'fswatch' (macOS) or 'inotify-tools' (Linux) for better performance${NC}"
    echo -e "${YELLOW}Using polling fallback (checks every 2 seconds)${NC}"
    echo ""

    LAST_HASH=""
    while true; do
        # Get hash of all source files
        CURRENT_HASH=$(find src -type f -name "*.java" -o -name "*.json" 2>/dev/null | xargs cat 2>/dev/null | md5 2>/dev/null || md5sum 2>/dev/null | cut -d' ' -f1)

        if [ -n "$CURRENT_HASH" ] && [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
            if [ -n "$LAST_HASH" ]; then
                do_deploy
            fi
            LAST_HASH="$CURRENT_HASH"
        fi
        sleep 2
    done
fi
