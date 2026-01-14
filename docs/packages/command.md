# Command System

Package: `com.hypixel.hytale.server.core.command.system`

## Overview

Commands allow players and console to execute actions on the server. The system supports subcommands, required/optional arguments, permissions, and auto-completion.

## Base Command Classes

| Class | Use Case |
|-------|----------|
| `AbstractCommand` | Base class for all commands |
| `AbstractPlayerCommand` | Commands that require a player sender |
| `AbstractWorldCommand` | Commands that require a world context |
| `AbstractTargetPlayerCommand` | Commands targeting another player |
| `AbstractTargetEntityCommand` | Commands targeting an entity |
| `AbstractAsyncCommand` | Async command execution |
| `AbstractCommandCollection` | Group of subcommands |

## Creating a Command

### Simple Player Command

```java
import com.hypixel.hytale.server.core.command.system.CommandContext;
import com.hypixel.hytale.server.core.command.system.basecommands.AbstractPlayerCommand;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.server.core.universe.PlayerRef;
import com.hypixel.hytale.server.core.universe.world.World;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

public class MyCommand extends AbstractPlayerCommand {

    public MyCommand() {
        super("mycommand", "server.commands.mycommand.description");
        // Permission auto-generated as "plugingroup.pluginname.command.mycommand"
    }

    @Override
    protected void execute(CommandContext context, Store<EntityStore> store,
                          Ref<EntityStore> ref, PlayerRef playerRef, World world) {
        playerRef.sendMessage(Message.text("Hello from MyCommand!"));
    }
}
```

### Command with Arguments

```java
import com.hypixel.hytale.server.core.command.system.arguments.system.RequiredArg;
import com.hypixel.hytale.server.core.command.system.arguments.system.DefaultArg;
import com.hypixel.hytale.server.core.command.system.arguments.system.OptionalArg;
import com.hypixel.hytale.server.core.command.system.arguments.system.FlagArg;
import com.hypixel.hytale.server.core.command.system.arguments.types.ArgTypes;

public class GiveCommand extends AbstractPlayerCommand {
    // Required argument
    private final RequiredArg<ItemType> itemArg;
    // Optional with default
    private final DefaultArg<Integer> amountArg;
    // Optional flag
    private final FlagArg silentFlag;

    public GiveCommand() {
        super("give", "server.commands.give.description");

        // Required: /give <item>
        this.itemArg = withRequiredArg("item",
            "server.commands.give.arg.item",
            ArgTypes.ITEM_TYPE);

        // Default: /give <item> --amount 1
        this.amountArg = withDefaultArg("amount",
            "server.commands.give.arg.amount",
            ArgTypes.INTEGER, 1, "1");

        // Flag: /give <item> --silent
        this.silentFlag = withFlagArg("silent",
            "server.commands.give.arg.silent");
    }

    @Override
    protected void execute(CommandContext context, Store<EntityStore> store,
                          Ref<EntityStore> ref, PlayerRef playerRef, World world) {
        ItemType item = context.get(itemArg);
        int amount = context.get(amountArg);
        boolean silent = context.get(silentFlag);

        // Give item to player
        if (!silent) {
            playerRef.sendMessage(Message.text("Gave " + amount + " " + item));
        }
    }
}
```

### Command with Subcommands

```java
public class AdminCommand extends AbstractCommandCollection {

    public AdminCommand() {
        super("admin", "server.commands.admin.description");

        // Add subcommands
        addSubCommand(new BanSubCommand());
        addSubCommand(new KickSubCommand());
        addSubCommand(new MuteSubCommand());
    }

    // /admin ban <player>
    private class BanSubCommand extends AbstractTargetPlayerCommand {
        public BanSubCommand() {
            super("ban", "server.commands.admin.ban.description");
        }

        @Override
        protected void execute(CommandContext context, PlayerRef target) {
            // Ban logic
        }
    }
}
```

## Registering Commands

In your plugin's `setup()` method:

```java
@Override
protected void setup() {
    // Register single command
    getCommandRegistry().register(new MyCommand());

    // Register command collection
    getCommandRegistry().register(new AdminCommand());
}
```

## Argument Types (ArgTypes)

Common built-in argument types:

| Type | Description | Example |
|------|-------------|---------|
| `ArgTypes.STRING` | Any string | `hello` |
| `ArgTypes.INTEGER` | Integer number | `42` |
| `ArgTypes.FLOAT` | Decimal number | `3.14` |
| `ArgTypes.BOOLEAN` | true/false | `true` |
| `ArgTypes.PLAYER` | Online player | `Steve` |
| `ArgTypes.WORLD` | World name | `overworld` |
| `ArgTypes.VECTOR3I` | Block position | `100 64 -200` |
| `ArgTypes.VECTOR3D` | Precise position | `100.5 64.0 -200.5` |
| `ArgTypes.ITEM_TYPE` | Item type | `stone` |
| `ArgTypes.BLOCK_TYPE` | Block type | `dirt` |
| `ArgTypes.ENTITY_TYPE` | Entity type | `zombie` |
| `ArgTypes.DURATION` | Time duration | `5m`, `1h30m` |
| `ArgTypes.UUID` | UUID | `550e8400-e29b-41d4-...` |

## Argument Variants

### Required Arguments

```java
// Single value
RequiredArg<String> name = withRequiredArg("name", "desc", ArgTypes.STRING);

// List of values
RequiredArg<List<String>> names = withListRequiredArg("names", "desc", ArgTypes.STRING);
```

### Optional Arguments

```java
// Optional (may be absent)
OptionalArg<Integer> count = withOptionalArg("count", "desc", ArgTypes.INTEGER);

// With default value
DefaultArg<Integer> count = withDefaultArg("count", "desc",
    ArgTypes.INTEGER, 10, "10");

// Flag (boolean, present = true)
FlagArg verbose = withFlagArg("verbose", "desc");
```

## CommandContext

Access parsed arguments and sender info:

```java
@Override
protected void execute(CommandContext context, ...) {
    // Get required argument
    String name = context.get(nameArg);

    // Get optional (may be null)
    Integer count = context.get(countArg);

    // Get with default
    int amount = context.get(amountArg); // Never null if has default

    // Check flag
    boolean isVerbose = context.get(verboseFlag);

    // Sender info
    CommandSender sender = context.sender();
    sender.sendMessage(Message.text("Done!"));

    // Player ref (if AbstractPlayerCommand)
    Ref<EntityStore> playerRef = context.senderAsPlayerRef();
}
```

## Permissions

Permissions are auto-generated based on plugin and command name:

```
{group}.{pluginname}.command.{commandname}
{group}.{pluginname}.command.{commandname}.{subcommand}
```

Override with custom permission:

```java
public MyCommand() {
    super("mycommand", "description");
    requirePermission("custom.permission.node");
}
```

Per-argument permissions:

```java
OptionalArg<Integer> adminArg = withOptionalArg("admin", "desc", ArgTypes.INTEGER);
adminArg.requirePermission("mycommand.admin");
```

## Command Aliases

```java
public MyCommand() {
    super("mycommand", "description");
    addAliases("mc", "mycmd");
}
// Now works: /mycommand, /mc, /mycmd
```

## Confirmation Required

For dangerous commands:

```java
public DeleteCommand() {
    super("delete", "description", true); // requiresConfirmation = true
}
// User must add --confirm flag: /delete world --confirm
```

## Messages

Use translation keys for localization:

```java
// In command
context.sendMessage(Message.translation("server.commands.mycommand.success")
    .param("player", playerName));

// Translation file has: server.commands.mycommand.success = "Successfully did thing for {player}"
```

## Async Commands

Long-running commands should be async:

```java
public class AsyncCommand extends AbstractAsyncCommand {
    @Override
    protected CompletableFuture<Void> executeAsync(CommandContext context) {
        return CompletableFuture.runAsync(() -> {
            // Long operation
        });
    }
}
```

## See Also

- [Plugin System](plugin.md) - CommandRegistry access
- [Entity System](entity.md) - Player and CommandSender
