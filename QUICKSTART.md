# Quick Start Guide - Flutter UI Agent

## 🚀 Get Started in 5 Minutes

### Step 1: Install Python Dependencies
```bash
pip install -r requirements.txt
```

### Step 2: Get Your Google GenAI API Key
1. Visit: https://makersuite.google.com/app/apikey
2. Create a new API key
3. Copy it

### Step 3: Set Your API Key
```bash
export GOOGLE_API_KEY="your-api-key-here"
```

Or create a `.env` file:
```
GOOGLE_API_KEY=your-api-key-here
```

### Step 4: Test Setup
```bash
python test_setup.py
```

### Step 5: Generate Your First UI
```bash
python flutter_ui_agent.py
```

Choose from examples or enter your own description!

## 📱 Using in Flutter

### Option A: Run the Demo App
1. Copy `main.dart` and `dynamic_widget_builder.dart` to a Flutter project
2. Run the app to see pre-built examples

### Option B: Use Generated JSON
1. Generate UI with Python agent
2. Copy `ui_schema.json` to Flutter assets
3. Load and render:

```dart
import 'dynamic_widget_builder.dart';
import 'dart:convert';

// Load JSON
final String jsonString = await rootBundle.loadString('assets/ui_schema.json');
final Map<String, dynamic> json = jsonDecode(jsonString);

// Render widget
Widget myUI = DynamicWidgetBuilder.fromJson(json);
```

## 🎯 Common Use Cases

### Generate a Login Screen
```bash
python flutter_ui_agent.py
# Enter: "Create a modern login screen with email, password, and login button"
```

### Generate a Profile Page
```bash
python flutter_ui_agent.py
# Enter: "Design a user profile with avatar, name, bio, and social links"
```

### Generate a Product Card
```bash
python flutter_ui_agent.py
# Enter: "Build a product card with image, title, price, and add to cart button"
```

## 🔧 Programmatic Usage

```python
from flutter_ui_agent import FlutterUIAgent

# Initialize
agent = FlutterUIAgent(api_key="your-key")

# Generate
schema = agent.generate_ui("Your description here")

# Export
agent.export_to_json(schema, "my_ui.json")

# Generate Dart code
code = agent.generate_flutter_code(schema)
print(code)
```

## 💡 Tips

1. **Be Specific**: "Blue rounded button with white text" works better than "nice button"
2. **Use Common Widgets**: Stick to Container, Column, Row, Text, Button, Card
3. **Colors**: Use standard names (red, blue, green) or hex (#FF5733)
4. **Layout**: Specify alignment, padding, spacing in your description

## ❓ Troubleshooting

**Error: API key not found**
→ Set GOOGLE_API_KEY environment variable

**Error: Module not found**
→ Run `pip install -r requirements.txt`

**Flutter widget not rendering**
→ Check JSON format matches schema in README

## 📚 Next Steps

- Read the full README.md for detailed documentation
- Check example_schemas.json for more examples
- Explore dynamic_widget_builder.dart for supported widgets

Happy building! 🎉
