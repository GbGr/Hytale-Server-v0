# Hytale Server API Index

This documentation is auto-generated from decompiled HytaleServer.jar for AI agents to assist with plugin development.

## Package Overview

| Package | Description |
|---------|-------------|
| `com.hypixel.hytale.server.core.plugin` | Plugin system - loading, lifecycle, registries |
| `com.hypixel.hytale.server.core.entity` | Entities - Player, LivingEntity, Entity base |
| `com.hypixel.hytale.server.core.event` | Server events - player, entity, blocks |
| `com.hypixel.hytale.server.core.command` | Command system - registration, arguments |
| `com.hypixel.hytale.server.core.universe` | Worlds, chunks, world generation |
| `com.hypixel.hytale.server.core.blocktype` | Block types and states |
| `com.hypixel.hytale.server.core.inventory` | Inventory and item management |
| `com.hypixel.hytale.server.core.permissions` | Permission system |
| `com.hypixel.hytale.component` | ECS (Entity Component System) |
| `com.hypixel.hytale.event` | Core event bus infrastructure |
| `com.hypixel.hytale.registry` | Asset and type registries |
| `com.hypixel.hytale.logger` | Logging (HytaleLogger) |

## Key Entry Points for Plugins

### Plugin Base Class
```java
import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;

public class MyPlugin extends JavaPlugin {
    public MyPlugin(JavaPluginInit init) {
        super(init);
    }

    @Override
    protected void setup() {
        // Plugin initialization
    }
}
```

### Important Managers (via HytaleServer)
- `HytaleServer.instance()` - Server singleton
- `server.getPluginManager()` - Plugin management
- `server.getCommandManager()` - Command registration
- `server.getEventBus()` - Event subscription
- `server.getUniverse()` - World access

## Documentation Files

- [Plugin System](packages/plugin.md) - JavaPlugin, lifecycle, registries
- [Entity System](packages/entity.md) - Player, Entity, components
- [Event System](packages/event.md) - Events, EventBus, priorities
- [Command System](packages/command.md) - Commands, arguments, suggestions
- [World System](packages/universe.md) - Worlds, chunks, blocks
- [ECS System](packages/component.md) - Components, Systems, Stores
- [UI System](packages/ui.md) - Custom pages, windows, event handling
- [Built-in Plugins](packages/builtin.md) - Example plugins to learn from

## Quick Reference

### Event Subscription
```java
server.getEventBus().subscribe(PlayerConnectEvent.class, event -> {
    // Handle player connect
});
```

### Command Registration
```java
// Extend AbstractPlayerCommand, AbstractWorldCommand, etc.
server.getCommandManager().register(myCommand);
```

### ECS Component Access
```java
entity.get(ComponentType.class);  // Get component
entity.has(ComponentType.class);  // Check if has component
```

## Real Plugin Examples

### Lucky-Mining ([GitHub](https://github.com/Buuz135/Lucky-Mining))
Mining plugin that demonstrates:
- Config system with Codecs
- EntityEventSystem for BreakBlockEvent
- World block manipulation
- Per-player state tracking

See [Plugin System - Real-World Example](packages/plugin.md#real-world-example-lucky-mining-plugin)

## Decompiled Sources

Full decompiled sources available in `docs/decompiled/` for detailed implementation reference.

To regenerate (if needed):
```bash
brew install cfr-decompiler
cfr-decompiler runtime/Server/HytaleServer.jar --outputdir docs/decompiled
```

---
*Generated for AI assistants working with Hytale plugin development*
