# Skill: Flutter UI Agent — Dynamic Widget Loading via `ui_schema.json`

## Overview

This project is an AI-powered Flutter UI generation system. A Python agent (LangChain + Google Gemini) converts natural language UI descriptions into a JSON widget schema (`ui_schema.json`), which a Flutter runtime engine (`DynamicWidgetBuilder`) renders into live widgets — no recompilation needed.

```
User prompt → Python Agent → ui_schema.json → DynamicWidgetBuilder → Flutter UI
```

---

## Project Structure

| Path | Role |
|------|------|
| `flutter_ui_agent.py` | Python AI agent — generates JSON schemas from text descriptions |
| `lib/dynamic_widget_builder.dart` | Core engine — recursively builds Flutter widgets from JSON |
| `main.dart` | Demo app with hardcoded example schemas + drawer navigation |
| `ui_schema.json` | Generated schema file — the bridge between agent and app |
| `generated_widget.dart` | Auto-generated Dart code output (from Python agent) |
| `example_schemas.json` | Sample schema for reference |
| `pubspec.yaml` | Flutter dependencies (no external packages required) |
| `requirements.txt` | Python dependencies (langchain, pydantic, google-generativeai) |

---

## JSON Schema Format

Every widget node follows this recursive structure:

```json
{
  "type": "WidgetType",
  "properties": { ... },
  "children": [ ... ]
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `type` | `string` | Flutter widget name: `Container`, `Column`, `Row`, `Text`, `Card`, `ListView`, `Scaffold`, etc. |
| `properties` | `object` | Widget-specific props: `color`, `padding`, `fontSize`, `text`, `mainAxisAlignment`, etc. |
| `children` | `array` | Nested widget nodes (recursive). Empty array `[]` for leaf widgets. |

### Minimal Example

```json
{
  "type": "Container",
  "properties": { "padding": 16, "color": "white" },
  "children": [
    {
      "type": "Text",
      "properties": { "text": "Hello", "fontSize": 24, "fontWeight": "bold" },
      "children": []
    }
  ]
}
```

---

## Supported Widget Types

| Type | Key Properties |
|------|---------------|
| `Container` | `width`, `height`, `color`, `padding`, `margin`, `alignment`, `decoration` |
| `Column` | `mainAxisAlignment`, `crossAxisAlignment` |
| `Row` | `mainAxisAlignment`, `crossAxisAlignment` |
| `Text` | `text`, `fontSize`, `fontWeight`, `color`, `textAlign` |
| `ElevatedButton` / `Button` | `text`, `color`, `padding` |
| `Card` | `color`, `elevation`, `margin` |
| `Padding` | `padding` |
| `Center` | — |
| `Expanded` | `flex` |
| `ListView` | `padding` |
| `SizedBox` | `width`, `height` |
| `Stack` | — |
| `Image` | `url` (network) or `asset` (local) |
| `Icon` | `icon`, `size`, `color` |
| `TextField` | `label`, `hint`, `obscureText` |
| `Scaffold` | `backgroundColor`, `appBar` (nested), `body` (nested), `bottomNavigationBar` (nested) |

### Property Value Conventions

- **Colors**: Named strings — `red`, `blue`, `green`, `white`, `black`, `grey`, `orange`, `purple`, `pink`, `yellow`, `transparent`, or hex `#RRGGBB`
- **Padding/Margin**: Single number → `EdgeInsets.all(n)`
- **Alignment**: `center`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `centerLeft`, `centerRight`
- **MainAxisAlignment**: `start`, `end`, `center`, `spaceBetween`, `spaceAround`, `spaceEvenly`
- **CrossAxisAlignment**: `start`, `end`, `center`, `stretch`
- **FontWeight**: `bold`, `normal`, `light`
- **TextAlign**: `left`, `right`, `center`, `justify`
- **Icons**: `home`, `person`, `settings`, `star`, `favorite`, `search`, `menu`, `close`, `check` (defaults to `widgets`)

---

## How Dynamic Widget Loading Works

### 1. Generate the schema (Python agent)

```bash
export GOOGLE_API_KEY="your-key"
python flutter_ui_agent.py
```

The agent prompts for a UI description, calls Gemini, validates the output with Pydantic, and writes `ui_schema.json`.

### 2. Load and render in Flutter

```dart
import 'lib/dynamic_widget_builder.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// From a JSON file
final jsonString = await rootBundle.loadString('ui_schema.json');
final jsonData = json.decode(jsonString);
Widget widget = DynamicWidgetBuilder.fromJson(jsonData);

// From an inline Map
Widget widget = DynamicWidgetBuilder.fromJson({
  "type": "Text",
  "properties": {"text": "Dynamic!", "fontSize": 20},
  "children": []
});
```

### 3. The builder recursion

`DynamicWidgetBuilder.fromJson()` works recursively:

1. Reads `type` to determine which Flutter widget to create
2. Reads `properties` to configure that widget
3. Recursively calls `fromJson()` on each item in `children`
4. Returns the assembled widget tree

---

## `ui_schema.json` — Full Schema Example

The current `ui_schema.json` defines a **Stock Trader** screen with:

- `Scaffold` root with `AppBar`, `body`, and `BottomNavigationBar`
- A `Column` body containing a title and an `Expanded > ListView` of stock index `Card`s
- Each card shows index name, price, change percentage, and timestamp
- Bottom nav with 4 tabs: Indices, Watchlist, Portfolio, Order Pad

This demonstrates how a single JSON file can describe a complete multi-section Flutter screen.

---

## Adding New Widget Types

In `lib/dynamic_widget_builder.dart`, add a case to `_buildWidget()`:

```dart
case 'yourwidget':
  return YourWidget(
    prop: properties['prop'],
    child: children.isNotEmpty ? children.first : null,
  );
```

Then add any helper parsers (colors, enums, etc.) following the existing patterns.

---

## Key Constraints

- **No event handlers**: Buttons have placeholder `onPressed: () {}`. Callback routing is not yet implemented.
- **No state management**: The dynamic builder renders static widget trees. No Provider/Riverpod integration.
- **No animations**: Static rendering only.
- **Scaffold builder is basic**: The current `_buildScaffold` doesn't fully parse nested `appBar`/`bottomNavigationBar` from JSON — the `ui_schema.json` schema is more advanced than what the builder currently handles. Extending `_buildScaffold` to parse these nested structures is a natural next step.
- **Icon set is limited**: Only 9 icon names are mapped. Unknown icons fall back to `Icons.widgets`.

---

## Workflow Summary

1. Describe the UI you want in plain English
2. Run `python flutter_ui_agent.py` to generate `ui_schema.json`
3. Load the JSON in Flutter via `DynamicWidgetBuilder.fromJson()`
4. The widget tree renders at runtime — swap the JSON to swap the UI
