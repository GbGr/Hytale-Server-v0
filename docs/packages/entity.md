# Entity System

Package: `com.hypixel.hytale.server.core.entity`

## Overview

Entities are game objects that exist in worlds - players, NPCs, creatures, items, projectiles, etc. The entity system is built on top of an ECS (Entity Component System) architecture.

## Class Hierarchy

```
Entity (abstract)
├── LivingEntity (abstract)
│   ├── Player
│   └── [NPC entities]
├── BlockEntity
└── [Other entities]
```

## Core Classes

### Entity

Base class for all entities. Key features:
- Network ID for client sync
- UUID for persistence
- World reference
- ECS Ref/Holder access

```java
// Entity fields
int networkId              // Network sync ID
UUID legacyUuid            // Persistent identifier
World world                // Current world
Ref<EntityStore> reference // ECS reference
```

### Key Methods

```java
// Lifecycle
entity.remove()                    // Remove from world
entity.loadIntoWorld(world)        // Add to world
entity.unloadFromWorld()           // Remove without deleting
entity.wasRemoved()                // Check if removed

// World/Position
entity.getWorld()                  // Get current world
entity.getTransformComponent()     // Get position (deprecated, use ECS)
entity.moveTo(ref, x, y, z, accessor) // Move entity

// Identity
entity.getUuid()                   // Get UUID
entity.getNetworkId()              // Get network ID

// ECS
entity.getReference()              // Get ECS Ref
entity.toHolder()                  // Convert to Holder
entity.clone()                     // Clone entity
```

### Player (extends LivingEntity)

Player entity with all player-specific functionality.

```java
public class Player extends LivingEntity
    implements CommandSender, PermissionHolder, MetricProvider
```

#### Player-Specific Features

```java
// Identity
player.getUuid()                   // Player UUID
player.getPlayerRef()              // PlayerRef component
player.getDisplayName()            // Username

// Communication
player.sendMessage(Message)        // Send chat message

// Permissions
player.hasPermission("permission.id")
player.hasPermission("permission.id", defaultValue)

// Game Mode
player.getGameMode()               // Get current game mode
Player.setGameMode(ref, mode, accessor)  // Set game mode

// Managers
player.getInventory()              // Player inventory
player.getHotbarManager()          // Hotbar access
player.getWindowManager()          // UI windows
player.getPageManager()            // Server pages
player.getHudManager()             // HUD elements
player.getWorldMapTracker()        // Chunk tracking
player.getCameraManager()          // Camera control (via PlayerRef)

// Respawn
Player.getRespawnPosition(ref, worldName, accessor) // Get respawn location
player.hasSpawnProtection()        // Check invulnerability
```

#### PlayerRef

Component that holds player connection info:

```java
PlayerRef playerRef = accessor.getComponent(ref, PlayerRef.getComponentType());

playerRef.getUuid()                // Player UUID
playerRef.getUsername()            // Player name
playerRef.getPacketHandler()       // Network connection
playerRef.sendMessage(Message)     // Send message
playerRef.getHiddenPlayersManager() // Hidden players
playerRef.getComponent(type)       // Get component
```

### LivingEntity

Base for entities with health, inventory, etc:

```java
// Health
livingEntity.getHealth()
livingEntity.setHealth(value)
livingEntity.getMaxHealth()
livingEntity.damage(cause, amount)

// Inventory
livingEntity.getInventory()
livingEntity.setInventory(inventory)
```

## Game Modes

```java
public enum GameMode {
    Survival,
    Adventure,
    Creative
}

// Set player game mode
Player.setGameMode(ref, GameMode.Creative, componentAccessor);
```

## Working with Entities (ECS Style)

Modern Hytale uses ECS. Access entities through stores:

```java
// In event handler or system
void handleEvent(BreakBlockEvent event) {
    Ref<EntityStore> ref = ...;
    ComponentAccessor<EntityStore> accessor = ...;

    // Get Player component
    Player player = accessor.getComponent(ref, Player.getComponentType());

    // Get Transform
    TransformComponent transform = accessor.getComponent(ref, TransformComponent.getComponentType());
    Vector3d position = transform.getPosition();

    // Get PlayerRef
    PlayerRef playerRef = accessor.getComponent(ref, PlayerRef.getComponentType());
    playerRef.sendMessage(Message.text("Hello!"));
}
```

## Key Components

| Component | Purpose |
|-----------|---------|
| `Player` | Player data and managers |
| `PlayerRef` | Connection and identity |
| `TransformComponent` | Position and rotation |
| `BoundingBox` | Collision box |
| `Velocity` | Movement velocity |
| `UUIDComponent` | Entity UUID |
| `MovementStatesComponent` | Flying, swimming, etc |
| `ChunkTracker` | Tracked chunks |
| `Invulnerable` | Damage immunity |

## Entity Events

```java
// Subscribe to entity events
getEventRegistry().subscribe(EntityRemoveEvent.class, event -> {
    Entity entity = event.getEntity();
});

getEventRegistry().subscribe(PlayerConnectEvent.class, event -> {
    PlayerRef ref = event.getPlayerRef();
    Holder<EntityStore> holder = event.getHolder();
});
```

## Spawning Entities

```java
// Entity creation typically through EntityModule
EntityModule entityModule = EntityModule.get();

// Get component types
ComponentType<EntityStore, Player> playerType = Player.getComponentType();
```

## Messages

Send messages to players:

```java
// Simple text
player.sendMessage(Message.text("Hello!"));

// Translation key with params
player.sendMessage(Message.translation("server.general.welcome")
    .param("username", player.getDisplayName()));

// Colored message
player.sendMessage(Message.translation("server.chat.error")
    .color("#ff5555"));
```

## See Also

- [Plugin System](plugin.md) - EntityRegistry for custom entities
- [Event System](event.md) - Entity-related events
- [ECS System](component.md) - Component architecture
- [World System](universe.md) - World and chunk management
