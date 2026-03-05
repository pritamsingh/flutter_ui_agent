# Flutter UI Agent - Project Overview

## 🎯 What This Project Does

This is a complete AI-powered system that:
1. Takes natural language descriptions of UI designs
2. Uses Google's Gemini AI (via LangChain) to generate Flutter widget structures
3. Exports the UI as JSON schemas
4. Provides a Flutter widget builder that renders UIs from JSON at runtime

**Example Flow:**
```
"Create a login screen with email and password" 
    → AI Agent (Python + LangChain + Gemini)
    → JSON Schema
    → Flutter Dynamic Widget Builder
    → Rendered UI in Flutter app
```

## 📁 Project Structure

```
flutter_ui_agent/
├── Python Agent (Backend)
│   ├── flutter_ui_agent.py       # Main AI agent using LangChain
│   ├── requirements.txt           # Python dependencies
│   ├── test_setup.py              # Setup verification script
│   └── .env.example               # API key template
│
├── Flutter Components (Frontend)
│   ├── dynamic_widget_builder.dart # JSON → Widget converter
│   ├── main.dart                   # Demo Flutter app
│   └── pubspec.yaml                # Flutter dependencies
│
├── Examples & Schemas
│   └── example_schemas.json       # Sample UI schemas
│
└── Documentation
    ├── README.md                  # Full documentation
    └── QUICKSTART.md              # 5-minute setup guide
```

## 🔧 Key Components

### 1. **flutter_ui_agent.py** (Python/LangChain Agent)
- Uses Google Gemini Pro via LangChain
- Converts text descriptions to structured widget schemas
- Exports JSON and generates Dart code
- Handles prompt engineering for optimal results

**Key Features:**
- Pydantic schema validation
- Robust error handling with fallbacks
- Support for nested widget hierarchies
- Export/import functionality

### 2. **dynamic_widget_builder.dart** (Flutter Widget Renderer)
- Reads JSON schemas at runtime
- Dynamically builds Flutter widget trees
- Supports 15+ widget types
- Handles properties, styling, and layouts

**Supported Widgets:**
- Layout: Container, Column, Row, Stack, Padding, Center, Expanded
- Content: Text, Image, Icon
- Interactive: ElevatedButton, TextField
- Structure: Card, ListView, SizedBox, Scaffold

### 3. **main.dart** (Demo Application)
- Complete Flutter app demonstrating the system
- Pre-loaded with example UIs
- Interactive menu to switch between examples
- JSON viewer and export functionality

## 🚀 How to Use

### Quick Setup (3 steps)

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set API key:**
   ```bash
   export GOOGLE_API_KEY="your-gemini-api-key"
   ```

3. **Run the agent:**
   ```bash
   python flutter_ui_agent.py
   ```

### Integration in Flutter Project

1. Copy `dynamic_widget_builder.dart` to your Flutter lib folder
2. Generate UI schemas using the Python agent
3. Load and render:

```dart
import 'dynamic_widget_builder.dart';
import 'dart:convert';

// From JSON string
Widget widget = DynamicWidgetBuilder.fromJson(jsonData);

// From asset
final json = jsonDecode(await rootBundle.loadString('assets/ui.json'));
Widget widget = DynamicWidgetBuilder.fromJson(json);
```

## 💡 Use Cases

### 1. **Rapid Prototyping**
Generate UI mockups instantly from descriptions for client presentations.

### 2. **Dynamic UIs**
Build apps where UI is loaded from a backend API, allowing UI updates without app releases.

### 3. **A/B Testing**
Test different UI layouts by switching JSON schemas without rebuilding the app.

### 4. **No-Code Tools**
Backend for a visual UI builder where users describe UIs in plain English.

### 5. **Template System**
Create reusable UI templates that can be customized via JSON parameters.

## 🎨 Example Outputs

### Login Screen
**Input:** "Create a login screen with email and password fields and a blue login button"

**Output JSON:**
```json
{
  "type": "Container",
  "properties": {"padding": 20},
  "children": [
    {"type": "TextField", "properties": {"label": "Email"}},
    {"type": "TextField", "properties": {"label": "Password", "obscureText": true}},
    {"type": "Button", "properties": {"text": "Login", "color": "blue"}}
  ]
}
```

### Profile Card
**Input:** "Design a profile card with avatar, name, and bio"

**Generates:** A Card widget with Icon, Text widgets for name/bio, all properly styled and aligned.

## 🔐 Security & Best Practices

### API Key Management
- Never commit API keys to version control
- Use environment variables or secret management
- The `.env.example` shows the format without exposing keys

### JSON Validation
- All schemas are validated through Pydantic models
- Dynamic builder includes safety checks
- Fallbacks for malformed data

### Production Considerations
- Add authentication if exposing as an API service
- Implement rate limiting for API calls
- Sanitize user inputs
- Cache generated schemas to reduce API costs

## 🛠️ Customization

### Add New Widget Types
Edit `dynamic_widget_builder.dart`:
```dart
case 'your_widget':
  return YourCustomWidget(
    // Map properties from JSON
  );
```

### Modify AI Behavior
Edit the prompt in `flutter_ui_agent.py`:
```python
self.ui_generation_prompt = PromptTemplate(
    template="Your custom prompt here..."
)
```

### Change AI Model
```python
self.llm = ChatGoogleGenerativeAI(
    model="gemini-pro-vision",  # or another model
    temperature=0.5  # adjust creativity
)
```

## 📊 Technical Details

### Dependencies
**Python:**
- langchain: AI orchestration framework
- langchain-google-genai: Gemini integration
- pydantic: Data validation
- google-generativeai: Google AI SDK

**Flutter:**
- Standard Flutter SDK (no external packages needed)
- Built-in JSON support via dart:convert

### Architecture Pattern
- **Separation of Concerns**: AI generation (Python) separate from rendering (Flutter)
- **Schema-Driven**: JSON as the intermediate representation
- **Platform Agnostic**: JSON schemas could be used for web, iOS, Android

## 🔮 Future Enhancements

Potential improvements:
- [ ] Add event handlers in JSON (onPressed callbacks)
- [ ] Support for animations and transitions
- [ ] Custom theme support in schemas
- [ ] Visual UI editor with drag-and-drop
- [ ] State management integration (Provider, Riverpod)
- [ ] Support for more complex widgets (GridView, PageView)
- [ ] API backend for schema storage and versioning
- [ ] Multi-language support for UI text

## 📝 License & Credits

**License:** MIT - Free to use in your projects

**Built With:**
- LangChain for AI orchestration
- Google Gemini for natural language understanding
- Flutter for cross-platform UI rendering

## 🆘 Support & Resources

- **Full Documentation:** See README.md
- **Quick Start:** See QUICKSTART.md
- **Examples:** Check example_schemas.json
- **Test Setup:** Run test_setup.py

## ✅ Getting Started Checklist

- [ ] Install Python dependencies
- [ ] Get Google GenAI API key
- [ ] Set environment variable
- [ ] Run test_setup.py
- [ ] Generate your first UI
- [ ] Try the Flutter demo app
- [ ] Create your own schemas
- [ ] Integrate into your project

---

**Ready to build dynamic UIs with AI?** Start with QUICKSTART.md! 🚀
