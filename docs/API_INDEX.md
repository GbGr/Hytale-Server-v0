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

### Important Singletons
- `HytaleServer.get()` - Server singleton
- `Universe.get()` - Universe singleton (worlds, players)
- `PluginManager.get()` - Plugin management

### Via HytaleServer
- `server.getEventBus()` - Event subscription
- `server.getConfig()` - Server configuration

## Documentation Files

- [Plugin System](packages/plugin.md) - JavaPlugin, lifecycle, registries
- [Entity System](packages/entity.md) - Player, Entity, components
- [Event System](packages/event.md) - Events, EventBus, priorities
- [Command System](packages/command.md) - Commands, arguments, suggestions
- [World System](packages/universe.md) - Worlds, chunks, blocks, world generation
- [ECS System](packages/component.md) - Components, Systems, Stores
- [UI System](packages/ui.md) - Custom pages, .ui files, event handling
- [Built-in Plugins](packages/builtin.md) - Example plugins to learn from

## Quick Reference

### Event Subscription (in plugin setup())
```java
// Global events (player connect, chat, etc.)
getEventRegistry().registerGlobal(PlayerConnectEvent.class, event -> {
    event.setWorld(Universe.get().getWorld("spawn"));
});

// Via server event bus
HytaleServer.get().getEventBus().dispatchFor(MyEvent.class).dispatch(new MyEvent());
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

### Custom UI (Pages)
```java
// Asset pack structure: src/main/resources/Common/UI/Custom/Pages/PluginName_Page.ui
// manifest.json must have: "IncludesAssetPack": true (with 's'!)

// Open page
player.getPageManager().openCustomPage(ref, store, new MyPage(playerRef));

// Close page
player.getPageManager().setPage(ref, store, Page.None);

// UI file (.ui) uses Common.ui components:
// $C = "../Common.ui";
// $C.@PageOverlay {}
// $C.@DecoratedContainer { ... }
// $C.@BackButton #CloseButton {}
```

## Real Plugin Examples

### Lucky-Mining ([GitHub](https://github.com/Buuz135/Lucky-Mining))
Mining plugin that demonstrates:
- Config system with Codecs
- EntityEventSystem for BreakBlockEvent
- World block manipulation
- Per-player state tracking

### Advanced-Item-Info ([GitHub](https://github.com/Buuz135/Advanced-Item-Info))
Item browser plugin that demonstrates:
- Custom UI with InteractiveCustomUIPage
- Search functionality with rebuild()
- Event data codecs
- Grid-based UI layout

### AdminUI ([GitHub](https://github.com/Buuz135/AdminUI))
Admin panel plugin that demonstrates:
- Complex multi-page UI
- Tab navigation
- Form inputs
- Server management commands

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
