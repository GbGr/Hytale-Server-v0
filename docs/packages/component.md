# ECS (Entity Component System)

Package: `com.hypixel.hytale.component`

## Overview

Hytale uses an Entity Component System architecture for game objects. This provides:
- Data-oriented design for performance
- Composition over inheritance
- Flexible entity definitions
- Parallel system execution

## Core Concepts

### Components

Data containers attached to entities:

```java
// Components are plain data classes
public class Player extends LivingEntity implements Component<EntityStore> { }
public class TransformComponent implements Component<EntityStore> { }
public class Velocity implements Component<EntityStore> { }
```

### Component Types

Type-safe handles for components:

```java
// Get component type
ComponentType<EntityStore, Player> playerType = Player.getComponentType();
ComponentType<EntityStore, TransformComponent> transformType = TransformComponent.getComponentType();
```

### Ref (Reference)

Handle to an entity in a Store:

```java
Ref<EntityStore> ref;  // Entity reference

// Check validity
if (ref.isValid()) { }

// Get store
Store<EntityStore> store = ref.getStore();
```

### Holder

Temporary entity container (not in store):

```java
Holder<EntityStore> holder = EntityStore.REGISTRY.newHolder();
holder.addComponent(playerType, playerInstance);
holder.addComponent(transformType, transformInstance);

// Get component from holder
Player player = holder.getComponent(playerType);
```

### Store

Container for entities and their components:

```java
Store<EntityStore> store = world.getEntityStore().getStore();

// Get component from entity
Player player = store.getComponent(ref, Player.getComponentType());

// Check if entity has component
boolean hasPlayer = store.hasComponent(ref, Player.getComponentType());

// Add component
store.putComponent(ref, Invulnerable.getComponentType(), Invulnerable.INSTANCE);

// Remove component
store.tryRemoveComponent(ref, Invulnerable.getComponentType());
```

### ComponentAccessor

Interface for accessing components (Store implements this):

```java
void processEntity(Ref<EntityStore> ref, ComponentAccessor<EntityStore> accessor) {
    Player player = accessor.getComponent(ref, Player.getComponentType());
    TransformComponent transform = accessor.getComponent(ref, TransformComponent.getComponentType());

    if (player != null && transform != null) {
        // Do something
    }
}
```

## Systems

Systems process entities with specific components:

### System Types

| Type | Description |
|------|-------------|
| `ISystem` | Base system interface |
| `TickingSystem` | Runs every tick |
| `EntityTickingSystem` | Per-entity tick processing |
| `QuerySystem` | Processes entities matching query |
| `EntityEventSystem` | Handles entity-scoped events (BreakBlockEvent, etc.) |
| `WorldEventSystem` | Handles world-scoped events |
| `RefSystem` | Processes entity references |
| `HolderSystem` | Processes holders |

### EntityEventSystem (Real Example)

From [Lucky-Mining](https://github.com/Buuz135/Lucky-Mining) plugin - handling block break events:

```java
public class BreakBlockEventSystem implements EntityEventSystem<EntityStore, BreakBlockEvent> {

    @Override
    public EntityEventType<BreakBlockEvent> getEventType() {
        return BreakBlockEvent.EVENT;  // Subscribe to this event type
    }

    @Override
    public void accept(Store<EntityStore> store, Ref<EntityStore> ref,
                      ComponentAccessor<EntityStore> accessor, BreakBlockEvent event) {
        // Get world from store
        World world = store.getExternalData().getWorld();

        // Get event data
        BlockType blockType = event.getBlockType();
        Vector3i position = event.getTargetBlock();

        // Access entity components
        UUIDComponent uuid = accessor.getComponent(ref, UUIDComponent.getComponentType());
        Player player = accessor.getComponent(ref, Player.getComponentType());

        // Modify world
        world.setBlock(x, y, z, newBlockType);

        // Cancel event if needed
        event.setCancelled(true);
    }
}
```

Register in plugin setup:
```java
@Override
protected void setup() {
    getEntityStoreRegistry().register(new BreakBlockEventSystem());
}
```

### Queries

Filter entities by components:

```java
// Query for entities with Player AND TransformComponent
Query query = Query.builder()
    .with(Player.getComponentType())
    .with(TransformComponent.getComponentType())
    .build();

// Iterate matching entities
store.forEach(query, (ref, accessor) -> {
    Player player = accessor.getComponent(ref, Player.getComponentType());
    // Process
});
```

## EntityStore

Specialized store for game entities:

```java
EntityStore entityStore = world.getEntityStore();
Store<EntityStore> store = entityStore.getStore();

// Spawn entity from holder
Ref<EntityStore> ref = entityStore.spawnEntity(holder);

// Iterate all players
store.forEach(Player.getComponentType(), (ref, player) -> {
    // Process each player
});
```

## ChunkStore

Specialized store for chunk data:

```java
ChunkStore chunkStore = world.getChunkStore();
Store<ChunkStore> store = chunkStore.getStore();
```

## Working with ECS in Plugins

### In Event Handlers

```java
getEventRegistry().subscribe(BreakBlockEvent.class, event -> {
    // ECS events provide ComponentAccessor
    // Access components through the event context
});
```

### Registering Components

Plugins can register custom components:

```java
@Override
protected void setup() {
    // Register to EntityStore
    getEntityStoreRegistry().register(MyComponent.getComponentType());

    // Register to ChunkStore
    getChunkStoreRegistry().register(MyChunkComponent.getComponentType());
}
```

### Common Patterns

```java
// Get player from ref
void processPlayer(Ref<EntityStore> ref, ComponentAccessor<EntityStore> accessor) {
    Player player = accessor.getComponent(ref, Player.getComponentType());
    if (player == null) return;

    PlayerRef playerRef = accessor.getComponent(ref, PlayerRef.getComponentType());
    TransformComponent transform = accessor.getComponent(ref, TransformComponent.getComponentType());

    Vector3d position = transform.getPosition();
    playerRef.sendMessage(Message.text("You are at " + position));
}
```

## Built-in Component Types

### Entity Components

| Component | Description |
|-----------|-------------|
| `Player` | Player data |
| `PlayerRef` | Player connection info |
| `LivingEntity` | Living entity base |
| `Entity` | Base entity |
| `TransformComponent` | Position/rotation |
| `Velocity` | Movement velocity |
| `BoundingBox` | Collision bounds |
| `UUIDComponent` | Entity UUID |
| `MovementStatesComponent` | Flying, swimming, etc |
| `ChunkTracker` | Tracked chunks (player) |
| `Invulnerable` | Damage immunity |
| `RespondToHit` | Hit response |

### Getting Component Types

```java
// Static method on component class
ComponentType<EntityStore, Player> type = Player.getComponentType();

// Or through EntityModule
EntityModule.get().getComponentType(Player.class);
```

## Resources

Global data accessible to systems:

```java
// Time resource
TimeResource time = store.getResource(TimeResource.TYPE);

// World time
WorldTimeResource worldTime = store.getResource(WorldTimeResource.TYPE);
```

## See Also

- [Entity System](entity.md) - Entity and Player classes
- [World System](universe.md) - EntityStore and ChunkStore
- [Plugin System](plugin.md) - Registering components
