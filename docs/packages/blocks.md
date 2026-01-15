# Block System

Package: `com.hypixel.hytale.server.core.asset.type.blocktype.config`

## Overview

Block types define all blocks in Hytale. They are loaded dynamically from `Assets.zip` at runtime and cannot be listed statically. This document explains the block system architecture and how to work with blocks programmatically.

## Core Classes

### BlockType

The main class representing a block type:

```java
import com.hypixel.hytale.server.core.asset.type.blocktype.config.BlockType;

// Get block type by ID
BlockType stone = BlockType.getAssetMap().getAsset("Rock_Stone");
BlockType grass = BlockType.getAssetMap().getAsset("Grass_Zone1");

// Get block type by index
BlockType blockType = BlockType.getAssetMap().getAsset(blockTypeIndex);

// Get block ID/key
String blockId = blockType.getId();

// Check if block exists
boolean exists = BlockType.getAssetMap().containsKey("Rock_Stone");
```

### Getting All Block Types at Runtime

```java
import com.hypixel.hytale.assetstore.map.BlockTypeAssetMap;
import com.hypixel.hytale.server.core.asset.type.blocktype.config.BlockType;

// Get the asset map
BlockTypeAssetMap<String, BlockType> assetMap = BlockType.getAssetMap();

// Iterate all block types
assetMap.forEach((key, blockType) -> {
    String blockId = blockType.getId();
    // Process block type...
});

// Get total count
int totalBlocks = assetMap.size();
```

## Block Properties

### Basic Properties

```java
blockType.getId()                    // Block ID string (e.g., "Rock_Stone")
blockType.getItem()                  // Associated Item (for inventory)
blockType.getDrawType()              // Rendering type (Cube, Model, etc.)
blockType.getMaterial()              // Block material (Stone, Wood, etc.)
blockType.getOpacity()               // Opacity (Solid, Transparent, etc.)
blockType.isUnknown()                // Is this an unknown/invalid block
```

### Block Materials (BlockMaterial enum)

| Material | Description |
|----------|-------------|
| `Empty` | No material (air) |
| `Stone` | Stone-based blocks |
| `Wood` | Wood-based blocks |
| `Metal` | Metal blocks |
| `Glass` | Glass blocks |
| `Dirt` | Dirt/soil blocks |
| `Sand` | Sand blocks |
| `Plant` | Plant/vegetation |
| `Cloth` | Fabric/cloth |
| `Liquid` | Water, lava, etc. |

### Draw Types (DrawType enum)

| Type | Description |
|------|-------------|
| `Empty` | Invisible (air) |
| `Cube` | Standard cube block |
| `Model` | Custom 3D model |
| `Cross` | Cross/X shape (plants) |
| `Slab` | Half block |
| `Stair` | Stair shape |

## Block Drops (Gathering System)

Block drops are defined in the `BlockGathering` configuration.

### BlockGathering

```java
BlockGathering gathering = blockType.getGathering();
if (gathering != null) {
    // Check drop types
    boolean isSoft = gathering.isSoft();           // Can be broken by hand
    boolean isHarvestable = gathering.isHarvestable(); // Can be picked up

    // Get specific drop configurations
    BlockBreakingDropType breaking = gathering.getBreaking();
    SoftBlockDropType soft = gathering.getSoft();
    HarvestingDropType harvest = gathering.getHarvest();
    PhysicsDropType physics = gathering.getPhysics();
}
```

### Drop Type Hierarchy

| Drop Type | When Used | Description |
|-----------|-----------|-------------|
| `Breaking` | Tool breaks block | Drops when broken with correct tool |
| `Soft` | Hand breaks block | Drops when broken without tool |
| `Harvest` | Interaction pickup | Drops when harvested (e.g., crops) |
| `Physics` | Block falls/destroyed | Drops when destroyed by physics |

### Drop Configuration

Each drop type contains:

```java
// BlockBreakingDropType
breaking.getItemId()      // Specific item to drop (nullable)
breaking.getDropListId()  // Drop list for random drops (nullable)
breaking.getQuantity()    // Number of items to drop
breaking.getGatherType()  // Required tool type (e.g., "Pickaxe")

// SoftBlockDropType
soft.getItemId()          // Item to drop
soft.getDropListId()      // Drop list
soft.isWeaponBreakable()  // Can weapons break this?

// HarvestingDropType
harvest.getItemId()       // Item to drop
harvest.getDropListId()   // Drop list

// PhysicsDropType
physics.getItemId()       // Item to drop
physics.getDropListId()   // Drop list
```

### Drop Resolution

Drops are resolved in this order:
1. If `dropListId` is set -> Random items from drop list
2. If `itemId` is set -> Specific item
3. Otherwise -> Block's associated `Item` (blockType.getItem())

```java
// From BlockHarvestUtils.getDrops()
public static List<ItemStack> getDrops(BlockType blockType, int quantity,
                                        String itemId, String dropListId) {
    if (dropListId == null && itemId == null) {
        Item item = blockType.getItem();
        if (item == null) return empty;
        return new ItemStack(item.getId(), quantity);
    }
    // ... handle dropList and itemId
}
```

## Common Block ID Patterns

Based on observed usage in code:

### Terrain Blocks
- `Rock_Stone` - Stone
- `Rock_Cobblestone` - Cobblestone
- `Grass_Zone1` - Zone 1 grass
- `Dirt_Zone1` - Zone 1 dirt
- `Sand_Zone1` - Zone 1 sand

### Wood Blocks
- `Wood_Oak` - Oak wood
- `Wood_Birch` - Birch wood
- `Plank_Oak` - Oak planks

### Special Blocks
- `Empty` - Air/no block
- `Water` - Water
- `Lava` - Lava

## Working with Blocks in World

### Setting Blocks

```java
// Set block by ID
world.setBlock(x, y, z, "Rock_Stone");

// Set block with rotation
world.setBlock(x, y, z, blockType, rotation);

// Set block by index
worldChunk.setBlock(localX, localY, localZ, blockTypeIndex);
```

### Getting Blocks

```java
// Get block type at position
BlockType blockType = world.getBlockType(x, y, z);

// Get block index
int blockIndex = worldChunk.getBlock(localX, localY, localZ);

// Convert index to BlockType
BlockType blockType = BlockType.getAssetMap().getAsset(blockIndex);
```

## Plugin Example: Listing All Blocks

```java
public class BlockLister extends JavaPlugin {
    @Override
    protected void setup() {
        // Register command to list all blocks
        getCommandRegistry().register(new ListBlocksCommand());
    }
}

class ListBlocksCommand implements ICommand {
    @Override
    public void execute(CommandContext context) {
        BlockTypeAssetMap<String, BlockType> assetMap = BlockType.getAssetMap();

        StringBuilder sb = new StringBuilder();
        sb.append("Total blocks: ").append(assetMap.size()).append("\n");

        assetMap.forEach((key, blockType) -> {
            sb.append(key);

            // Add drop info
            BlockGathering gathering = blockType.getGathering();
            if (gathering != null) {
                BlockBreakingDropType breaking = gathering.getBreaking();
                if (breaking != null && breaking.getItemId() != null) {
                    sb.append(" -> ").append(breaking.getItemId());
                }
            }

            sb.append("\n");
        });

        // Log to console or send to player
        getLogger().info(sb.toString());
    }
}
```

## Plugin Example: Custom Block Drops

```java
// Intercept block break to modify drops
getEventRegistry().registerGlobal(BreakBlockEvent.class, event -> {
    BlockType blockType = event.getBlockType();

    if (blockType.getId().equals("Rock_Stone")) {
        // Custom logic for stone blocks
        // Note: actual drop modification requires more complex handling
    }
});
```

## Tool Types (GatherType)

Tools are matched to blocks via `GatherType`:

| GatherType | Tool | Blocks |
|------------|------|--------|
| `Pickaxe` | Pickaxes | Stone, ore, metal |
| `Axe` | Axes | Wood, planks |
| `Shovel` | Shovels | Dirt, sand, gravel |
| `Hoe` | Hoes | Farmland, crops |

```java
// Check if tool can break block efficiently
BlockBreakingDropType breaking = gathering.getBreaking();
String requiredTool = breaking.getGatherType(); // e.g., "Pickaxe"

// Tool spec defines efficiency
ItemToolSpec spec = BlockHarvestUtils.getSpecPowerDamageBlock(item, blockType, tool);
float power = spec != null ? spec.getPower() : 0.0f;
```

## See Also

- [Universe System](universe.md) - World and chunk management
- [Entity System](entity.md) - Entities and items
- [Event System](event.md) - Block-related events (BreakBlockEvent, DamageBlockEvent)
