# World System (Universe)

Package: `com.hypixel.hytale.server.core.universe`

## Overview

The universe system manages worlds, chunks, blocks, and world generation. A server has one `Universe` containing multiple `World` instances.

## Core Classes

### Universe

Singleton managing all worlds and player data:

```java
Universe universe = Universe.get();

// Get worlds
World world = universe.getWorld("default");
Collection<World> worlds = universe.getWorlds();

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
    IWorldGen createWorldGen(World world);
}
```

### Built-in Generators

- `VoidWorldGenProvider` - Empty world
- `FlatWorldGenProvider` - Flat terrain with layers
- `DummyWorldGenProvider` - Minimal generation

```java
// In world config asset
{
  "WorldGen": "hytale:flat",
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

### Adding Player to World

```java
// Listen for player connect
getEventRegistry().subscribe(PlayerConnectEvent.class, event -> {
    World targetWorld = Universe.get().getWorld("default");
    event.setWorld(targetWorld);  // Set spawn world
});
```

### Teleporting Player

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

```java
// World events
getEventRegistry().subscribe(StartWorldEvent.class, event -> {
    World world = event.getWorld();
});

// Player in world events
getEventRegistry().subscribe(AddPlayerToWorldEvent.class, event -> {
    Ref<EntityStore> ref = event.getRef();
    World world = event.getWorld();
});

getEventRegistry().subscribe(DrainPlayerFromWorldEvent.class, event -> {
    // Player leaving world
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
