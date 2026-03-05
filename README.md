# Flutter UI Agent 🤖

An AI-powered agent that generates Flutter UI widgets from natural language descriptions and exports/imports them as JSON for dynamic rendering.

## 🎯 Features

- **Text-to-UI**: Convert natural language descriptions into Flutter widgets
- **JSON Export/Import**: Save widget schemas as JSON and load them dynamically
- **Dynamic Rendering**: Render Flutter widgets from JSON at runtime
- **LangChain Integration**: Uses LangChain with Google's Gemini API
- **Comprehensive Widget Support**: Container, Column, Row, Text, Button, Card, and more

## 📋 Architecture

```
Text Description → LangChain Agent → Widget Schema (JSON) → Flutter Dart Code
                                            ↓
                                    Dynamic Widget Builder
                                            ↓
                                    Rendered UI in Flutter
```

## 🚀 Quick Start

### Prerequisites

1. Python 3.8+
2. Flutter SDK
3. Google GenAI API Key ([Get one here](https://makersuite.google.com/app/apikey))

### Installation

1. **Clone/Download the project**

2. **Install Python dependencies**:
```bash
pip install -r requirements.txt
```

3. **Set up your API key**:

Option 1 - Environment variable:
```bash
export GOOGLE_API_KEY="your-api-key-here"
```

Option 2 - Create a `.env` file:
```
GOOGLE_API_KEY=your-api-key-here
```

### Usage

#### 1. Generate UI with Python Agent

```bash
python flutter_ui_agent.py
```

This will:
- Prompt you to enter a UI description
- Generate a JSON schema
- Create Flutter Dart code
- Save both to files

**Example descriptions:**
- "Create a login screen with email and password fields and a blue login button"
- "Design a profile card with avatar, name, and bio"
- "Build a product list with image, title, and price"

#### 2. Use in Flutter Project

**Step 1**: Copy `dynamic_widget_builder.dart` to your Flutter project:
```bash
cp dynamic_widget_builder.dart /path/to/your/flutter/project/lib/
```

**Step 2**: Import and use in your Flutter app:

```dart
import 'package:flutter/material.dart';
import 'dynamic_widget_builder.dart';
import 'dart:convert';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Load JSON (from file, asset, or API)
    final jsonSchema = {
      "type": "Container",
      "properties": {"padding": 16, "color": "white"},
      "children": [
        {
          "type": "Text",
          "properties": {
            "text": "Hello from JSON!",
            "fontSize": 24,
            "color": "blue"
          },
          "children": []
        }
      ]
    };

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Dynamic UI')),
        body: DynamicWidgetBuilder.fromJson(jsonSchema),
      ),
    );
  }
}
```

**Step 3**: Load JSON from assets:

```dart
import 'package:flutter/services.dart' show rootBundle;

Future<Widget> loadUIFromAsset(String assetPath) async {
  final String jsonString = await rootBundle.loadString(assetPath);
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  return DynamicWidgetBuilder.fromJson(jsonData);
}

// Usage
Widget dynamicUI = await loadUIFromAsset('assets/ui_schema.json');
```

## 📖 JSON Schema Format

```json
{
  "type": "Container",
  "properties": {
    "color": "blue",
    "padding": 16,
    "width": 200,
    "height": 100
  },
  "children": [
    {
      "type": "Text",
      "properties": {
        "text": "Hello World",
        "fontSize": 20,
        "color": "white"
      },
      "children": []
    }
  ]
}
```

### Supported Widget Types

| Widget | Properties | Example |
|--------|-----------|---------|
| Container | color, padding, margin, width, height, alignment | `{"type": "Container", "properties": {"color": "blue"}}` |
| Text | text, fontSize, color, fontWeight, textAlign | `{"type": "Text", "properties": {"text": "Hello"}}` |
| Column/Row | mainAxisAlignment, crossAxisAlignment | `{"type": "Column", "children": [...]}` |
| Button | text, color, padding | `{"type": "Button", "properties": {"text": "Click"}}` |
| Card | color, elevation, margin | `{"type": "Card", "children": [...]}` |
| Image | url, asset | `{"type": "Image", "properties": {"url": "..."}}` |
| Icon | icon, size, color | `{"type": "Icon", "properties": {"icon": "star"}}` |
| TextField | hint, label, obscureText | `{"type": "TextField", "properties": {"hint": "Email"}}` |

### Supported Colors
`red`, `blue`, `green`, `white`, `black`, `grey`, `yellow`, `orange`, `purple`, `pink`, or hex codes like `#FF5733`

## 🔧 Advanced Usage

### Custom Agent with Different Model

```python
from flutter_ui_agent import FlutterUIAgent

# Initialize with custom settings
agent = FlutterUIAgent(
    api_key="your-key",
    model="gemini-pro",  # or gemini-pro-vision
    temperature=0.7
)

# Generate UI
schema = agent.generate_ui("Create a settings page with toggles")

# Export
agent.export_to_json(schema, "settings_ui.json")

# Generate Flutter code
code = agent.generate_flutter_code(schema)
print(code)
```

### Programmatic UI Generation

```python
# Batch generation
descriptions = [
    "Login screen",
    "Profile page",
    "Settings page"
]

for desc in descriptions:
    schema = agent.generate_ui(desc)
    filename = desc.replace(" ", "_").lower() + ".json"
    agent.export_to_json(schema, filename)
```

## 🎨 Example Outputs

### Login Screen
```bash
python flutter_ui_agent.py
# Choose option 1: "Create a login screen..."
```

Generates:
```json
{
  "type": "Container",
  "properties": {"padding": 20, "color": "white"},
  "children": [
    {
      "type": "Column",
      "properties": {"mainAxisAlignment": "center"},
      "children": [
        {"type": "Text", "properties": {"text": "Login", "fontSize": 28}},
        {"type": "TextField", "properties": {"hint": "Email"}},
        {"type": "TextField", "properties": {"hint": "Password", "obscureText": true}},
        {"type": "Button", "properties": {"text": "Login", "color": "blue"}}
      ]
    }
  ]
}
```

## 🔒 Security Notes

- Never commit your API key to version control
- Use environment variables or secret management
- Sanitize user inputs if exposing this as a service
- Validate JSON schemas before rendering

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Add more widget types (ListView.builder, GridView, etc.)
- Implement event handlers in JSON schema
- Add state management support
- Create visual UI designer interface

## 📄 License

MIT License - feel free to use in your projects!

## 🐛 Troubleshooting

**Issue**: "API key not found"
- Solution: Set `GOOGLE_API_KEY` environment variable

**Issue**: "Import error for langchain"
- Solution: Run `pip install -r requirements.txt`

**Issue**: Dynamic widget not rendering
- Solution: Verify JSON schema format matches documentation

## 📚 Additional Resources

- [LangChain Documentation](https://python.langchain.com/)
- [Google GenAI API](https://ai.google.dev/)
- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets)

---

**Built with ❤️ using LangChain and Flutter**
