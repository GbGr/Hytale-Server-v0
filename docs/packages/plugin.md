# Plugin System

Package: `com.hypixel.hytale.server.core.plugin`

## Overview

The plugin system allows extending Hytale server functionality through Java plugins. Each plugin is a JAR file with a `manifest.json` that specifies metadata and main class.

## Core Classes

### JavaPlugin (extends PluginBase)

Base class for all plugins. Your plugin must extend this class.

```java
package com.example.myplugin;

import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;
import com.hypixel.hytale.logger.HytaleLogger;
import javax.annotation.Nonnull;

public class MyPlugin extends JavaPlugin {
    private static final HytaleLogger LOGGER = HytaleLogger.forEnclosingClass();

    public MyPlugin(@Nonnull JavaPluginInit init) {
        super(init);
    }

    @Override
    protected void setup() {
        // Called during plugin setup phase
        // Register commands, events, components here
        LOGGER.info("MyPlugin setup!");
    }

    @Override
    protected void start() {
        // Called after setup, when plugin is starting
        // Plugin is fully enabled after this
    }

    @Override
    protected void shutdown() {
        // Called when plugin is being disabled
        // Clean up resources here
    }
}
```

### Plugin Lifecycle

```
NONE → SETUP → START → ENABLED → SHUTDOWN → DISABLED
```

1. **NONE** - Plugin loaded but not initialized
2. **SETUP** - `setup()` method called, register things here
3. **START** - `start()` method called
4. **ENABLED** - Plugin fully operational
5. **SHUTDOWN** - `shutdown()` method called
6. **DISABLED** - Plugin disabled, all registries cleaned up

### PluginBase - Available Registries

PluginBase provides these registries for safe resource management (auto-cleanup on disable):

| Registry | Method | Purpose |
|----------|--------|---------|
| CommandRegistry | `getCommandRegistry()` | Register commands |
| EventRegistry | `getEventRegistry()` | Subscribe to events |
| EntityRegistry | `getEntityRegistry()` | Register entity types |
| BlockStateRegistry | `getBlockStateRegistry()` | Register block states |
| TaskRegistry | `getTaskRegistry()` | Schedule tasks |
| AssetRegistry | `getAssetRegistry()` | Register assets |
| ClientFeatureRegistry | `getClientFeatureRegistry()` | Client-side features |
| EntityStoreRegistry | `getEntityStoreRegistry()` | ECS entity storage |
| ChunkStoreRegistry | `getChunkStoreRegistry()` | ECS chunk storage |

### JavaPluginInit

Passed to constructor, contains:
- `getFile()` - Path to plugin JAR
- `getClassLoader()` - Plugin's class loader
- `getPluginManifest()` - Parsed manifest.json
- `getDataDirectory()` - Plugin data folder

## Configuration

Plugins can use `Config<T>` for configuration files with automatic serialization via Codecs.

### Config Class Example (from Lucky-Mining plugin)

```java
public class LMConfig {
    // Define codec for serialization
    public static final BuilderCodec<LMConfig> CODEC = BuilderCodec.builder(LMConfig.class)
        .append(new KeyedCodec<>("LuckStartChance", Codec.DOUBLE),
            (cfg, v) -> cfg.luckStartChance = v,
            cfg -> cfg.luckStartChance).add()
        .append(new KeyedCodec<>("LuckIncreaseChance", Codec.DOUBLE),
            (cfg, v) -> cfg.luckIncreaseChance = v,
            cfg -> cfg.luckIncreaseChance).add()
        .append(new KeyedCodec<>("MaxTimeBetweenBlockBreaksInSeconds", Codec.INTEGER),
            (cfg, v) -> cfg.maxTime = v,
            cfg -> cfg.maxTime).add()
        .append(new KeyedCodec<>("WhitelistOres", Codec.STRING.listOf()),
            (cfg, v) -> cfg.whitelistOres = v.toArray(new String[0]),
            cfg -> Arrays.asList(cfg.whitelistOres)).add()
        .build();

    // Config fields with defaults
    private double luckStartChance = 0.40;
    private double luckIncreaseChance = 0.02;
    private int maxTime = 3;
    private String[] whitelistOres = {"Iron", "Gold", "Copper"};

    // Getters
    public double getLuckStartChance() { return luckStartChance; }
    public double getLuckIncreaseChance() { return luckIncreaseChance; }
    public int getMaxTime() { return maxTime; }
    public String[] getWhitelistOres() { return whitelistOres; }
}
```

### Using Config in Plugin

```java
public class MyPlugin extends JavaPlugin {
    private Config<LMConfig> config;

    public MyPlugin(JavaPluginInit init) {
        super(init);
        // Initialize config in constructor (before setup!)
        this.config = withConfig("MyPlugin", LMConfig.CODEC);
    }

    @Override
    protected void setup() {
        config.save();  // Save default config if not exists
        LMConfig cfg = config.get();
        // Use config values
        double chance = cfg.getLuckStartChance();
    }
}
```

## Key Methods

### From PluginBase

```java
// Logging
getLogger().info("Message");
getLogger().at(Level.WARNING).log("Formatted %s", value);

// Identity
getIdentifier()       // PluginIdentifier (Group:Name)
getManifest()         // PluginManifest from manifest.json
getName()             // String identifier

// State
getState()            // Current PluginState
isEnabled()           // true if plugin is running
isDisabled()          // true if not running

// Paths
getDataDirectory()    // Plugin data folder
getFile()             // JAR file path (JavaPlugin only)

// Permissions
getBasePermission()   // "group.name" lowercase
```

## Manifest (manifest.json)

```json
{
  "Group": "com.example",
  "Name": "MyPlugin",
  "Version": "1.0.0",
  "Main": "com.example.myplugin.MyPlugin",
  "Description": "My awesome plugin",
  "Authors": ["Developer"],
  "Dependencies": ["com.other:OtherPlugin"],
  "IncludeAssetPack": false
}
```

## Plugin Commands

Server console commands for managing plugins:

```
/plugin list                    # List all plugins
/plugin load <Group:Name>       # Load a plugin
/plugin unload <Group:Name>     # Unload a plugin
/plugin reload <Group:Name>     # Reload (unload + load)
```

## Related Classes

- `PluginManager` - Manages all plugins (load/unload/reload)
- `PluginClassLoader` - Isolated class loading per plugin
- `PluginIdentifier` - Group:Name identifier
- `PluginManifest` - Parsed manifest.json
- `PluginState` - Enum of lifecycle states
- `PluginType` - PLUGIN or ADDON

## Real-World Example: Lucky-Mining Plugin

Complete example from [Lucky-Mining](https://github.com/Buuz135/Lucky-Mining) - a plugin that gives bonus ores when mining consecutively.

### Main Plugin Class

```java
public class LuckyMining extends JavaPlugin {
    private Config<LMConfig> config;

    public LuckyMining(@Nonnull JavaPluginInit init) {
        super(init);
        this.config = withConfig("LuckyMining", LMConfig.CODEC);
    }

    @Override
    protected void setup() {
        config.save();
        // Register ECS system for block break events
        getEntityStoreRegistry().register(new BreakBlockEventSystem(config));
    }
}
```

### ECS Event System

```java
public class BreakBlockEventSystem implements EntityEventSystem<EntityStore, BreakBlockEvent> {
    private final Config<LMConfig> config;
    private final HashMap<UUID, LuckyMiningInfo> luckyMiningInfo = new HashMap<>();

    public BreakBlockEventSystem(Config<LMConfig> config) {
        this.config = config;
    }

    @Override
    public EntityEventType<BreakBlockEvent> getEventType() {
        return BreakBlockEvent.EVENT;
    }

    @Override
    public void accept(Store<EntityStore> store, Ref<EntityStore> ref,
                      ComponentAccessor<EntityStore> accessor, BreakBlockEvent event) {
        LMConfig cfg = config.get();
        World world = store.getExternalData().getWorld();
        BlockType blockType = event.getBlockType();

        // Check if block is whitelisted ore
        if (!isWhitelistedOre(blockType, cfg)) return;

        // Get player UUID
        UUIDComponent uuid = accessor.getComponent(ref, UUIDComponent.getComponentType());
        if (uuid == null) return;

        // Track consecutive mining and calculate luck
        LuckyMiningInfo info = luckyMiningInfo.computeIfAbsent(
            uuid.getUuid(), k -> new LuckyMiningInfo());

        // Reset if too much time passed
        if (System.currentTimeMillis() - info.lastBreak > cfg.getMaxTime() * 1000) {
            info.reset(cfg.getLuckStartChance());
        }

        // Roll for bonus ore
        if (Math.random() < info.chance) {
            Vector3i pos = event.getTargetBlock();
            // Find adjacent block to place bonus ore
            Vector3i bonusPos = findAdjacentReplaceableBlock(world, pos, cfg);
            if (bonusPos != null) {
                world.setBlock(bonusPos.x, bonusPos.y, bonusPos.z, blockType);
                // Spawn particles/sound
                spawnEffects(world, bonusPos);
            }
        }

        // Increase luck for next break
        info.chance += cfg.getLuckIncreaseChance();
        info.lastBreak = System.currentTimeMillis();
    }
}
```

### Manifest (manifest.json)

```json
{
  "Group": "Buuz135",
  "Name": "LuckyMining",
  "Version": "1.0.3",
  "Main": "com.buuz135.luckymining.LuckyMining",
  "Description": "Get more ores from mining, the more you mine in a row",
  "Authors": ["Buuz135"],
  "Website": "https://buuz135.com",
  "ServerVersion": "*",
  "IncludeAssetPack": true
}
```

### Key Patterns Used

1. **Config with Codec** - Persistent configuration with auto-serialization
2. **EntityStoreRegistry** - Register ECS systems for game events
3. **EntityEventSystem** - Handle entity-scoped events (BreakBlockEvent)
4. **ComponentAccessor** - Access entity components (UUIDComponent)
5. **World.setBlock()** - Modify world blocks

## See Also

- [Event System](event.md) - How to subscribe to events
- [Command System](command.md) - How to register commands
- [Entity System](entity.md) - Working with entities
- [ECS System](component.md) - EntityEventSystem and ComponentAccessor
