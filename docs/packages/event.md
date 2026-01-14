# Event System

Packages:
- `com.hypixel.hytale.event` - Core event bus infrastructure
- `com.hypixel.hytale.server.core.event.events` - Server-specific events

## Overview

Hytale uses an event-driven architecture. Events are dispatched through an EventBus, and plugins can subscribe to handle them. Events can be synchronous or asynchronous, and some are cancellable.

## Subscribing to Events

Use the `EventRegistry` from your plugin:

```java
public class MyPlugin extends JavaPlugin {
    public MyPlugin(JavaPluginInit init) {
        super(init);
    }

    @Override
    protected void setup() {
        // Subscribe to player connect
        getEventRegistry().subscribe(PlayerConnectEvent.class, this::onPlayerConnect);

        // Subscribe to chat with priority
        getEventRegistry().subscribe(PlayerChatEvent.class, EventPriority.HIGH, this::onChat);

        // Subscribe to block break
        getEventRegistry().subscribe(BreakBlockEvent.class, this::onBlockBreak);
    }

    private void onPlayerConnect(PlayerConnectEvent event) {
        PlayerRef playerRef = event.getPlayerRef();
        getLogger().info("Player connected: " + playerRef.getUsername());

        // Optionally set spawn world
        event.setWorld(someWorld);
    }

    private void onChat(PlayerChatEvent event) {
        // Modify or cancel chat
        if (event.getContent().contains("bad")) {
            event.setCancelled(true);
        }
    }

    private void onBlockBreak(BreakBlockEvent event) {
        Vector3i pos = event.getTargetBlock();
        BlockType type = event.getBlockType();
        // Cancel if needed
        event.setCancelled(true);
    }
}
```

## Event Types

### Core Interfaces (`com.hypixel.hytale.event`)

| Interface | Description |
|-----------|-------------|
| `IEvent<T>` | Base event interface, T is result type |
| `IAsyncEvent<T>` | Async event (different thread) |
| `ICancellable` | Event can be cancelled |
| `IProcessedEvent` | Has processed flag |

### Player Events (`server.core.event.events.player`)

| Event | Cancellable | Description |
|-------|-------------|-------------|
| `PlayerConnectEvent` | No | Player connecting, can set spawn world |
| `PlayerDisconnectEvent` | No | Player disconnecting |
| `PlayerReadyEvent` | No | Player fully loaded and ready |
| `PlayerChatEvent` | Yes | Chat message, can modify content/targets |
| `PlayerInteractEvent` | Yes | Player interaction with world |
| `PlayerMouseButtonEvent` | No | Mouse click input |
| `PlayerMouseMotionEvent` | No | Mouse movement |
| `PlayerCraftEvent` | No | Player crafting |
| `AddPlayerToWorldEvent` | No | Player added to world |
| `DrainPlayerFromWorldEvent` | No | Player removed from world |

### Block/ECS Events (`server.core.event.events.ecs`)

| Event | Cancellable | Description |
|-------|-------------|-------------|
| `BreakBlockEvent` | Yes | Block being broken |
| `PlaceBlockEvent` | Yes | Block being placed |
| `DamageBlockEvent` | Yes | Block taking damage |
| `UseBlockEvent` | Yes | Block being used (Pre/Post) |
| `DropItemEvent` | Yes | Item dropped |
| `InteractivelyPickupItemEvent` | Yes | Item picked up |
| `CraftRecipeEvent` | Yes | Crafting (Pre/Post) |
| `SwitchActiveSlotEvent` | No | Hotbar slot changed |
| `ChangeGameModeEvent` | Yes | Game mode changing |
| `DiscoverZoneEvent` | No | Zone discovered |

### Entity Events (`server.core.event.events.entity`)

| Event | Cancellable | Description |
|-------|-------------|-------------|
| `EntityEvent` | No | Base entity event |
| `EntityRemoveEvent` | No | Entity being removed |
| `LivingEntityInventoryChangeEvent` | No | Inventory changed |
| `LivingEntityUseBlockEvent` | No | Entity using block |

### Server Events

| Event | Description |
|-------|-------------|
| `BootEvent` | Server starting up |
| `ShutdownEvent` | Server shutting down |
| `PrepareUniverseEvent` | Universe being prepared |

### Permission Events (`server.core.event.events.permissions`)

| Event | Description |
|-------|-------------|
| `PlayerPermissionChangeEvent` | Player permissions changed |
| `GroupPermissionChangeEvent` | Permission group changed |
| `PlayerGroupEvent` | Player added/removed from group |

## Event Priority

```java
public enum EventPriority {
    LOWEST,   // First to run
    LOW,
    NORMAL,   // Default
    HIGH,
    HIGHEST,  // Last to run (final say on cancellation)
    MONITOR   // Only observe, don't modify
}
```

## Cancellable Events

```java
getEventRegistry().subscribe(PlayerChatEvent.class, event -> {
    if (shouldCancel(event)) {
        event.setCancelled(true);
    }
});

// Check if already cancelled
if (!event.isCancelled()) {
    // Process event
}
```

## Event Data Examples

### PlayerConnectEvent
```java
event.getPlayerRef()    // PlayerRef - player reference
event.getHolder()       // Holder<EntityStore> - ECS holder
event.getWorld()        // World or null
event.setWorld(world)   // Set spawn world
```

### PlayerChatEvent (Async, Cancellable)
```java
event.getSender()       // PlayerRef
event.getTargets()      // List<PlayerRef>
event.getContent()      // String message
event.setContent(msg)   // Modify message
event.setTargets(list)  // Change recipients
event.getFormatter()    // Message formatter
event.setFormatter(fmt) // Custom format
```

### BreakBlockEvent (Cancellable)
```java
event.getTargetBlock()  // Vector3i position
event.getBlockType()    // BlockType being broken
event.getItemInHand()   // ItemStack or null
event.setCancelled(true) // Prevent break
```

### PlaceBlockEvent (Cancellable)
```java
event.getTargetBlock()  // Vector3i position
event.getItemInHand()   // ItemStack being placed
event.getRotation()     // RotationTuple
event.setRotation(rot)  // Change rotation
```

## ECS Events (EntityEventSystem)

Block events like `BreakBlockEvent` are ECS events that should be handled via `EntityEventSystem`, not `EventRegistry`.

### Two Ways to Handle Events

**1. EventRegistry (simple events like PlayerConnect)**
```java
getEventRegistry().subscribe(PlayerConnectEvent.class, event -> {
    PlayerRef ref = event.getPlayerRef();
});
```

**2. EntityEventSystem (ECS events like BreakBlock)**
```java
public class MySystem implements EntityEventSystem<EntityStore, BreakBlockEvent> {
    @Override
    public EntityEventType<BreakBlockEvent> getEventType() {
        return BreakBlockEvent.EVENT;
    }

    @Override
    public void accept(Store<EntityStore> store, Ref<EntityStore> ref,
                      ComponentAccessor<EntityStore> accessor, BreakBlockEvent event) {
        // Full ECS access - components, world, etc.
        World world = store.getExternalData().getWorld();
        BlockType block = event.getBlockType();
        event.setCancelled(true);
    }
}

// Register in setup()
getEntityStoreRegistry().register(new MySystem());
```

### When to Use Which

| Event Type | Use | Examples |
|------------|-----|----------|
| `EventRegistry` | Connection, chat, permissions | PlayerConnectEvent, PlayerChatEvent |
| `EntityEventSystem` | Block, entity, inventory actions | BreakBlockEvent, PlaceBlockEvent, DropItemEvent |

See [ECS System](component.md) for more details on EntityEventSystem.

## Async Events

`IAsyncEvent` implementations run on a different thread. Be careful with thread safety:

```java
getEventRegistry().subscribe(PlayerChatEvent.class, event -> {
    // This runs async - don't modify game state directly
    // Use server.getScheduler() to run on main thread
});
```

## See Also

- [Plugin System](plugin.md) - EventRegistry access
- [Entity System](entity.md) - Player and Entity classes
- [ECS System](component.md) - Component system for ECS events
