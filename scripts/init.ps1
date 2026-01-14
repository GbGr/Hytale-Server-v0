# Hytale Plugin Template Initializer for Windows
# Usage: .\scripts\init.ps1

$ErrorActionPreference = "Stop"

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "======================================" -ForegroundColor Blue
Write-Host "  Hytale Plugin Template Initializer  " -ForegroundColor Blue
Write-Host "======================================" -ForegroundColor Blue
Write-Host ""

# Check if already initialized
$ExistingJava = Get-ChildItem -Path "$ProjectRoot\src\main\java\com\endoworlds" -Filter "*.java" -Recurse -ErrorAction SilentlyContinue
if ($ExistingJava) {
    Write-Host "Error: Project already initialized." -ForegroundColor Red
    Write-Host "If you want to reinitialize, delete the src\ directory first."
    exit 1
}

# Prompt for plugin name
Write-Host "Enter your plugin name (PascalCase, e.g., MyAwesomePlugin):" -ForegroundColor Yellow
$PluginName = Read-Host

# Validate plugin name
if ($PluginName -notmatch "^[A-Z][a-zA-Z0-9]*$") {
    Write-Host "Error: Plugin name must be PascalCase (start with uppercase, alphanumeric only)." -ForegroundColor Red
    exit 1
}

# Generate lowercase name for package
$PluginNameLower = $PluginName.ToLower()

# Fixed group
$Group = "com.endoworlds"
$PackagePath = "com\endoworlds\$PluginNameLower"

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Blue
Write-Host "  Plugin Name: $PluginName"
Write-Host "  Package: $Group.$PluginNameLower"
Write-Host "  Main Class: $Group.$PluginNameLower.$PluginName"
Write-Host ""

# Create directory structure
Write-Host "Creating directory structure..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "$ProjectRoot\src\main\java\$PackagePath" | Out-Null
New-Item -ItemType Directory -Force -Path "$ProjectRoot\src\main\resources" | Out-Null
New-Item -ItemType Directory -Force -Path "$ProjectRoot\gradle\wrapper" | Out-Null

# Create main plugin class
Write-Host "Creating plugin class..." -ForegroundColor Green
$PluginClass = @"
package $Group.$PluginNameLower;

import com.hypixel.hytale.logger.HytaleLogger;
import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;

import javax.annotation.Nonnull;

public class $PluginName extends JavaPlugin {
    private static final HytaleLogger LOGGER = HytaleLogger.forEnclosingClass();

    public $PluginName(@Nonnull JavaPluginInit init) {
        super(init);
        LOGGER.atInfo().log("$PluginName loaded!");
    }

    @Override
    protected void setup() {
        LOGGER.atInfo().log("$PluginName is setting up...");
        // Add your plugin initialization logic here
    }
}
"@
$PluginClass | Out-File -FilePath "$ProjectRoot\src\main\java\$PackagePath\$PluginName.java" -Encoding UTF8

# Create manifest.json
Write-Host "Creating manifest.json..." -ForegroundColor Green
$Manifest = @"
{
  "Group": "$Group",
  "Name": "$PluginName",
  "Version": "0.1.0",
  "Description": "A Hytale server plugin",
  "Main": "$Group.$PluginNameLower.$PluginName",
  "Authors": [{ "Name": "Developer" }]
}
"@
$Manifest | Out-File -FilePath "$ProjectRoot\src\main\resources\manifest.json" -Encoding UTF8

# Create build.gradle.kts
Write-Host "Creating build.gradle.kts..." -ForegroundColor Green
$BuildGradle = @"
plugins {
    java
}

group = "$Group"
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
    archiveBaseName.set("$PluginNameLower")
    from(sourceSets.main.get().output)

    // Copy to mods folder after build
    doLast {
        val modsDir = file("runtime/Server/mods")
        if (modsDir.exists()) {
            copy {
                from(archiveFile)
                into(modsDir)
            }
            println("Copied `${archiveFile.get().asFile.name} to mods/")
        }
    }
}

// Custom task to deploy plugin
tasks.register("deploy") {
    dependsOn("jar")
    group = "deployment"
    description = "Build and deploy plugin to server mods folder"
}
"@
$BuildGradle | Out-File -FilePath "$ProjectRoot\build.gradle.kts" -Encoding UTF8

# Create settings.gradle.kts
Write-Host "Creating settings.gradle.kts..." -ForegroundColor Green
$Settings = @"
rootProject.name = "$PluginNameLower"
"@
$Settings | Out-File -FilePath "$ProjectRoot\settings.gradle.kts" -Encoding UTF8

# Check if gradle wrapper exists
if (-not (Test-Path "$ProjectRoot\gradle\wrapper\gradle-wrapper.jar")) {
    Write-Host "Creating gradle-wrapper.properties..." -ForegroundColor Green
    $WrapperProps = @"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
"@
    $WrapperProps | Out-File -FilePath "$ProjectRoot\gradle\wrapper\gradle-wrapper.properties" -Encoding UTF8

    # Try to download gradle wrapper
    Write-Host "Downloading Gradle wrapper..." -ForegroundColor Green
    $WrapperUrl = "https://github.com/gradle/gradle/raw/v8.12.0/gradle/wrapper/gradle-wrapper.jar"
    try {
        Invoke-WebRequest -Uri $WrapperUrl -OutFile "$ProjectRoot\gradle\wrapper\gradle-wrapper.jar" -UseBasicParsing
    } catch {
        Write-Host "Warning: Could not download gradle-wrapper.jar. Run './gradlew wrapper' manually." -ForegroundColor Yellow
    }
}

# Create gradlew.bat script
Write-Host "Creating gradlew.bat..." -ForegroundColor Green
$GradlewBat = @'
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
'@
$GradlewBat | Out-File -FilePath "$ProjectRoot\gradlew.bat" -Encoding ASCII

# Create gradlew script for bash (in case using WSL)
Write-Host "Creating gradlew..." -ForegroundColor Green
$Gradlew = @'
#!/bin/sh

APP_HOME=$( cd "${APP_HOME:-./}" && pwd -P ) || exit
DEFAULT_JVM_OPTS='-Xmx64m -Xms64m'
CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

if [ -n "$JAVA_HOME" ] ; then
    JAVACMD=$JAVA_HOME/bin/java
else
    JAVACMD=java
fi

exec "$JAVACMD" $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS \
  -classpath "$CLASSPATH" \
  org.gradle.wrapper.GradleWrapperMain \
  "$@"
'@
$Gradlew | Out-File -FilePath "$ProjectRoot\gradlew" -Encoding UTF8 -NoNewline

# Create mods directory if needed
New-Item -ItemType Directory -Force -Path "$ProjectRoot\runtime\Server\mods" -ErrorAction SilentlyContinue | Out-Null

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Initialization complete!            " -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your plugin structure:"
Write-Host "  src\main\java\$PackagePath\$PluginName.java"
Write-Host "  src\main\resources\manifest.json"
Write-Host "  build.gradle.kts"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Edit your plugin code in src\main\java\"
Write-Host "  2. Build: .\gradlew.bat build"
Write-Host "  3. Deploy: .\scripts\deploy.ps1"
Write-Host ""
Write-Host "Quick commands:" -ForegroundColor Blue
Write-Host "  .\gradlew.bat build      - Build plugin JAR"
Write-Host "  .\scripts\deploy.ps1     - Build + copy to mods + reload server"
Write-Host ""
