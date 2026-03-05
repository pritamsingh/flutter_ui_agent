"""
Flutter UI Agent - Generates Flutter widgets from text and exports/imports JSON
"""

import json
import os
import re
import time
import base64
import tempfile
import webbrowser
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.messages import HumanMessage
from pydantic import BaseModel, Field

load_dotenv(".env.example")


class WidgetSchema(BaseModel):
    """Schema for a Flutter widget"""
    type: str = Field(description="Widget type (Container, Column, Row, Text, etc.)")
    properties: Dict[str, Any] = Field(description="Widget properties like color, padding, etc.")
    children: List['WidgetSchema'] = Field(default=[], description="Child widgets")
    
    class Config:
        json_schema_extra = {
            "example": {
                "type": "Container",
                "properties": {"color": "blue", "padding": 16},
                "children": []
            }
        }


WidgetSchema.model_rebuild()


class FlutterUIAgent:
    """Agent that generates Flutter UI from text descriptions"""
    
    AVAILABLE_MODELS = [
        "Gemini 3 Pro",
        "gemini-2.0-flash",
        "Gemini 2.5 Pro",
        "Gemini 2 Flash Exp",
        "gemini-2.5-flash",
        "Gemini 2.5 Flash Lite",
        "Gemini 2.5 Flash TTS",
    ]

    def __init__(self, api_key: str, model: str = "gemini-2.0-flash"):
        """Initialize the agent with Google GenAI API key"""
        self.api_key = api_key
        self.model_name = model
        self.llm = ChatGoogleGenerativeAI(
            model=model,
            google_api_key=api_key,
            temperature=0.7,
            timeout=300,
            max_retries=5,
        )
        
        # Parser for structured output
        self.parser = PydanticOutputParser(pydantic_object=WidgetSchema)
        
        # Prompt template for UI generation
        self.ui_generation_prompt = PromptTemplate(
            input_variables=["description"],
            template="""You are a Flutter UI expert. Generate a JSON schema for a Flutter UI based on the description.

Description: {description}

The Flutter app supports TWO JSON formats. Choose the appropriate one:

=== FORMAT 1: Simple Widget Tree (for single screens or components) ===
{{
  "type": "WidgetType",
  "properties": {{ ... }},
  "children": [ ... ]
}}

Supported widget types and their properties:
- Scaffold: backgroundColor, appBar (nested widget), body (nested widget), bottomNavigationBar (nested widget)
- Container: color, backgroundColor, width, height, padding, margin, alignment, decoration
- Column: mainAxisAlignment (start|end|center|spaceBetween|spaceAround|spaceEvenly), crossAxisAlignment (start|end|center|stretch)
- Row: mainAxisAlignment, crossAxisAlignment (same values as Column)
- Wrap: spacing, runSpacing
- Text: text, fontSize, fontWeight (bold|normal|light), color, textAlign (left|right|center|justify), maxLines
- ElevatedButton / Button: text, backgroundColor, textColor, padding, color
- Card: color, elevation, margin
- Padding: padding
- Center: (no properties, wraps single child)
- Expanded: flex
- SizedBox: width, height
- SingleChildScrollView: (wraps single child)
- ListView: shrinkWrap (true/false), physics ("never" for NeverScrollableScrollPhysics)
- Stack: (no special properties)
- Image: url, asset, width, height
- Icon: icon or iconName, size, color
- TextField: hint, label, obscureText (true/false)

=== FORMAT 2: App-Level Schema (for full apps with multiple screens and navigation) ===
{{
  "meta": {{
    "app": "AppName",
    "version": "v1",
    "description": "App description",
    "initialScreen": "screenId",
    "noNavScreens": ["login", "twoFactor"]
  }},
  "designTokens": {{
    "colors": {{ "primary": "#hex", "secondary": "#hex" }},
    "typography": {{ "fontDisplay": "FontName", "fontBody": "FontName" }},
    "radius": {{ "sm": 4.0, "md": 8.0, "lg": 12.0 }},
    "dimensions": {{ "navWidth": 220.0, "topbarHeight": 52.0 }}
  }},
  "navigation": {{
    "type": "NavDrawer",
    "logo": {{ "mark": "AB", "text": "AppName" }},
    "user": {{ "initials": "AJ", "name": "User Name", "role": "Role" }},
    "sections": [
      {{
        "label": "SECTION",
        "items": [
          {{
            "id": "nav-screenId",
            "icon": "icon_name",
            "label": "Screen Label",
            "onClick": {{ "action": "navigate", "screen": "screenId" }}
          }}
        ]
      }}
    ]
  }},
  "screens": [
    {{
      "id": "screenId",
      "title": "Screen Title",
      "showNav": true,
      "layout": "screenGrid",
      "regions": {{
        "top": {{ "title": "Title", "actions": [...] }},
        "left": {{ "type": "RegionType", ... }},
        "center": {{ "type": "RegionType", ... }},
        "right": {{ "type": "RegionType", ... }},
        "bottom": {{ "type": "RegionType", ... }}
      }},
      "widgets": [...]
    }}
  ]
}}

Supported region types: ConversationSidebar, MessageList, MessageComposer, ArtifactPanel, DataTable, VerticalCardList, SettingsForm, TaskDetailBody, Column (with MarketDataCard/AlgoMonitorCard children)
Supported screen layouts: centered (for login/forms), screenGrid (for region-based), settingsLayout

Use FORMAT 2 for descriptions that involve full apps, multiple screens, or navigation.
Use FORMAT 1 for single screen or component descriptions.

=== Supported Colors ===
Named: red, blue, green, white, black, grey, yellow, orange, purple, pink, teal, cyan, amber, indigo, brown, lightBlue, darkBlue, darkGrey, lightGrey, transparent
Hex: #RRGGBB format (e.g., "#2563EB")

=== Supported Icons ===
home, person, settings, star, favorite, search, menu, close, check, public, pie_chart, shopping_cart, show_chart, add_shopping_cart, account_balance_wallet, build, lightbulb, notifications, email, phone, camera, delete, edit, add, remove, arrow_back, arrow_forward, info, warning, error, lock, visibility, dashboard, list, cloud, download, upload, share, map, location_on, calendar_today, access_time, chat_bubble, work, folder, bar_chart, rocket_launch, bolt, history, shield, logout, expand_more, more_vert, content_copy, thumb_up, thumb_down, send, attach_file, alternate_email, code, description, play_arrow, grid_view, trending_up, trending_down

=== Padding/Margin Formats ===
- Number: 16 (applies to all sides)
- Object: {{"all": 16}} or {{"horizontal": 16, "vertical": 8}} or {{"left": 8, "top": 12, "right": 8, "bottom": 12}}

Return ONLY valid JSON, no explanations or markdown."""
        )

        self.chain = self.ui_generation_prompt | self.llm

    def set_model(self, model: str):
        """Switch to a different Gemini model"""
        self.model_name = model
        self.llm = ChatGoogleGenerativeAI(
            model=model,
            google_api_key=self.api_key,
            temperature=0.7,
            timeout=300,
            max_retries=5,
        )
        self.chain = self.ui_generation_prompt | self.llm

    def _call_llm(self, description: str, attachment_path: Optional[str] = None) -> str:
        """Call LLM with rate-limit retry handling"""
        if attachment_path:
            ext = os.path.splitext(attachment_path)[1].lower()
            image_exts = ('.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp')
            if ext in image_exts:
                return self._generate_with_image(description, attachment_path)
            else:
                return self._generate_with_text_file(description, attachment_path)
        else:
            result = self.chain.invoke({"description": description})
            return str(result.content).strip()

    def generate_ui(self, description: str, attachment_path: Optional[str] = None,
                    status_callback=None) -> Dict[str, Any]:
        """Generate Flutter UI from text description, optionally with a file attachment.
        status_callback: optional callable(msg) for progress updates (used by Streamlit)."""
        max_retries = 3
        for attempt in range(max_retries):
            try:
                result_str = self._call_llm(description, attachment_path)

                # Strip markdown code fences if present
                if result_str.startswith("```"):
                    lines = result_str.split("\n")
                    lines = [l for l in lines if not l.strip().startswith("```")]
                    result_str = "\n".join(lines)

                # Extract JSON from response
                start_idx = result_str.find('{')
                end_idx = result_str.rfind('}') + 1
                if start_idx != -1 and end_idx > start_idx:
                    json_str = result_str[start_idx:end_idx]
                    parsed = json.loads(json_str)

                    # Detect format: app-level schema or simple widget tree
                    if isinstance(parsed, dict):
                        if "screens" in parsed or "navigation" in parsed:
                            return parsed
                        elif "type" in parsed:
                            try:
                                widget_schema = WidgetSchema.model_validate(parsed)
                                return widget_schema.model_dump()
                            except Exception:
                                return parsed

                    return parsed
            except Exception as e:
                err_str = str(e)
                # Rate limit — extract retry delay and wait
                if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str:
                    wait_match = re.search(r'retry\s*(?:in|after)\s*([\d.]+)\s*s', err_str, re.IGNORECASE)
                    wait_secs = float(wait_match.group(1)) if wait_match else 30.0
                    wait_secs = min(wait_secs + 2, 120)  # cap at 2 minutes
                    msg = f"Rate limited. Waiting {wait_secs:.0f}s before retry ({attempt+1}/{max_retries})..."
                    print(msg)
                    if status_callback:
                        status_callback(msg)
                    time.sleep(wait_secs)
                    continue
                # Network error — short retry
                if "nodename" in err_str or "Errno" in err_str or "ConnectionError" in err_str:
                    msg = f"Network error. Retrying in 5s ({attempt+1}/{max_retries})..."
                    print(msg)
                    if status_callback:
                        status_callback(msg)
                    time.sleep(5)
                    continue
                # Other errors — don't retry
                raise

        # Ultimate fallback: return a simple error structure
        return {
            "type": "Container",
            "properties": {"color": "white"},
            "children": [{
                "type": "Text",
                "properties": {"text": "Error generating UI — rate limit exceeded. Try again later."},
                "children": []
            }]
        }
    
    def _generate_with_image(self, description: str, image_path: str) -> str:
        """Send description + image to Gemini for multimodal UI generation"""
        ext = os.path.splitext(image_path)[1].lower()
        mime_map = {
            ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
            ".webp": "image/webp", ".gif": "image/gif", ".bmp": "image/bmp",
        }
        mime_type = mime_map.get(ext, "image/png")

        with open(image_path, "rb") as f:
            image_data = base64.standard_b64encode(f.read()).decode("utf-8")

        prompt_text = self.ui_generation_prompt.format(description=description)
        prompt_text += (
            "\n\nAn image/screenshot is attached. Use it as a visual reference "
            "to replicate the layout, colors, typography, and component structure "
            "as closely as possible in the JSON schema."
        )

        message = HumanMessage(
            content=[
                {"type": "text", "text": prompt_text},
                {"type": "image_url", "image_url": {"url": f"data:{mime_type};base64,{image_data}"}},
            ]
        )
        response = self.llm.invoke([message])
        return str(response.content).strip()

    def _generate_with_text_file(self, description: str, file_path: str) -> str:
        """Send description + text file content (HTML/CSS/JSON/TXT) to Gemini"""
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            file_content = f.read()

        # Truncate very large files to avoid API timeouts
        max_chars = 150_000
        if len(file_content) > max_chars:
            file_content = file_content[:max_chars] + "\n\n... [TRUNCATED — file too large] ..."
            print(f"Note: File truncated to {max_chars} characters to avoid timeout.")

        ext = os.path.splitext(file_path)[1].lower()
        file_type = {
            ".html": "HTML", ".css": "CSS", ".json": "JSON",
            ".txt": "text", ".xml": "XML", ".svg": "SVG",
        }.get(ext, "text")

        prompt_text = self.ui_generation_prompt.format(description=description)
        prompt_text += (
            f"\n\nA {file_type} file is attached below as reference. "
            "Analyze its structure, layout, components, styling, colors, and typography. "
            "Replicate the UI design as closely as possible in the JSON schema.\n\n"
            f"--- {file_type} FILE: {os.path.basename(file_path)} ---\n"
            f"{file_content}\n"
            f"--- END OF {file_type} FILE ---"
        )

        message = HumanMessage(content=[{"type": "text", "text": prompt_text}])
        response = self.llm.invoke([message])
        return str(response.content).strip()

    def generate_flutter_code(self, widget_schema: Dict[str, Any]) -> str:
        """Convert JSON schema to Flutter Dart code"""
        # App-level schemas don't map to a single widget tree
        if "screens" in widget_schema or "navigation" in widget_schema:
            return ('// App-level schema detected.\n'
                    '// This schema is rendered by AppSchemaRenderer at runtime.\n'
                    '// See lib/app_schema_renderer.dart')
        return self._build_widget_code(widget_schema, indent=2)

    def _build_widget_code(self, widget: Dict[str, Any], indent: int = 0) -> str:
        """Recursively build valid Flutter Dart widget code"""
        ind = "  " * indent
        w_type = widget.get("type", "Container")
        props = widget.get("properties", {})
        children = widget.get("children", [])
        child_widgets = [self._build_widget_code(c, indent + 2) for c in children]

        handler = {
            "Scaffold": self._code_scaffold,
            "Container": self._code_container,
            "Text": self._code_text,
            "ElevatedButton": self._code_button,
            "Button": self._code_button,
            "Card": self._code_card,
            "Padding": self._code_padding,
            "Column": self._code_flex,
            "Row": self._code_flex,
            "ListView": self._code_flex,
            "Stack": self._code_flex,
            "Icon": self._code_icon,
            "SizedBox": self._code_sizedbox,
            "Center": self._code_single_child,
            "Expanded": self._code_expanded,
            "SingleChildScrollView": self._code_single_child,
            "TextField": self._code_textfield,
            "Image": self._code_image,
        }.get(w_type)

        if handler:
            return handler(w_type, props, child_widgets, indent)

        # Fallback: generic widget
        if child_widgets:
            if len(child_widgets) == 1:
                return f"{ind}{w_type}(\n{ind}  child: {child_widgets[0].strip()},\n{ind})"
            return f"{ind}{w_type}(\n{ind}  children: [\n" + ",\n".join(child_widgets) + f",\n{ind}  ],\n{ind})"
        return f"{ind}{w_type}()"

    def _dart_color(self, color_value) -> str:
        """Convert a color string to valid Dart Color expression"""
        if not color_value:
            return "Colors.white"
        c = str(color_value)
        simple = {
            "red": "Colors.red", "blue": "Colors.blue", "green": "Colors.green",
            "white": "Colors.white", "black": "Colors.black", "grey": "Colors.grey",
            "gray": "Colors.grey", "yellow": "Colors.yellow", "orange": "Colors.orange",
            "purple": "Colors.purple", "pink": "Colors.pink", "teal": "Colors.teal",
            "cyan": "Colors.cyan", "amber": "Colors.amber", "indigo": "Colors.indigo",
            "brown": "Colors.brown", "transparent": "Colors.transparent",
            "lightBlue": "Colors.lightBlue", "lightGrey": "Colors.grey.shade300",
            "lightGray": "Colors.grey.shade300", "darkGrey": "Colors.grey.shade700",
            "darkGray": "Colors.grey.shade700", "darkBlue": "Color(0xFF0D47A1)",
        }
        if c.lower() in {k.lower(): k for k in simple}:
            for k, v in simple.items():
                if k.lower() == c.lower():
                    return v
        if c.startswith("#"):
            return f"Color(0xFF{c[1:].upper()})"
        return f"Colors.{c}"

    def _dart_edge_insets(self, value) -> str:
        """Convert padding/margin value to EdgeInsets Dart code"""
        if isinstance(value, (int, float)):
            return f"EdgeInsets.all({value})"
        if isinstance(value, dict):
            if "all" in value:
                return f"EdgeInsets.all({value['all']})"
            if "horizontal" in value or "vertical" in value:
                h = value.get("horizontal", 0)
                v = value.get("vertical", 0)
                return f"EdgeInsets.symmetric(horizontal: {h}, vertical: {v})"
            l, t, r, b = value.get("left", 0), value.get("top", 0), value.get("right", 0), value.get("bottom", 0)
            return f"EdgeInsets.only(left: {l}, top: {t}, right: {r}, bottom: {b})"
        return "EdgeInsets.all(0)"

    def _dart_alignment(self, value) -> str:
        mapping = {
            "center": "Alignment.center", "topleft": "Alignment.topLeft",
            "topright": "Alignment.topRight", "topcenter": "Alignment.topCenter",
            "bottomleft": "Alignment.bottomLeft", "bottomright": "Alignment.bottomRight",
            "bottomcenter": "Alignment.bottomCenter", "centerleft": "Alignment.centerLeft",
            "centerright": "Alignment.centerRight",
        }
        return mapping.get(str(value).lower(), "Alignment.center")

    def _dart_main_axis(self, value) -> str:
        mapping = {
            "start": "MainAxisAlignment.start", "end": "MainAxisAlignment.end",
            "center": "MainAxisAlignment.center", "spacebetween": "MainAxisAlignment.spaceBetween",
            "spacearound": "MainAxisAlignment.spaceAround", "spaceevenly": "MainAxisAlignment.spaceEvenly",
        }
        return mapping.get(str(value).lower(), "MainAxisAlignment.start")

    def _dart_cross_axis(self, value) -> str:
        mapping = {
            "start": "CrossAxisAlignment.start", "end": "CrossAxisAlignment.end",
            "center": "CrossAxisAlignment.center", "stretch": "CrossAxisAlignment.stretch",
        }
        return mapping.get(str(value).lower(), "CrossAxisAlignment.center")

    def _code_scaffold(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        lines = [f"{ind}Scaffold("]
        if "backgroundColor" in props:
            lines.append(f"{ind}  backgroundColor: {self._dart_color(props['backgroundColor'])},")
        if "appBar" in props and isinstance(props["appBar"], dict):
            appbar_code = self._build_widget_code(props["appBar"], indent + 1).strip()
            lines.append(f"{ind}  appBar: {appbar_code},")
        if "body" in props and isinstance(props["body"], dict):
            body_code = self._build_widget_code(props["body"], indent + 1).strip()
            lines.append(f"{ind}  body: {body_code},")
        elif child_widgets:
            lines.append(f"{ind}  body: {child_widgets[0].strip()},")
        if "bottomNavigationBar" in props and isinstance(props["bottomNavigationBar"], dict):
            nav_code = self._build_widget_code(props["bottomNavigationBar"], indent + 1).strip()
            lines.append(f"{ind}  bottomNavigationBar: {nav_code},")
        lines.append(f"{ind})")
        return "\n".join(lines)

    def _code_container(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        lines = [f"{ind}Container("]
        color = props.get("color") or props.get("backgroundColor")
        if color:
            lines.append(f"{ind}  color: {self._dart_color(color)},")
        if "width" in props:
            lines.append(f"{ind}  width: {props['width']},")
        if "height" in props:
            lines.append(f"{ind}  height: {props['height']},")
        if "padding" in props:
            lines.append(f"{ind}  padding: {self._dart_edge_insets(props['padding'])},")
        if "margin" in props:
            lines.append(f"{ind}  margin: {self._dart_edge_insets(props['margin'])},")
        if "alignment" in props:
            lines.append(f"{ind}  alignment: {self._dart_alignment(props['alignment'])},")
        if child_widgets:
            if len(child_widgets) == 1:
                lines.append(f"{ind}  child: {child_widgets[0].strip()},")
            else:
                lines.append(f"{ind}  child: Column(children: [")
                lines.append(",\n".join(child_widgets) + ",")
                lines.append(f"{ind}  ]),")
        lines.append(f"{ind})")
        return "\n".join(lines)

    def _code_text(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        text = props.get("text", "").replace("'", "\\'")
        style_parts = []
        if "fontSize" in props:
            style_parts.append(f"fontSize: {props['fontSize']}")
        if "fontWeight" in props:
            fw = "FontWeight.bold" if props["fontWeight"] == "bold" else "FontWeight.normal"
            style_parts.append(f"fontWeight: {fw}")
        if "color" in props:
            style_parts.append(f"color: {self._dart_color(props['color'])}")
        style = ""
        if style_parts:
            style = f", style: TextStyle({', '.join(style_parts)})"
        align = ""
        if "textAlign" in props:
            align_map = {"left": "TextAlign.left", "right": "TextAlign.right",
                         "center": "TextAlign.center", "justify": "TextAlign.justify"}
            ta = align_map.get(props["textAlign"], "")
            if ta:
                align = f", textAlign: {ta}"
        return f"{ind}Text('{text}'{style}{align})"

    def _code_button(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        lines = [f"{ind}ElevatedButton("]
        lines.append(f"{ind}  onPressed: () {{}},")
        style_parts = []
        bg = props.get("backgroundColor") or props.get("color")
        if bg:
            style_parts.append(f"backgroundColor: {self._dart_color(bg)}")
        if "textColor" in props:
            style_parts.append(f"foregroundColor: {self._dart_color(props['textColor'])}")
        if "padding" in props:
            style_parts.append(f"padding: {self._dart_edge_insets(props['padding'])}")
        if style_parts:
            lines.append(f"{ind}  style: ElevatedButton.styleFrom({', '.join(style_parts)}),")
        if child_widgets:
            lines.append(f"{ind}  child: {child_widgets[0].strip()},")
        else:
            text = props.get("text", "Button").replace("'", "\\'")
            lines.append(f"{ind}  child: Text('{text}'),")
        lines.append(f"{ind})")
        return "\n".join(lines)

    def _code_card(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        lines = [f"{ind}Card("]
        if "elevation" in props:
            lines.append(f"{ind}  elevation: {props['elevation']},")
        if "margin" in props:
            lines.append(f"{ind}  margin: {self._dart_edge_insets(props['margin'])},")
        if "color" in props:
            lines.append(f"{ind}  color: {self._dart_color(props['color'])},")
        if child_widgets:
            if len(child_widgets) == 1:
                lines.append(f"{ind}  child: {child_widgets[0].strip()},")
            else:
                lines.append(f"{ind}  child: Column(children: [")
                lines.append(",\n".join(child_widgets) + ",")
                lines.append(f"{ind}  ]),")
        lines.append(f"{ind})")
        return "\n".join(lines)

    def _code_padding(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        pad = self._dart_edge_insets(props.get("padding", 8))
        child = child_widgets[0].strip() if child_widgets else "Container()"
        return f"{ind}Padding(\n{ind}  padding: {pad},\n{ind}  child: {child},\n{ind})"

    def _code_flex(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        lines = [f"{ind}{w_type}("]
        if "mainAxisAlignment" in props:
            lines.append(f"{ind}  mainAxisAlignment: {self._dart_main_axis(props['mainAxisAlignment'])},")
        if "crossAxisAlignment" in props:
            lines.append(f"{ind}  crossAxisAlignment: {self._dart_cross_axis(props['crossAxisAlignment'])},")
        if w_type == "ListView":
            if props.get("shrinkWrap"):
                lines.append(f"{ind}  shrinkWrap: true,")
            if props.get("physics") == "never":
                lines.append(f"{ind}  physics: NeverScrollableScrollPhysics(),")
        lines.append(f"{ind}  children: [")
        for cw in child_widgets:
            lines.append(cw + ",")
        lines.append(f"{ind}  ],")
        lines.append(f"{ind})")
        return "\n".join(lines)

    def _code_icon(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        name = props.get("icon") or props.get("iconName") or "star"
        parts = [f"Icons.{name}"]
        if "size" in props:
            parts.append(f"size: {props['size']}")
        if "color" in props:
            parts.append(f"color: {self._dart_color(props['color'])}")
        return f"{ind}Icon({', '.join(parts)})"

    def _code_sizedbox(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        parts = []
        if "width" in props:
            parts.append(f"width: {props['width']}")
        if "height" in props:
            parts.append(f"height: {props['height']}")
        child = ""
        if child_widgets:
            child = f", child: {child_widgets[0].strip()}"
        return f"{ind}SizedBox({', '.join(parts)}{child})"

    def _code_single_child(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        child = child_widgets[0].strip() if child_widgets else "Container()"
        return f"{ind}{w_type}(\n{ind}  child: {child},\n{ind})"

    def _code_expanded(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        flex = props.get("flex", 1)
        child = child_widgets[0].strip() if child_widgets else "Container()"
        parts = []
        if flex != 1:
            parts.append(f"flex: {flex}")
        parts.append(f"child: {child}")
        return f"{ind}Expanded(\n" + "".join(f"{ind}  {p},\n" for p in parts) + f"{ind})"

    def _code_textfield(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        hint = props.get("hint", "").replace("'", "\\'")
        label = props.get("label", "").replace("'", "\\'")
        obscure = "true" if props.get("obscureText") else "false"
        return (f"{ind}TextField(\n"
                f"{ind}  decoration: InputDecoration(hintText: '{hint}', labelText: '{label}', border: OutlineInputBorder()),\n"
                f"{ind}  obscureText: {obscure},\n"
                f"{ind})")

    def _code_image(self, w_type, props, child_widgets, indent) -> str:
        ind = "  " * indent
        if "url" in props:
            return f"{ind}Image.network('{props['url']}')"
        if "asset" in props:
            return f"{ind}Image.asset('{props['asset']}')"
        return f"{ind}Icon(Icons.image, size: 50)"
    
    def preview_in_browser(self, widget_schema: Dict[str, Any]):
        """Render a visual HTML preview of the widget schema and open in browser"""
        html = self._schema_to_html(widget_schema)
        full_html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Flutter UI Preview</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: 'Segoe UI', Roboto, sans-serif; background: #f0f0f0; }}
  .phone-frame {{
    width: 390px; height: 844px; margin: 30px auto;
    border: 3px solid #333; border-radius: 40px;
    overflow: hidden; background: white;
    display: flex; flex-direction: column;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
  }}
  .phone-frame > .scaffold {{ flex: 1; display: flex; flex-direction: column; overflow: hidden; }}
  .phone-frame > :not(.scaffold) {{ flex: 1; overflow-y: auto; }}
  .appbar {{
    padding: 12px 16px; display: flex; align-items: center;
    justify-content: center; min-height: 56px; flex-shrink: 0;
  }}
  .appbar-title {{ font-size: 20px; font-weight: 600; }}
  .bottom-nav {{
    display: flex; border-top: 1px solid #e0e0e0;
    padding: 8px 0; flex-shrink: 0;
  }}
  .bottom-nav-item {{
    flex: 1; display: flex; flex-direction: column;
    align-items: center; gap: 4px; font-size: 12px; color: #9e9e9e;
  }}
  .bottom-nav-item:first-child {{ color: #2196F3; }}
  .bottom-nav-item .material-icon {{ font-size: 24px; }}
  .scaffold-body {{ flex: 1; overflow-y: auto; }}
  .w-column {{ display: flex; flex-direction: column; }}
  .w-row {{ display: flex; flex-direction: row; align-items: center; }}
  .w-row.space-between {{ justify-content: space-between; }}
  .w-expanded {{ flex: 1; min-height: 0; overflow-y: auto; }}
  .w-card {{
    background: white; border-radius: 8px;
    box-shadow: 0 2px 6px rgba(0,0,0,0.12);
  }}
  .w-text {{ line-height: 1.4; }}
  .w-textfield {{
    border: 1px solid #ccc; border-radius: 4px;
    padding: 14px 12px; font-size: 14px; width: 100%;
  }}
  .w-button {{
    border: none; border-radius: 4px; padding: 14px 24px;
    color: white; font-size: 16px; cursor: pointer; text-align: center;
  }}
  .w-icon {{ font-family: 'Material Icons'; font-size: 24px; }}
  .w-listview {{ display: flex; flex-direction: column; }}
  .w-center {{ display: flex; justify-content: center; align-items: center; }}
  .badge {{
    position: fixed; bottom: 16px; right: 16px;
    background: #333; color: white; padding: 8px 16px;
    border-radius: 20px; font-size: 13px; z-index: 100;
  }}
</style>
<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
</head>
<body>
  <div class="phone-frame">{html}</div>
  <div class="badge">Flutter UI Preview</div>
</body>
</html>"""
        fd, path = tempfile.mkstemp(suffix='.html', prefix='flutter_preview_')
        with os.fdopen(fd, 'w') as f:
            f.write(full_html)
        webbrowser.open(f'file://{path}')
        print(f"Preview opened in browser")

    def _schema_to_html(self, widget: Dict[str, Any]) -> str:
        """Recursively convert widget schema to HTML"""
        w_type = widget.get("type", "Container").lower()
        props = widget.get("properties", {})
        children = widget.get("children", [])

        children_html = "".join(self._schema_to_html(c) for c in children)

        if w_type == "scaffold":
            return self._render_scaffold(props)
        elif w_type == "column":
            style = self._flex_style(props)
            return f'<div class="w-column" style="{style}">{children_html}</div>'
        elif w_type == "row":
            style = self._flex_style(props)
            return f'<div class="w-row" style="{style}">{children_html}</div>'
        elif w_type == "text":
            return self._render_text(props)
        elif w_type in ("elevatedbutton", "button"):
            text = self._esc(props.get("text", "Button"))
            bg = self._css_color(props.get("color", "blue"))
            pad = props.get("padding", 14)
            return f'<button class="w-button" style="background:{bg};padding:{pad}px;">{text}</button>'
        elif w_type == "textfield":
            hint = self._esc(props.get("hint", ""))
            label = self._esc(props.get("label", ""))
            placeholder = hint or label
            input_type = "password" if props.get("obscureText") else "text"
            return f'<div style="width:100%;"><label style="font-size:12px;color:#666;">{label}</label><input class="w-textfield" type="{input_type}" placeholder="{placeholder}"></div>'
        elif w_type == "card":
            margin = props.get("margin", 0)
            elev = props.get("elevation", 2)
            bg = self._css_color(props.get("color", "white"))
            shadow = f"0 {elev}px {elev*2}px rgba(0,0,0,0.12)"
            return f'<div class="w-card" style="margin:{margin}px;box-shadow:{shadow};background:{bg};">{children_html}</div>'
        elif w_type == "padding":
            pad = props.get("padding", 8)
            return f'<div style="padding:{pad}px;">{children_html}</div>'
        elif w_type == "container":
            return self._render_container(props, children_html)
        elif w_type == "sizedbox":
            w = props.get("width", 0)
            h = props.get("height", 0)
            return f'<div style="width:{w}px;height:{h}px;">{children_html}</div>'
        elif w_type == "center":
            return f'<div class="w-center">{children_html}</div>'
        elif w_type == "expanded":
            return f'<div class="w-expanded">{children_html}</div>'
        elif w_type == "listview":
            return f'<div class="w-listview">{children_html}</div>'
        elif w_type == "icon":
            return self._render_icon(props)
        elif w_type == "image":
            url = props.get("url", "")
            if url:
                return f'<img src="{self._esc(url)}" style="max-width:100%;">'
            return '<span class="material-icon" style="font-size:50px;color:#ccc;">image</span>'
        elif w_type == "stack":
            return f'<div style="position:relative;">{children_html}</div>'
        else:
            return f'<div>{children_html}</div>'

    def _render_scaffold(self, props: Dict[str, Any]) -> str:
        bg = self._css_color(props.get("backgroundColor", "white"))
        parts = [f'<div class="scaffold" style="background:{bg};">']

        # AppBar
        appbar = props.get("appBar")
        if appbar and isinstance(appbar, dict):
            ap = appbar.get("properties", {})
            ab_bg = self._css_color(ap.get("backgroundColor", "blue"))
            ab_fg = self._css_color(ap.get("foregroundColor", "white"))
            title = ap.get("title", "")
            if isinstance(title, dict):
                title_text = self._esc(title.get("properties", {}).get("text", ""))
            else:
                title_text = self._esc(str(title))
            parts.append(f'<div class="appbar" style="background:{ab_bg};color:{ab_fg};"><span class="appbar-title">{title_text}</span></div>')

        # Body
        body = props.get("body")
        if body and isinstance(body, dict):
            body_html = self._schema_to_html(body)
            parts.append(f'<div class="scaffold-body">{body_html}</div>')

        # BottomNavigationBar
        bnb = props.get("bottomNavigationBar")
        if bnb and isinstance(bnb, dict):
            bp = bnb.get("properties", {})
            items = bp.get("items", [])
            nav_html = '<div class="bottom-nav">'
            for item in items:
                ip = item.get("properties", {})
                label = self._esc(ip.get("label", ""))
                icon_data = ip.get("icon", {})
                icon_name = "circle"
                if isinstance(icon_data, dict):
                    icon_name = icon_data.get("properties", {}).get("icon", "circle")
                mat_icon = self._material_icon_name(icon_name)
                nav_html += f'<div class="bottom-nav-item"><span class="material-icons material-icon">{mat_icon}</span><span>{label}</span></div>'
            nav_html += '</div>'
            parts.append(nav_html)

        parts.append('</div>')
        return "".join(parts)

    def _render_text(self, props: Dict[str, Any]) -> str:
        text = self._esc(props.get("text", ""))
        size = props.get("fontSize", 14)
        color = self._css_color(props.get("color", "black"))
        weight = "bold" if props.get("fontWeight") == "bold" else "normal"
        align = props.get("textAlign", "left")
        return f'<div class="w-text" style="font-size:{size}px;color:{color};font-weight:{weight};text-align:{align};">{text}</div>'

    def _render_container(self, props: Dict[str, Any], children_html: str) -> str:
        styles = []
        if "color" in props:
            styles.append(f"background:{self._css_color(props['color'])}")
        if "padding" in props:
            styles.append(f"padding:{props['padding']}px")
        if "margin" in props:
            styles.append(f"margin:{props['margin']}px")
        if "width" in props:
            styles.append(f"width:{props['width']}px")
        if "height" in props:
            styles.append(f"height:{props['height']}px")
        return f'<div style="{";".join(styles)}">{children_html}</div>'

    def _render_icon(self, props: Dict[str, Any]) -> str:
        name = self._material_icon_name(props.get("icon", "star"))
        size = props.get("size", 24)
        color = self._css_color(props.get("color", "black"))
        return f'<span class="material-icons" style="font-size:{size}px;color:{color};">{name}</span>'

    def _flex_style(self, props: Dict[str, Any]) -> str:
        styles = []
        ma = (props.get("mainAxisAlignment") or "").lower()
        ca = (props.get("crossAxisAlignment") or "").lower()
        jc_map = {"center": "center", "end": "flex-end", "start": "flex-start",
                   "spacebetween": "space-between", "spacearound": "space-around", "spaceevenly": "space-evenly"}
        ai_map = {"center": "center", "end": "flex-end", "start": "flex-start", "stretch": "stretch"}
        if ma in jc_map:
            styles.append(f"justify-content:{jc_map[ma]}")
        if ca in ai_map:
            styles.append(f"align-items:{ai_map[ca]}")
        return ";".join(styles)

    @staticmethod
    def _css_color(color) -> str:
        if not color:
            return "inherit"
        c = str(color).lower()
        mapping = {"grey": "#9e9e9e", "gray": "#9e9e9e", "transparent": "transparent"}
        return mapping.get(c, c)

    @staticmethod
    def _material_icon_name(name: str) -> str:
        mapping = {
            "person": "person", "home": "home", "settings": "settings",
            "star": "star", "favorite": "favorite", "search": "search",
            "menu": "menu", "close": "close", "check": "check",
            "public": "public", "pie_chart": "pie_chart",
            "shopping_cart": "shopping_cart", "image": "image",
        }
        return mapping.get(str(name).lower(), "widgets")

    @staticmethod
    def _esc(text) -> str:
        return str(text).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")

    def export_to_json(self, widget_schema: Dict[str, Any], filename: str):
        """Export widget schema to JSON file"""
        with open(filename, 'w') as f:
            json.dump(widget_schema, f, indent=2)
        print(f"✓ Exported to {filename}")

    def import_from_json(self, filename: str) -> Dict[str, Any]:
        """Import widget schema from JSON file"""
        with open(filename, 'r') as f:
            return json.load(f)


def main():
    """Demo usage of the Flutter UI Agent"""
    
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("Error: GOOGLE_API_KEY not found. Set it in .env.example or as an environment variable.")
        return
    
    # Initialize agent
    agent = FlutterUIAgent(api_key)
    
    # Example descriptions
    examples = [
        "Create a login screen with email and password fields and a blue login button",
        "Design a profile card with user name, avatar, and bio",
        "Build a product list with 3 items showing image, title, and price"
    ]
    
    print("Flutter UI Agent - Demo\n")
    print("Choose an example or enter your own description:\n")
    for i, example in enumerate(examples, 1):
        print(f"{i}. {example}")
    print(f"{len(examples) + 1}. Custom description")

    choice = input(f"\nEnter choice (1-{len(examples) + 1}): ").strip()

    if choice.isdigit() and 1 <= int(choice) <= len(examples):
        description = examples[int(choice) - 1]
    else:
        description = input("Enter your UI description: ")

    # Attachment option
    attachment_path = None
    attach = input("\nAttach a file as reference? (image/HTML/CSS/JSON/TXT) (y/n): ").strip().lower()
    if attach == 'y':
        attachment_path = input("Enter file path: ").strip().strip('"').strip("'")
        if attachment_path and not os.path.isfile(attachment_path):
            print(f"Warning: File not found: {attachment_path}")
            attachment_path = None
        elif attachment_path:
            supported = ('.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp',
                         '.html', '.css', '.json', '.txt', '.xml', '.svg')
            if not attachment_path.lower().endswith(supported):
                print(f"Warning: Unsupported format. Supported: {', '.join(supported)}")
                attachment_path = None
            else:
                print(f"Attached: {os.path.basename(attachment_path)}")

    print(f"\nGenerating UI for: {description}")
    if attachment_path:
        print(f"   With reference: {os.path.basename(attachment_path)}")
    print()

    # Generate UI
    widget_schema = agent.generate_ui(description, attachment_path=attachment_path)

    # Preview in browser before exporting
    print("🖥️  Opening preview in browser...")
    agent.preview_in_browser(widget_schema)

    # Ask user to confirm
    export = input("\nExport this design? (y/n): ").strip().lower()
    if export != 'y':
        print("Discarded. Run again to regenerate.")
        return

    # Export to JSON
    json_file = "ui_schema.json"
    agent.export_to_json(widget_schema, json_file)

    # Generate Flutter code
    flutter_code = agent.generate_flutter_code(widget_schema)

    # Save Flutter code
    dart_file = "generated_widget.dart"
    is_app_schema = "screens" in widget_schema or "navigation" in widget_schema
    with open(dart_file, 'w') as f:
        f.write("import 'package:flutter/material.dart';\n\n")
        if is_app_schema:
            f.write("// App-level schema detected.\n")
            f.write("// This schema is rendered by AppSchemaRenderer at runtime.\n")
            f.write("// See lib/app_schema_renderer.dart\n")
            f.write("// The ui_schema.json file is loaded automatically by the app.\n")
        else:
            f.write("class GeneratedWidget extends StatelessWidget {\n")
            f.write("  @override\n")
            f.write("  Widget build(BuildContext context) {\n")
            f.write(f"    return {flutter_code.strip()};\n")
            f.write("  }\n")
            f.write("}\n")

    print(f"✓ Generated Flutter code saved to {dart_file}")
    print(f"\n📋 Generated Widget Schema:\n")
    print(json.dumps(widget_schema, indent=2))


if __name__ == "__main__":
    main()
