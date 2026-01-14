# Hytale UI System - Complete Guide

Package: `com.hypixel.hytale.server.core.entity.entities.player.pages`

## Overview

Hytale использует **собственный проприетарный UI фреймворк** (не ImGui, Qt или веб-технологии). Ключевые особенности:

- **Кастомный формат `.ui`** - декларативный текстовый формат (не XML/JSON)
- **BSON-транспорт** - эффективная сериализация для сети
- **Клиент-серверная архитектура** - сервер строит UI определения, клиент рендерит
- **Asset-based загрузка** - UI файлы загружаются из asset pack

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SERVER SIDE                          │
├─────────────────────────────────────────────────────────────┤
│  Plugin                                                     │
│    └── CustomUIPage.build()                                 │
│          ├── UICommandBuilder (структура UI)                │
│          └── UIEventBuilder (привязка событий)              │
│                    ↓                                        │
│          CustomPage packet (BSON)                           │
└─────────────────────────────────────────────────────────────┘
                         ↓ Network
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT SIDE                          │
├─────────────────────────────────────────────────────────────┤
│  Парсит .ui файлы → Рендерит UI                            │
│  User interaction → CustomPageEvent packet                  │
└─────────────────────────────────────────────────────────────┘
                         ↓ Network
┌─────────────────────────────────────────────────────────────┐
│  PageManager.handleEvent()                                  │
│    └── page.handleDataEvent(ref, store, typedData)         │
└─────────────────────────────────────────────────────────────┘
```

## Core Classes

| Class | Purpose |
|-------|---------|
| `CustomUIPage` | Базовый класс для кастомного UI |
| `InteractiveCustomUIPage<T>` | С типизированной обработкой событий |
| `UICommandBuilder` | Построение/модификация UI структуры |
| `UIEventBuilder` | Привязка событий к UI элементам |
| `PageManager` | Открытие/закрытие страниц |

---

## Asset Pack Structure

**КРИТИЧНО:** UI файлы должны быть в специфической структуре директорий:

```
src/main/resources/
├── manifest.json                           # "IncludesAssetPack": true (с 's'!)
└── Common/
    └── UI/
        └── Custom/
            └── Pages/
                └── PluginName_PageName.ui  # UI файл
```

### manifest.json

```json
{
  "Group": "com.example",
  "Name": "MyPlugin",
  "Version": "1.0.0",
  "Description": "Plugin description",
  "Main": "com.example.myplugin.MyPlugin",
  "Authors": [{ "Name": "Developer" }],
  "ServerVersion": "*",
  "IncludesAssetPack": true
}
```

**Частая ошибка:** `"IncludeAssetPack"` (без 's') - вызовет ошибку "Could not find document"!

---

## UI File Format (.ui)

### Basic Structure

```
$C = "../Common.ui";

$C.@PageOverlay {}

$C.@DecoratedContainer {
  Anchor: (Width: 400, Height: 300);

  #Title {
    Group {
      $C.@Title {
        @Text = "Page Title";
      }
    }
  }

  #Content {
    LayoutMode: Top;
    Padding: (Full: 20);

    Label #MyLabel {
      Text: "Hello World";
      Style: (FontSize: 18, Alignment: Center, TextColor: #ffffff);
    }

    Group #ButtonContainer {
      LayoutMode: Left;
      Gap: 10;

      $C.@Button #SaveButton {
        @Text = "Save";
      }

      $C.@Button #CancelButton {
        @Text = "Cancel";
      }
    }
  }
}

$C.@BackButton #CloseButton {}
```

### Syntax Reference

| Syntax | Description | Example |
|--------|-------------|---------|
| `$C = "../Common.ui"` | Импорт Common.ui | Обязательно в начале |
| `$C.@ComponentName` | Использовать компонент | `$C.@PageOverlay {}` |
| `@Param = "value"` | Параметр шаблона | `@Text = "Hello";` |
| `#ElementId` | ID элемента (как CSS) | `Label #MyLabel {}` |
| `ElementType {}` | Объявление элемента | `Group {}`, `Label {}` |
| `Property: value;` | Установка свойства | `Text: "Hello";` |
| `Property: (...)` | Составное свойство | `Anchor: (Width: 100);` |

### Element Types

| Element | Description |
|---------|-------------|
| `Group` | Контейнер для других элементов |
| `Label` | Текстовый элемент |
| `Panel` | Панель (аналог Group) |
| `Image` | Изображение |
| `Button` | Кнопка (обычно через `$C.@Button`) |

### Built-in Components (Common.ui)

| Component | Description | Parameters |
|-----------|-------------|------------|
| `$C.@PageOverlay` | Полупрозрачный оверлей фона | - |
| `$C.@DecoratedContainer` | Стандартный контейнер с рамкой | Слоты: `#Title`, `#Content` |
| `$C.@Title` | Стилизованный заголовок | `@Text` |
| `$C.@BackButton` | Кнопка закрытия/назад | - |
| `$C.@Button` | Интерактивная кнопка | `@Text` |
| `$C.@TextInput` | Поле ввода текста | - |

---

## Styling System

### Anchor (Position & Size)

```
Anchor: (
  Width: 400,           // Абсолютная ширина
  Height: 200,          // Абсолютная высота
  MinWidth: 100,        // Минимальная ширина
  MaxWidth: 600,        // Максимальная ширина
  Left: 10,             // Отступ слева
  Right: 10,            // Отступ справа
  Top: 10,              // Отступ сверху
  Bottom: 10            // Отступ снизу
);
```

### Style (Text Styling)

```
Style: (
  FontSize: 18,              // Размер шрифта
  TextColor: #ffffff,        // Цвет текста (hex)
  Alignment: Center,         // Выравнивание: Left, Center, Right
  FontWeight: Bold           // Жирность
);
```

### Padding

```
Padding: (
  Full: 20,             // Все стороны
  Horizontal: 10,       // Лево + право
  Vertical: 5,          // Верх + низ
  Left: 10,
  Right: 10,
  Top: 5,
  Bottom: 5
);
```

### Layout

```
LayoutMode: Top;        // Вертикальный сверху вниз
LayoutMode: Bottom;     // Вертикальный снизу вверх
LayoutMode: Left;       // Горизонтальный слева направо
LayoutMode: Right;      // Горизонтальный справа налево

Gap: 10;                // Отступ между элементами
```

### Common Mistakes

```
// НЕПРАВИЛЬНО - Center не валидное поле Anchor
Anchor: (Width: 400, Height: 200, Center: true);

// ПРАВИЛЬНО
Anchor: (Width: 400, Height: 200);

// НЕПРАВИЛЬНО - HorizontalAlignment как отдельное свойство
HorizontalAlignment: Center;

// ПРАВИЛЬНО - использовать Style
Style: (Alignment: Center);
```

---

## Java Implementation

### Basic Page (No Events)

```java
public class InfoPage extends CustomUIPage {

    public InfoPage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.CanDismiss);
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder cmd,
                     UIEventBuilder events, Store<EntityStore> store) {
        cmd.append("Pages/MyPlugin_Info.ui");
        cmd.set("#Title.Text", "Welcome!");
        cmd.set("#Description.Text", "This is my plugin.");
    }
}
```

### Interactive Page (With Events)

```java
public class MyPage extends InteractiveCustomUIPage<MyPage.EventData> {
    private static final String LAYOUT = "Pages/MyPlugin_Page.ui";

    public MyPage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.CanDismiss, EventData.CODEC);
    }

    @Override
    public void build(@Nonnull Ref<EntityStore> ref, @Nonnull UICommandBuilder cmd,
                      @Nonnull UIEventBuilder events, @Nonnull Store<EntityStore> store) {
        cmd.append(LAYOUT);

        // Привязка событий
        events.addEventBinding(CustomUIEventBindingType.Activating, "#SaveButton",
            new EventData().append("Action", "Save"));
        events.addEventBinding(CustomUIEventBindingType.Activating, "#CancelButton",
            new EventData().append("Action", "Cancel"));
        events.addEventBinding(CustomUIEventBindingType.Activating, "#CloseButton");
    }

    @Override
    public void handleDataEvent(@Nonnull Ref<EntityStore> ref, @Nonnull Store<EntityStore> store,
                                @Nonnull EventData data) {
        Player player = store.getComponent(ref, Player.getComponentType());
        if (player == null) return;

        switch (data.action != null ? data.action : "") {
            case "Save":
                // Логика сохранения
                player.sendMessage(Message.raw("Saved!"));
                break;
            case "Cancel":
            default:
                // Закрыть страницу
                player.getPageManager().setPage(ref, store, Page.None);
                break;
        }
    }

    public static class EventData {
        public static final BuilderCodec<EventData> CODEC = BuilderCodec
            .builder(EventData.class, EventData::new)
            .append(new KeyedCodec<>("Action", Codec.STRING),
                (d, v) -> d.action = v, d -> d.action).add()
            .build();

        public String action;
    }
}
```

---

## UICommandBuilder Reference

### Command Types

| Method | Description |
|--------|-------------|
| `append(path)` | Добавить UI из файла в корень |
| `append(selector, path)` | Добавить UI в элемент |
| `appendInline(selector, ui)` | Добавить inline UI |
| `insertBefore(selector, path)` | Вставить перед элементом |
| `set(selector, value)` | Установить свойство |
| `remove(selector)` | Удалить элемент |
| `clear(selector)` | Очистить дочерние элементы |

### Selectors

```java
"#ElementId"              // По ID
"#Parent #Child"          // Вложенный
"#List[0]"                // Первый элемент списка
"#List[0] #Button"        // Кнопка в первом элементе
"#Element.Property"       // Свойство элемента
```

### Setting Values

```java
// Текст
cmd.set("#Label.Text", "Hello");
cmd.set("#Label.Text", Message.translation("i18n.key"));

// Числа
cmd.set("#Progress.Value", 0.5f);
cmd.set("#Counter.Text", 42);

// Boolean
cmd.set("#Button.Visible", true);
cmd.set("#Button.Disabled", false);

// Сложные типы
cmd.set("#Slot", new ItemGridSlot(itemStack));
cmd.set("#Container.Anchor", anchor);
```

### Built-in Codecs

UICommandBuilder поддерживает эти типы для `set()`:

- `Area` - прямоугольник
- `ItemGridSlot` - слот инвентаря
- `ItemStack` - стак предметов
- `LocalizableString` - локализованная строка
- `PatchStyle` - стиль текстуры
- `DropdownEntryInfo` - элемент выпадающего списка
- `Anchor` - позиция и размер

---

## Event System

### Event Types (24 типа)

#### Basic Interaction
| Event | Description |
|-------|-------------|
| `Activating` | Клик/тап/enter |
| `RightClicking` | Правый клик |
| `DoubleClicking` | Двойной клик |
| `MouseButtonReleased` | Отпускание кнопки мыши |

#### Hover Events
| Event | Description |
|-------|-------------|
| `MouseEntered` | Наведение курсора |
| `MouseExited` | Уход курсора |

#### Input Events
| Event | Description |
|-------|-------------|
| `ValueChanged` | Изменение значения (input) |
| `FocusGained` | Получение фокуса |
| `FocusLost` | Потеря фокуса |
| `KeyDown` | Нажатие клавиши |
| `Validating` | Валидация ввода |

#### Container Events
| Event | Description |
|-------|-------------|
| `ElementReordered` | Перестановка элемента |
| `SelectedTabChanged` | Смена вкладки |

#### Inventory Slot Events
| Event | Description |
|-------|-------------|
| `SlotClicking` | Клик по слоту |
| `SlotDoubleClicking` | Двойной клик по слоту |
| `SlotMouseEntered` | Наведение на слот |
| `SlotMouseExited` | Уход со слота |
| `SlotMouseDragCompleted` | Завершение перетаскивания |
| `SlotMouseDragExited` | Отмена перетаскивания |
| `SlotClickReleaseWhileDragging` | Отпускание при перетаскивании |
| `SlotClickPressWhileDragging` | Нажатие при перетаскивании |
| `DragCancelled` | Отмена drag |
| `Dropped` | Предмет брошен |

#### Page Events
| Event | Description |
|-------|-------------|
| `Dismissing` | Закрытие страницы |

### Event Binding Examples

```java
// Простое событие (блокирует UI)
events.addEventBinding(CustomUIEventBindingType.Activating, "#Button");

// С данными события
events.addEventBinding(
    CustomUIEventBindingType.Activating,
    "#Button",
    new EventData()
        .append("Action", "DoSomething")
        .append("ItemId", "123")
);

// Неблокирующее (UI остаётся отзывчивым)
events.addEventBinding(
    CustomUIEventBindingType.ValueChanged,
    "#SearchInput",
    new EventData().append("Action", "Search"),
    false  // locksInterface = false
);
```

---

## Event Data Codec

### Simple Codec

```java
public static class EventData {
    public static final BuilderCodec<EventData> CODEC =
        BuilderCodec.builder(EventData.class, EventData::new).build();
}
```

### With Fields

```java
public static class SearchEventData {
    public static final BuilderCodec<SearchEventData> CODEC = BuilderCodec
        .builder(SearchEventData.class, SearchEventData::new)
        .append(new KeyedCodec<>("Action", Codec.STRING),
            (d, v) -> d.action = v, d -> d.action).add()
        .append(new KeyedCodec<>("Query", Codec.STRING),
            (d, v) -> d.query = v, d -> d.query).add()
        .append(new KeyedCodec<>("PageIndex", Codec.INT),
            (d, v) -> d.pageIndex = v, d -> d.pageIndex).add()
        .build();

    public String action;
    public String query;
    public int pageIndex;
}
```

---

## Page Lifetime

```java
CustomPageLifetime.CantClose                      // Нельзя закрыть
CustomPageLifetime.CanDismiss                     // ESC для закрытия
CustomPageLifetime.CanDismissOrCloseThroughInteraction  // ESC или взаимодействие
```

---

## Page Updates

### Full Rebuild

```java
// Полностью пересобрать UI (вызывает build() заново)
rebuild();
```

### Partial Update

```java
// Отправить только изменения
UICommandBuilder cmd = new UICommandBuilder();
cmd.set("#Counter.Text", newValue);
cmd.set("#Progress.Value", 0.75f);
sendUpdate(cmd);
```

### Update with Clear

```java
UICommandBuilder cmd = new UICommandBuilder();
cmd.clear("#ItemList");
// ... добавить новые элементы ...
sendUpdate(cmd, true);  // clear = true
```

---

## Opening/Closing Pages

### From ECS System

```java
public class MySystem extends EntityEventSystem<EntityStore, MyEvent> {
    @Override
    public void handle(int index, ArchetypeChunk<EntityStore> chunk,
                       Store<EntityStore> store, CommandBuffer<EntityStore> buf,
                       MyEvent event) {
        var ref = chunk.getReferenceTo(index);
        Player player = chunk.getComponent(index, Player.getComponentType());
        PlayerRef playerRef = chunk.getComponent(index, PlayerRef.getComponentType());

        if (player != null && playerRef != null) {
            player.getPageManager().openCustomPage(ref, store, new MyPage(playerRef));
        }
    }
}
```

### From Command

```java
public class OpenGuiCommand extends AbstractPlayerCommand {
    public OpenGuiCommand() {
        super("mygui", "Opens my GUI");
    }

    @Override
    protected void execute(CommandContext ctx, Store<EntityStore> store,
                          Ref<EntityStore> ref, PlayerRef playerRef, World world) {
        Player player = store.getComponent(ref, Player.getComponentType());
        player.getPageManager().openCustomPage(ref, store, new MyPage(playerRef));
    }
}
```

### Closing Page

```java
Player player = store.getComponent(ref, Player.getComponentType());
player.getPageManager().setPage(ref, store, Page.None);
```

---

## Advanced Patterns

### Dynamic List Rendering

```java
@Override
public void build(Ref<EntityStore> ref, UICommandBuilder cmd,
                  UIEventBuilder events, Store<EntityStore> store) {
    cmd.append("Pages/MyPlugin_List.ui");

    List<Item> items = getItems();
    for (int i = 0; i < items.size(); i++) {
        Item item = items.get(i);
        String selector = "#ItemList[" + i + "] ";

        cmd.append("#ItemList", "Pages/MyPlugin_ItemCard.ui");
        cmd.set(selector + "#Name.Text", item.getName());
        cmd.set(selector + "#Icon.AssetPath", item.getIcon());

        events.addEventBinding(
            CustomUIEventBindingType.Activating,
            selector + "#Button",
            new EventData()
                .append("Action", "SelectItem")
                .append("ItemId", item.getId())
        );
    }
}
```

### Search with Rebuild

```java
private String searchQuery = "";

@Override
public void build(Ref<EntityStore> ref, UICommandBuilder cmd,
                  UIEventBuilder events, Store<EntityStore> store) {
    cmd.append("Pages/MyPlugin_Search.ui");

    // Неблокирующее событие для поиска
    events.addEventBinding(
        CustomUIEventBindingType.ValueChanged,
        "#SearchInput",
        new EventData().append("Action", "Search"),
        false
    );

    // Фильтрация по запросу
    List<Item> filtered = items.stream()
        .filter(i -> i.getName().contains(searchQuery))
        .toList();

    // Рендер результатов...
}

@Override
public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store,
                           EventData data) {
    if ("Search".equals(data.action)) {
        this.searchQuery = data.query != null ? data.query : "";
        rebuild();  // Пересобрать с новым фильтром
    }
}
```

### Tabs

```java
events.addEventBinding(
    CustomUIEventBindingType.SelectedTabChanged,
    "#TabContainer"
);
```

---

## Complete Working Example

### UI File: `TheSuperWorld_Reward.ui`

```
$C = "../Common.ui";

$C.@PageOverlay {}

$C.@DecoratedContainer {
  Anchor: (Width: 400, Height: 200);

  #Title {
    Group {
      $C.@Title {
        @Text = "Congratulations!";
      }
    }
  }

  #Content {
    LayoutMode: Top;
    Padding: (Full: 20);

    Label #Description {
      Text: "You broke the reward block!";
      Style: (FontSize: 18, Alignment: Center, TextColor: #ffffff);
    }
  }
}

$C.@BackButton #CloseButton {}
```

### Java: `RewardPage.java`

```java
package com.endoworlds.thesuperworld;

import com.hypixel.hytale.codec.builder.BuilderCodec;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.protocol.packets.interface_.CustomPageLifetime;
import com.hypixel.hytale.protocol.packets.interface_.CustomUIEventBindingType;
import com.hypixel.hytale.protocol.packets.interface_.Page;
import com.hypixel.hytale.server.core.entity.entities.Player;
import com.hypixel.hytale.server.core.entity.entities.player.pages.InteractiveCustomUIPage;
import com.hypixel.hytale.server.core.ui.builder.UICommandBuilder;
import com.hypixel.hytale.server.core.ui.builder.UIEventBuilder;
import com.hypixel.hytale.server.core.universe.PlayerRef;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

import javax.annotation.Nonnull;

public class RewardPage extends InteractiveCustomUIPage<RewardPage.EventData> {
    private static final String LAYOUT = "Pages/TheSuperWorld_Reward.ui";

    public RewardPage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.CanDismiss, EventData.CODEC);
    }

    @Override
    public void build(@Nonnull Ref<EntityStore> ref, @Nonnull UICommandBuilder cmd,
                      @Nonnull UIEventBuilder events, @Nonnull Store<EntityStore> store) {
        cmd.append(LAYOUT);
        events.addEventBinding(CustomUIEventBindingType.Activating, "#CloseButton");
    }

    @Override
    public void handleDataEvent(@Nonnull Ref<EntityStore> ref, @Nonnull Store<EntityStore> store,
                                @Nonnull EventData data) {
        Player player = store.getComponent(ref, Player.getComponentType());
        if (player != null) {
            player.getPageManager().setPage(ref, store, Page.None);
        }
    }

    public static class EventData {
        public static final BuilderCodec<EventData> CODEC =
            BuilderCodec.builder(EventData.class, EventData::new).build();
    }
}
```

---

## Troubleshooting

### "Could not find document Pages/..."

1. Проверьте `manifest.json` имеет `"IncludesAssetPack": true` (с 's'!)
2. Проверьте структуру: `src/main/resources/Common/UI/Custom/Pages/`
3. Имя файла должно соответствовать пути в коде

### "Could not find field X in type Y"

Ошибка синтаксиса UI:
- `Center: true` в Anchor - не валидно
- `HorizontalAlignment` как свойство - не валидно
- Используйте компоненты из Common.ui

### "Index was outside the bounds of the array"

Обычно вызвано неправильным inline UI или malformed .ui синтаксисом.

### UI не обновляется

- Убедитесь что вызываете `rebuild()` или `sendUpdate()`
- Проверьте что `locksInterface = false` для частых событий

---

## Best Practices

### Do's
- Используйте компоненты из `$C.@ComponentName`
- Используйте `locksInterface = false` для ValueChanged
- Используйте `rebuild()` для полных изменений
- Используйте `sendUpdate()` для частичных изменений
- Валидируйте event data перед обработкой
- Используйте `Message.translation()` для локализации

### Don'ts
- Не используйте сырые свойства типа `HorizontalAlignment: Center`
- Не используйте `Center: true` в Anchor
- Не забывайте `IncludesAssetPack: true` в manifest
- Не смешивайте `rebuild()` во время обработки события
- Не блокируйте обработчики событий

---

## External References

Примеры UI в плагинах сообщества:
- [Advanced-Item-Info](https://github.com/Buuz135/Advanced-Item-Info) - поиск предметов
- [AdminUI](https://github.com/Buuz135/AdminUI) - админ панель

---

## See Also

- [Plugin System](plugin.md) - регистрация команд
- [Command System](command.md) - создание команд
- [Entity System](entity.md) - доступ к Player и PageManager
- [ECS System](component.md) - EntityEventSystem для событий
