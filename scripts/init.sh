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

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Hytale Plugin Template Initializer  ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if already initialized
if [ -f "$PROJECT_ROOT/src/main/java/com/endoworlds/"*"/"*.java 2>/dev/null ]; then
    echo -e "${RED}Error: Project already initialized.${NC}"
    echo "If you want to reinitialize, delete the src/ directory first."
    exit 1
fi

# Prompt for plugin name
echo -e "${YELLOW}Enter your plugin name (PascalCase, e.g., MyAwesomePlugin):${NC}"
read -r PLUGIN_NAME

# Validate plugin name
if [[ ! "$PLUGIN_NAME" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
    echo -e "${RED}Error: Plugin name must be PascalCase (start with uppercase, alphanumeric only).${NC}"
    exit 1
fi

# Generate lowercase name for package
PLUGIN_NAME_LOWER=$(echo "$PLUGIN_NAME" | tr '[:upper:]' '[:lower:]')

# Fixed group
GROUP="com.endoworlds"
PACKAGE_PATH="com/endoworlds/$PLUGIN_NAME_LOWER"

echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Plugin Name: $PLUGIN_NAME"
echo "  Package: $GROUP.$PLUGIN_NAME_LOWER"
echo "  Main Class: $GROUP.$PLUGIN_NAME_LOWER.$PLUGIN_NAME"
echo ""

# Create directory structure
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p "$PROJECT_ROOT/src/main/java/$PACKAGE_PATH"
mkdir -p "$PROJECT_ROOT/src/main/resources"
mkdir -p "$PROJECT_ROOT/gradle/wrapper"

# Create main plugin class
echo -e "${GREEN}Creating plugin class...${NC}"
cat > "$PROJECT_ROOT/src/main/java/$PACKAGE_PATH/$PLUGIN_NAME.java" << EOF
package $GROUP.$PLUGIN_NAME_LOWER;

import com.hypixel.hytale.logger.HytaleLogger;
import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;

import javax.annotation.Nonnull;

public class $PLUGIN_NAME extends JavaPlugin {
    private static final HytaleLogger LOGGER = HytaleLogger.forEnclosingClass();

    public $PLUGIN_NAME(@Nonnull JavaPluginInit init) {
        super(init);
        LOGGER.atInfo().log("$PLUGIN_NAME loaded!");
    }

    @Override
    protected void setup() {
        LOGGER.atInfo().log("$PLUGIN_NAME is setting up...");
        // Add your plugin initialization logic here
    }
}
EOF

# Create manifest.json
echo -e "${GREEN}Creating manifest.json...${NC}"
cat > "$PROJECT_ROOT/src/main/resources/manifest.json" << EOF
{
  "Group": "$GROUP",
  "Name": "$PLUGIN_NAME",
  "Version": "0.1.0",
  "Description": "A Hytale server plugin",
  "Main": "$GROUP.$PLUGIN_NAME_LOWER.$PLUGIN_NAME",
  "Authors": [{ "Name": "Developer" }]
}
EOF

# Create build.gradle.kts
echo -e "${GREEN}Creating build.gradle.kts...${NC}"
cat > "$PROJECT_ROOT/build.gradle.kts" << EOF
plugins {
    java
}

group = "$GROUP"
version = "0.1.0"

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

repositories {
    mavenCentral()
}

dependencies {
    compileOnly(files("runtime/Server/HytaleServer.jar"))
}

tasks.jar {
    archiveBaseName.set("$PLUGIN_NAME_LOWER")
    from(sourceSets.main.get().output)

    // Copy to mods folder after build
    doLast {
        val modsDir = file("runtime/Server/mods")
        if (modsDir.exists()) {
            copy {
                from(archiveFile)
                into(modsDir)
            }
            println("Copied \${archiveFile.get().asFile.name} to mods/")
        }
    }
}

// Custom task to deploy plugin
tasks.register("deploy") {
    dependsOn("jar")
    group = "deployment"
    description = "Build and deploy plugin to server mods folder"
}
EOF

# Create settings.gradle.kts
echo -e "${GREEN}Creating settings.gradle.kts...${NC}"
cat > "$PROJECT_ROOT/settings.gradle.kts" << EOF
rootProject.name = "$PLUGIN_NAME_LOWER"
EOF

# Check if gradle wrapper exists in template
if [ ! -f "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.jar" ]; then
    echo -e "${GREEN}Downloading Gradle wrapper...${NC}"

    # Create gradle-wrapper.properties
    cat > "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties" << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

    # Download gradle wrapper jar
    WRAPPER_URL="https://github.com/gradle/gradle/raw/v8.12.0/gradle/wrapper/gradle-wrapper.jar"
    if command -v curl &> /dev/null; then
        curl -fsSL -o "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.jar" "$WRAPPER_URL" 2>/dev/null || true
    elif command -v wget &> /dev/null; then
        wget -q -O "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.jar" "$WRAPPER_URL" 2>/dev/null || true
    fi
fi

# Create gradlew script
echo -e "${GREEN}Creating gradlew scripts...${NC}"
cat > "$PROJECT_ROOT/gradlew" << 'GRADLEW'
#!/bin/sh

##############################################################################
#
#  Gradle start up script for POSIX generated by Gradle.
#
##############################################################################

# Attempt to set APP_HOME
APP_HOME=$( cd "${APP_HOME:-./}" && pwd -P ) || exit

# Add default JVM options here.
DEFAULT_JVM_OPTS='-Xmx64m -Xms64m'

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD=maximum

warn () {
    echo "$*"
} >&2

die () {
    echo
    echo "$*"
    echo
    exit 1
} >&2

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
nonstop=false
case "$( uname )" in
  CYGWIN* )         cygwin=true  ;;
  Darwin* )         darwin=true  ;;
  MSYS* | MINGW* )  msys=true    ;;
  NONSTOP* )        nonstop=true ;;
esac

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        JAVACMD=$JAVA_HOME/jre/sh/java
    else
        JAVACMD=$JAVA_HOME/bin/java
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME"
    fi
else
    JAVACMD=java
    if ! command -v java >/dev/null 2>&1
    then
        die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH."
    fi
fi

# Increase the maximum file descriptors if we can.
if ! "$cygwin" && ! "$darwin" && ! "$nonstop" ; then
    case $MAX_FD in
      max*)
        MAX_FD=$( ulimit -H -n ) ||
            warn "Could not query maximum file descriptor limit"
    esac
    case $MAX_FD in
      '' | soft) :;;
      *)
        ulimit -n "$MAX_FD" ||
            warn "Could not set maximum file descriptor limit to $MAX_FD"
    esac
fi

# Collect all arguments for the java command, stacking in reverse order:
#   * args from the command line
#   * the main class name
#   * -classpath
#   * -D...appname settings
#   * --module-path (only if needed)
#   * DEFAULT_JVM_OPTS, JAVA_OPTS, and GRADLE_OPTS environment variables.

# Stop when "xargs" is not available.
if ! command -v xargs >/dev/null 2>&1
then
    die "xargs is not available"
fi

# For Cygwin or MSYS, switch paths to Windows format before running java
if "$cygwin" || "$msys" ; then
    APP_HOME=$( cygpath --path --mixed "$APP_HOME" )
    CLASSPATH=$( cygpath --path --mixed "$CLASSPATH" )
    JAVACMD=$( cygpath --unix "$JAVACMD" )
fi

exec "$JAVACMD" $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS \
  "-Dorg.gradle.appname=$APP_BASE_NAME" \
  -classpath "$CLASSPATH" \
  org.gradle.wrapper.GradleWrapperMain \
  "$@"
GRADLEW

chmod +x "$PROJECT_ROOT/gradlew"

# Create gradlew.bat for Windows
cat > "$PROJECT_ROOT/gradlew.bat" << 'GRADLEWBAT'
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

@if "%DEBUG%"=="" @echo off
@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%"=="" set DIRNAME=.
@rem This is normally unused
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here.
set DEFAULT_JVM_OPTS="-Xmx64m" "-Xms64m"

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if %ERRORLEVEL% equ 0 goto execute

echo. 1>&2
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH. 1>&2
echo. 1>&2
goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto execute

echo. 1>&2
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME% 1>&2
echo. 1>&2
goto fail

:execute
@rem Setup the command line
set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

@rem Execute Gradle
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

:end
@rem End local scope for the variables with windows NT shell
if %ERRORLEVEL% equ 0 goto mainEnd

:fail
rem Set variable GRADLE_EXIT_CONSOLE if you need the _script_ return code instead of
rem having the _cmd.exe /c_ precedence.
set EXIT_CODE=%ERRORLEVEL%
if %EXIT_CODE% equ 0 set EXIT_CODE=1
if not ""=="%GRADLE_EXIT_CONSOLE%" exit %EXIT_CODE%
exit /b %EXIT_CODE%

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
GRADLEWBAT

# Create mods directory if needed
mkdir -p "$PROJECT_ROOT/runtime/Server/mods" 2>/dev/null || true

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Initialization complete!            ${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "Your plugin structure:"
echo -e "  src/main/java/$PACKAGE_PATH/$PLUGIN_NAME.java"
echo -e "  src/main/resources/manifest.json"
echo -e "  build.gradle.kts"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Edit your plugin code in src/main/java/"
echo "  2. Build: ./gradlew build"
echo "  3. Deploy: ./scripts/deploy.sh"
echo ""
echo -e "${BLUE}Quick commands:${NC}"
echo "  ./gradlew build      - Build plugin JAR"
echo "  ./scripts/deploy.sh  - Build + copy to mods + reload server"
echo ""
