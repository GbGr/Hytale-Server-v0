# UI System (Pages & Windows)

Package: `com.hypixel.hytale.server.core.entity.entities.player.pages`

## Overview

Hytale's UI system allows plugins to create custom GUI pages that players can interact with. The system uses:
- **CustomUIPage** - Base class for custom UI
- **InteractiveCustomUIPage** - For pages with user input/events
- **UICommandBuilder** - Build/modify UI elements
- **UIEventBuilder** - Bind events to UI elements
- **PageManager** - Open/close pages for players

## Architecture

```
Player
  └── PageManager
        ├── openCustomPage(page)    // Open custom UI
        ├── setPage(page)           // Set built-in page
        └── updateCustomPage(page)  // Update existing UI

CustomUIPage (abstract)
  └── InteractiveCustomUIPage<T>   // With event handling
        └── YourCustomPage         // Your implementation
```

## Creating a Custom Page

### Basic Page (No Events)

```java
public class SimpleInfoPage extends CustomUIPage {

    public SimpleInfoPage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.CanDismiss);
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder cmd,
                     UIEventBuilder events, Store<EntityStore> store) {
        // Load UI template from assets
        cmd.append("Pages/MyPlugin/InfoPanel.ui");

        // Set text values
        cmd.set("#Title.Text", "Welcome!");
        cmd.set("#Description.Text", Message.translation("myplugin.info.description"));

        // Set visibility
        cmd.set("#CloseButton.Visible", true);

        // Set numeric values
        cmd.set("#ProgressBar.Value", 0.75f);
    }
}
```

### Interactive Page (With Events)

```java
public class SearchPage extends InteractiveCustomUIPage<SearchPageData> {
    private String searchQuery = "";

    public SearchPage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.CanDismiss, SearchPageData.CODEC);
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder cmd,
                     UIEventBuilder events, Store<EntityStore> store) {
        cmd.append("Pages/MyPlugin/SearchPanel.ui");

        // Build item list based on search
        List<Item> items = filterItems(searchQuery);
        for (int i = 0; i < items.size(); i++) {
            Item item = items.get(i);
            String selector = "#ItemList[" + i + "] ";

            cmd.append("#ItemList", "Pages/MyPlugin/ItemCard.ui");
            cmd.set(selector + "#Name.Text", item.getName());
            cmd.set(selector + "#Icon.AssetPath", item.getIconPath());

            // Bind click event with data
            events.addEventBinding(
                CustomUIEventBindingType.Activating,
                selector + "#Button",
                new EventData()
                    .append("Action", "SelectItem")
                    .append("ItemId", item.getId())
            );
        }

        // Bind search input change event
        events.addEventBinding(
            CustomUIEventBindingType.ValueChanged,
            "#SearchInput",
            new EventData().append("Action", "Search")
        );
    }

    @Override
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store,
                               SearchPageData data) {
        switch (data.action) {
            case "Search":
                this.searchQuery = data.searchQuery;
                rebuild();  // Rebuild entire UI
                break;
            case "SelectItem":
                handleItemSelected(data.itemId, ref, store);
                // Partial update (more efficient)
                UICommandBuilder cmd = new UICommandBuilder();
                cmd.set("#SelectedItem.Text", data.itemId);
                sendUpdate(cmd);
                break;
        }
    }

    // Event data class with Codec
    public static class SearchPageData {
        public static final BuilderCodec<SearchPageData> CODEC = BuilderCodec
            .builder(SearchPageData.class, SearchPageData::new)
            .append(new KeyedCodec<>("Action", Codec.STRING),
                (d, v) -> d.action = v, d -> d.action).add()
            .append(new KeyedCodec<>("SearchQuery", Codec.STRING),
                (d, v) -> d.searchQuery = v, d -> d.searchQuery).add()
            .append(new KeyedCodec<>("ItemId", Codec.STRING),
                (d, v) -> d.itemId = v, d -> d.itemId).add()
            .build();

        public String action;
        public String searchQuery;
        public String itemId;
    }
}
```

## Opening a Page

### From Command

```java
public class OpenGuiCommand extends AbstractPlayerCommand {
    public OpenGuiCommand() {
        super("opengui", "Opens the custom GUI");
    }

    @Override
    protected void execute(CommandContext ctx, Store<EntityStore> store,
                          Ref<EntityStore> ref, PlayerRef playerRef, World world) {
        Player player = store.getComponent(ref, Player.getComponentType());
        player.getPageManager().openCustomPage(ref, store,
            new SearchPage(playerRef));
    }
}
```

### From Event

```java
getEventRegistry().subscribe(PlayerInteractEvent.class, event -> {
    PlayerRef playerRef = event.getPlayerRef();
    Ref<EntityStore> ref = playerRef.getReference();
    Store<EntityStore> store = ref.getStore();
    Player player = store.getComponent(ref, Player.getComponentType());

    player.getPageManager().openCustomPage(ref, store,
        new MyCustomPage(playerRef));
});
```

## UICommandBuilder Methods

### Loading Templates

```java
cmd.append("Path/To/Template.ui");              // Append to root
cmd.append("#Container", "Path/To/Child.ui");   // Append to element
cmd.appendInline("#Container", "<ui>...</ui>"); // Inline UI XML
cmd.insertBefore("#Element", "Path.ui");        // Insert before element
```

### Setting Values

```java
// Text
cmd.set("#Element.Text", "Hello");
cmd.set("#Element.Text", Message.translation("key").param("name", value));

// Numbers
cmd.set("#Progress.Value", 0.5f);
cmd.set("#Count.Text", 42);

// Boolean
cmd.set("#Button.Visible", true);
cmd.set("#Button.Disabled", false);

// Null (reset/clear)
cmd.setNull("#Element.Background");

// Complex objects
cmd.setObject("#Element.Anchor", new Anchor());
cmd.set("#Grid.Items", itemStackArray);
cmd.set("#List.Items", itemList);
```

### Selectors

```java
"#ElementId"              // By ID
"#Parent #Child"          // Nested
"#List[0]"                // First item in list
"#List[0] #Button"        // Button in first list item
"#Element.Property"       // Element property
```

### Removing/Clearing

```java
cmd.remove("#Element");   // Remove element
cmd.clear("#Container");  // Clear children
```

## UIEventBuilder Methods

### Event Types

| Event | Description |
|-------|-------------|
| `Activating` | Click/tap/enter |
| `RightClicking` | Right click |
| `DoubleClicking` | Double click |
| `MouseEntered` | Hover start |
| `MouseExited` | Hover end |
| `ValueChanged` | Input changed |
| `FocusGained` | Element focused |
| `FocusLost` | Element unfocused |
| `KeyDown` | Key pressed |
| `Dismissing` | Page closing |
| `SlotClicking` | Inventory slot click |
| `SelectedTabChanged` | Tab changed |

### Binding Events

```java
// Simple event
events.addEventBinding(CustomUIEventBindingType.Activating, "#Button");

// With data
events.addEventBinding(
    CustomUIEventBindingType.Activating,
    "#Button",
    new EventData()
        .append("Action", "DoSomething")
        .append("Value", 123)
);

// Non-locking (doesn't freeze UI)
events.addEventBinding(
    CustomUIEventBindingType.ValueChanged,
    "#Input",
    new EventData().append("Action", "Search"),
    false  // locksInterface = false
);
```

## Page Lifetime

```java
CustomPageLifetime.CantClose                      // Cannot be closed
CustomPageLifetime.CanDismiss                     // ESC to close
CustomPageLifetime.CanDismissOrCloseThroughInteraction  // ESC or interaction
```

## Updating Pages

### Full Rebuild

```java
rebuild();  // Re-runs build() method
```

### Partial Update

```java
UICommandBuilder cmd = new UICommandBuilder();
cmd.set("#Counter.Text", newValue);
sendUpdate(cmd);  // Only sends changes
```

### Update with Clear

```java
UICommandBuilder cmd = new UICommandBuilder();
cmd.clear("#ItemList");
// ... rebuild list ...
sendUpdate(cmd, true);  // clear = true
```

## Real Example: Advanced-Item-Info

From [Advanced-Item-Info](https://github.com/Buuz135/Advanced-Item-Info) plugin:

```java
public class AdvancedItemInfoGui extends InteractiveCustomUIPage<SearchGuiData> {
    private String searchQuery = "";

    public AdvancedItemInfoGui(PlayerRef playerRef, CustomPageLifetime lifetime,
                               String defaultSearch) {
        super(playerRef, lifetime, SearchGuiData.CODEC);
        this.searchQuery = defaultSearch;
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder cmd,
                     UIEventBuilder events, Store<EntityStore> store) {
        cmd.append("Pages/AdvancedItemInfo/MainPanel.ui");

        // Filter items by search
        List<Item> items = Main.ITEMS.values().stream()
            .filter(item -> matchesSearch(item, searchQuery))
            .collect(Collectors.toList());

        // Build grid (7 items per row)
        int itemsPerRow = 7;
        for (int i = 0; i < items.size(); i++) {
            Item item = items.get(i);
            String selector = "#ItemGrid[" + i + "] ";

            cmd.append("#ItemGrid", "Pages/AdvancedItemInfo/ItemCard.ui");
            cmd.set(selector + "#ItemName.Text", item.getTranslationKey());
            cmd.set(selector + "#ItemIcon.Item", item.createStack());

            // Build tooltip with item properties
            Message tooltip = buildItemTooltip(item);
            cmd.set(selector + "#Button.TooltipTextSpans", tooltip);

            // Click event
            events.addEventBinding(
                CustomUIEventBindingType.Activating,
                selector + "#Button",
                new EventData()
                    .append("Action", "Select")
                    .append("ItemId", item.getId())
            );
        }

        // Search input binding
        events.addEventBinding(
            CustomUIEventBindingType.ValueChanged,
            "#SearchInput",
            new EventData().append("Action", "Search"),
            false
        );
    }

    @Override
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store,
                               SearchGuiData data) {
        if ("Search".equals(data.action)) {
            this.searchQuery = data.searchQuery != null ? data.searchQuery : "";
            rebuild();
        } else if ("Select".equals(data.action)) {
            // Handle item selection
        }
    }

    private Message buildItemTooltip(Item item) {
        return Message.raw("")
            .insert(Message.translation("ID: ").color("#888888"))
            .insert(item.getId())
            .insert("\n")
            .insert(Message.translation("Stack Size: ").color("#888888"))
            .insert(String.valueOf(item.getMaxStackSize()));
    }
}
```

## UI Templates (.ui files)

UI templates are XML files in your asset pack. Example structure:

```xml
<!-- Pages/MyPlugin/Panel.ui -->
<Panel Id="MainPanel" Width="800" Height="600">
    <Text Id="Title" Text="" FontSize="24" />
    <Panel Id="ItemList" Layout="Vertical" />
    <Button Id="CloseButton" Text="Close" />
</Panel>
```

Asset pack structure:
```
assets/
└── Pages/
    └── MyPlugin/
        ├── MainPanel.ui
        └── ItemCard.ui
```

Manifest must include `"IncludeAssetPack": true`.

## Best Practices

1. **Use partial updates** when possible (more efficient than rebuild)
2. **Store state in page class** (searchQuery, selectedItem, etc.)
3. **Create EventData class with Codec** for type-safe event handling
4. **Use selectors with indices** for list items: `#List[0] #Button`
5. **Use Message.translation()** for localized text
6. **Set `locksInterface = false`** for frequent events like search input

## See Also

- [Plugin System](plugin.md) - Registering commands to open pages
- [Command System](command.md) - Creating commands
- [Entity System](entity.md) - Player and PageManager access
