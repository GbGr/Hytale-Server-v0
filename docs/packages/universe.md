# World System (Universe)

Package: `com.hypixel.hytale.server.core.universe`

## Overview

The universe system manages worlds, chunks, blocks, and world generation. A server has one `Universe` containing multiple `World` instances.

## Core Classes

### Universe

Singleton managing all worlds and player data. Universe itself extends JavaPlugin.

```java
Universe universe = Universe.get();

// Get worlds
World world = universe.getWorld("worldName");
World world = universe.getWorld(uuid);           // by UUID
World defaultWorld = universe.getDefaultWorld(); // from config
Map<String, World> worlds = universe.getWorlds();

// Create new world (async, returns CompletableFuture)
universe.addWorld("myworld")                                    // default generator
    .thenAccept(world -> { /* world ready */ });

universe.addWorld("voidworld", "Void", null)                    // void generator
    .thenAccept(world -> { /* empty world ready */ });

universe.addWorld("flatworld", "Flat", null)                    // flat generator
    .thenAccept(world -> { /* flat world ready */ });

// Load existing world from disk
universe.loadWorld("savedworld").thenAccept(world -> { });

// Remove world
universe.removeWorld("worldName");

// Wait for universe initialization
universe.getUniverseReady().thenRun(() -> {
    // All worlds loaded, safe to access
});

// Player management
PlayerRef player = universe.getPlayer(uuid);
PlayerRef player = universe.getPlayerByUsername("name", NameMatching.EXACT);
List<PlayerRef> players = universe.getPlayers();
int count = universe.getPlayerCount();

// Player storage
universe.getPlayerStorage().save(uuid, holder);
universe.getPlayerStorage().load(uuid);
```

### World

A single world/dimension with its own chunks, entities, and tick loop:

```java
public class World extends TickingThread
    implements Executor, ChunkAccessor<WorldChunk>, IWorldChunks, IMessageReceiver
```

#### World Properties

```java
world.getName()                    // World name
world.getSavePath()                // Save directory path
world.getWorldConfig()             // World configuration
world.getGameplayConfig()          // Gameplay settings
world.isAlive()                    // Is world running
world.isPaused()                   // Is ticking paused
```

#### Chunk Access

```java
// Get chunk at block position
WorldChunk chunk = world.getChunk(x, y, z);
WorldChunk chunk = world.getChunkAt(chunkX, chunkY, chunkZ);

// Get chunk column
ChunkColumn column = world.getChunkColumn(chunkX, chunkZ);

// Load chunk async
world.loadChunk(chunkX, chunkY, chunkZ).thenAccept(chunk -> { });

// Check if loaded
boolean loaded = world.isChunkLoaded(chunkX, chunkY, chunkZ);
```

#### Block Operations

```java
// Get block at position
BlockType block = world.getBlockType(x, y, z);

// Set block
world.setBlock(x, y, z, blockType);
world.setBlock(x, y, z, blockType, rotation);

// Get block state
BlockState state = world.getBlockState(x, y, z);
```

#### Entity Store

```java
// Get entity store
EntityStore entityStore = world.getEntityStore();
Store<EntityStore> store = entityStore.getStore();

// Spawn entity
Ref<EntityStore> ref = entityStore.spawnEntity(holder);

// Get all entities
store.forEach(Player.getComponentType(), (ref, player) -> { });
```

#### Chunk Store

```java
ChunkStore chunkStore = world.getChunkStore();
```

#### Execution

```java
// Run on world thread
world.execute(() -> {
    // Code runs on world tick thread
});

// Check if on world thread
if (world.isInThread()) { }
```

### WorldConfig

World configuration settings:

```java
WorldConfig config = world.getWorldConfig();

config.getGameMode()               // Default game mode
config.getSpawnProvider()          // Spawn point provider
config.getWorldGenProvider()       // World generator
config.getDayNightCycle()          // Time settings
```

### GameplayConfig

Gameplay rules:

```java
GameplayConfig gameplay = world.getGameplayConfig();

gameplay.getShowItemPickupNotifications()
gameplay.getPvpEnabled()
// etc.
```

## Chunks

### WorldChunk

Single chunk section (16x16x16):

```java
chunk.getChunkX()
chunk.getChunkY()
chunk.getChunkZ()

// Block operations within chunk
chunk.getBlockType(localX, localY, localZ)
chunk.setBlock(localX, localY, localZ, blockType)
```

### ChunkColumn

Full column of chunks at X,Z:

```java
column.getChunkX()
column.getChunkZ()
column.getChunk(chunkY)            // Get specific chunk
column.getChunks()                 // All chunks in column
```

## Block Types

### BlockType

Represents a type of block:

```java
BlockType stone = BlockType.get("hytale:stone");
BlockType air = BlockType.AIR;

blockType.getKey()                 // Asset key
blockType.getTranslationKey()      // For localization
blockType.isAir()                  // Check if air
blockType.isSolid()                // Check solidity
```

### BlockState

Block type + state data:

```java
BlockState state = world.getBlockState(x, y, z);
state.getBlockType()
state.getRotation()
state.getProperties()
```

## World Generation

### IWorldGenProvider

Interface for world generators:

```java
public interface IWorldGenProvider {
    IWorldGen getGenerator() throws WorldGenLoadException;
}
```

### Built-in Generators

| Generator ID | Class | Description |
|-------------|-------|-------------|
| `"Void"` | `VoidWorldGenProvider` | Empty world, no blocks generated |
| `"Flat"` | `FlatWorldGenProvider` | Flat terrain with configurable layers |
| `"Dummy"` | `DummyWorldGenProvider` | Minimal generation |

### Creating Worlds with Generators

```java
// Via Universe.addWorld(name, generatorType, chunkStorageType)
Universe.get().addWorld("empty", "Void", null);   // Void world
Universe.get().addWorld("flat", "Flat", null);    // Flat world

// Via WorldConfig
WorldConfig config = world.getWorldConfig();
config.setWorldGenProvider(new VoidWorldGenProvider());
config.setWorldGenProvider(new FlatWorldGenProvider());
```

### VoidWorldGenProvider Options

```java
// Programmatic
new VoidWorldGenProvider(tintColor, "EnvironmentName");

// JSON config
{
  "WorldGen": "Void",
  "WorldGenSettings": {
    "Tint": "#RRGGBB",           // Optional: chunk tint color
    "Environment": "Default"      // Optional: environment preset
  }
}
```

### FlatWorldGenProvider Options

```java
// JSON config
{
  "WorldGen": "Flat",
  "WorldGenSettings": {
    "Layers": [
      {"Block": "hytale:bedrock", "Height": 1},
      {"Block": "hytale:stone", "Height": 3},
      {"Block": "hytale:grass", "Height": 1}
    ]
  }
}
```

## Player in World

### Redirecting Player on Connect

```java
// Intercept player connection and set spawn world
getEventRegistry().registerGlobal(PlayerConnectEvent.class, event -> {
    World targetWorld = Universe.get().getWorld("myworld");
    event.setWorld(targetWorld);  // Player spawns in this world
});
```

### Adding Player to World (programmatic)

```java
// Add player to world with optional spawn position
world.addPlayer(playerRef, null)                    // default spawn
    .thenAccept(ref -> { /* player added */ });

world.addPlayer(playerRef, transform)               // specific position
    .thenAccept(ref -> { /* player added */ });

// Reset player (move between worlds with fresh state)
Universe.get().resetPlayer(playerRef, holder, targetWorld, transform);
```

### Teleporting Player Within World

```java
// Within world thread
world.execute(() -> {
    TransformComponent transform = store.getComponent(ref, TransformComponent.getComponentType());
    transform.getPosition().assign(x, y, z);
    // Or use Player.moveTo()
});
```

### Getting Players in World

```java
// On world thread
world.getEntityStore().getStore().forEach(Player.getComponentType(), (ref, player) -> {
    PlayerRef playerRef = store.getComponent(ref, PlayerRef.getComponentType());
    playerRef.sendMessage(Message.text("Hello!"));
});
```

## Events

### World Lifecycle Events

```java
// World being added to universe (can be cancelled)
getEventRegistry().registerGlobal(AddWorldEvent.class, event -> {
    World world = event.getWorld();
    // event.setCancelled(true) to prevent
});

// World being removed from universe
getEventRegistry().registerGlobal(RemoveWorldEvent.class, event -> {
    World world = event.getWorld();
    RemoveWorldEvent.RemovalReason reason = event.getReason();  // GENERAL or EXCEPTIONAL
});

// All worlds finished loading on startup
getEventRegistry().registerGlobal(AllWorldsLoadedEvent.class, event -> {
    // Safe to access all worlds
});
```

### Player World Events

```java
// Player added to world
getEventRegistry().registerGlobal(AddPlayerToWorldEvent.class, event -> {
    Ref<EntityStore> ref = event.getRef();
    World world = event.getWorld();
});

// Player leaving world
getEventRegistry().registerGlobal(DrainPlayerFromWorldEvent.class, event -> {
    // Cleanup
});
```

## Utilities

### SpawnUtil

Find safe spawn locations:

```java
Transform spawn = SpawnUtil.findSafeSpawn(world, x, y, z);
```

### BlockUtil / ChunkUtil

Coordinate conversions:

```java
// Block to chunk coords
int chunkX = ChunkUtil.toChunkCoord(blockX);

// Chunk to block coords
int blockX = ChunkUtil.toBlockCoord(chunkX);
```

## See Also

- [Entity System](entity.md) - Entities in worlds
- [Event System](event.md) - World-related events
- [ECS System](component.md) - EntityStore and ChunkStore
