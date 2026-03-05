import 'package:flutter/material.dart';
import 'dart:convert';

/// Dynamic Widget Builder - Renders Flutter widgets from JSON schema
class DynamicWidgetBuilder {
  /// Build a widget from JSON schema
  static Widget fromJson(Map<String, dynamic> json) {
    final String type = json['type'] ?? 'Container';
    final Map<String, dynamic> properties = json['properties'] ?? {};
    final List<dynamic> childrenJson = json['children'] ?? [];

    // Build children recursively
    List<Widget> children = childrenJson
        .map((child) => fromJson(child as Map<String, dynamic>))
        .toList();

    // Build widget based on type
    return _buildWidget(type, properties, children, childrenJson);
  }

  /// Build specific widget type
  static Widget _buildWidget(
    String type,
    Map<String, dynamic> properties,
    List<Widget> children,
    List<dynamic> childrenJson,
  ) {
    switch (type.toLowerCase()) {
      case 'container':
        return _buildContainer(properties, children);
      case 'column':
        return Column(
          mainAxisAlignment: _getMainAxisAlignment(properties),
          crossAxisAlignment: _getCrossAxisAlignment(properties),
          children: children,
        );
      case 'row':
        return _buildRow(properties, children, childrenJson);
      case 'wrap':
        return Wrap(
          spacing: _toDouble(properties['spacing']) ?? 0,
          runSpacing: _toDouble(properties['runSpacing']) ?? 0,
          children: children,
        );
      case 'text':
        return _buildText(properties);
      case 'elevatedbutton':
      case 'button':
        return _buildButton(properties, children);
      case 'card':
        return _buildCard(properties, children);
      case 'padding':
        return _buildPadding(properties, children);
      case 'center':
        return Center(child: children.isNotEmpty ? children.first : null);
      case 'expanded':
        return Expanded(
          flex: properties['flex'] ?? 1,
          child: children.isNotEmpty ? children.first : Container(),
        );
      case 'singlechildscrollview':
        return SingleChildScrollView(
          child: children.isNotEmpty ? children.first : Container(),
        );
      case 'listview':
        return _buildListView(properties, children);
      case 'sizedbox':
        return SizedBox(
          width: _toDouble(properties['width']),
          height: _toDouble(properties['height']),
          child: children.isNotEmpty ? children.first : null,
        );
      case 'stack':
        return Stack(children: children);
      case 'image':
        return _buildImage(properties);
      case 'icon':
        return _buildIcon(properties);
      case 'textfield':
        return _buildTextField(properties);
      case 'scaffold':
        return _buildScaffold(properties, children);
      default:
        return Container(
          child: children.isNotEmpty ? children.first : null,
        );
    }
  }

  /// Build Row widget with responsive children
  static Widget _buildRow(
    Map<String, dynamic> properties,
    List<Widget> children,
    List<dynamic> childrenJson,
  ) {
    final responsiveChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      final childType = i < childrenJson.length
          ? ((childrenJson[i] as Map<String, dynamic>?)?['type']?.toString().toLowerCase() ?? '')
          : '';
      // Don't wrap already-flexible or fixed-size types
      if (childType == 'expanded' || childType == 'sizedbox' || childType == 'icon') {
        responsiveChildren.add(children[i]);
      } else {
        responsiveChildren.add(Flexible(fit: FlexFit.loose, child: children[i]));
      }
    }
    return Row(
      mainAxisAlignment: _getMainAxisAlignment(properties),
      crossAxisAlignment: _getCrossAxisAlignment(properties),
      children: responsiveChildren,
    );
  }

  /// Build Container widget
  static Widget _buildContainer(
    Map<String, dynamic> properties,
    List<Widget> children,
  ) {
    final hasDecoration = properties['decoration'] != null;
    final requestedWidth = _toDouble(properties['width']);
    final requestedHeight = _toDouble(properties['height']);
    final child = children.isNotEmpty
        ? (children.length == 1 ? children.first : Column(children: children))
        : null;

    // Use constraints instead of fixed width to prevent overflow
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : double.infinity;
        final effectiveWidth = requestedWidth != null
            ? (requestedWidth > maxW ? maxW : requestedWidth)
            : null;

        return Container(
          width: effectiveWidth,
          height: requestedHeight,
          color: hasDecoration ? null : _parseColor(properties['color'] ?? properties['backgroundColor']),
          padding: _parseEdgeInsets(properties['padding']),
          margin: _parseEdgeInsets(properties['margin']),
          alignment: _parseAlignment(properties['alignment']),
          decoration: hasDecoration
              ? _parseDecoration(properties['decoration'], properties['backgroundColor'])
              : null,
          child: child,
        );
      },
    );
  }

  /// Build Text widget
  static Widget _buildText(Map<String, dynamic> properties) {
    final maxLines = properties['maxLines'] as int?;
    return Text(
      properties['text']?.toString() ?? '',
      style: TextStyle(
        fontSize: _toDouble(properties['fontSize']) ?? 14.0,
        color: _parseColor(properties['color']),
        fontWeight: _parseFontWeight(properties['fontWeight']),
      ),
      textAlign: _parseTextAlign(properties['textAlign']),
      softWrap: true,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      maxLines: maxLines,
    );
  }

  /// Build Button widget
  static Widget _buildButton(
    Map<String, dynamic> properties,
    List<Widget> children,
  ) {
    final String text = properties['text']?.toString() ?? 'Button';
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: _parseColor(properties['backgroundColor'] ?? properties['color']),
        foregroundColor: _parseColor(properties['textColor']),
        padding: _parseEdgeInsets(properties['padding']) ??
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: children.isNotEmpty ? children.first : Text(text),
    );
  }

  /// Build Card widget
  static Widget _buildCard(
    Map<String, dynamic> properties,
    List<Widget> children,
  ) {
    return Card(
      color: _parseColor(properties['color']),
      elevation: _toDouble(properties['elevation']) ?? 2.0,
      margin: _parseEdgeInsets(properties['margin']),
      child: children.isNotEmpty
          ? (children.length == 1 ? children.first : Column(children: children))
          : null,
    );
  }

  /// Build Padding widget
  static Widget _buildPadding(
    Map<String, dynamic> properties,
    List<Widget> children,
  ) {
    return Padding(
      padding: _parseEdgeInsets(properties['padding']) ?? EdgeInsets.all(8.0),
      child: children.isNotEmpty ? children.first : Container(),
    );
  }

  /// Build ListView widget
  static Widget _buildListView(
    Map<String, dynamic> properties,
    List<Widget> children,
  ) {
    final bool shrinkWrap = properties['shrinkWrap'] == true;
    final ScrollPhysics? physics =
        properties['physics']?.toString().toLowerCase() == 'never'
            ? const NeverScrollableScrollPhysics()
            : null;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }

  /// Build Image widget
  static Widget _buildImage(Map<String, dynamic> properties) {
    final String? url = properties['url'];
    final String? asset = properties['asset'];
    final fit = BoxFit.contain;
    final width = _toDouble(properties['width']);
    final height = _toDouble(properties['height']);

    Widget image;
    if (url != null) {
      image = Image.network(url, fit: fit, width: width, height: height);
    } else if (asset != null) {
      image = Image.asset(asset, fit: fit, width: width, height: height);
    } else {
      return Icon(Icons.image, size: 50);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? 300,
      ),
      child: image,
    );
  }

  /// Build Icon widget
  static Widget _buildIcon(Map<String, dynamic> properties) {
    return Icon(
      _parseIconData(properties['icon'] ?? properties['iconName']),
      size: _toDouble(properties['size']) ?? 24.0,
      color: _parseColor(properties['color']),
    );
  }

  /// Build TextField widget
  static Widget _buildTextField(Map<String, dynamic> properties) {
    return TextField(
      decoration: InputDecoration(
        hintText: properties['hint']?.toString(),
        labelText: properties['label']?.toString(),
        border: OutlineInputBorder(),
      ),
      obscureText: properties['obscureText'] == true,
    );
  }

  /// Build Scaffold widget
  static Widget _buildScaffold(
    Map<String, dynamic> properties,
    List<Widget> children,
  ) {
    return Scaffold(
      backgroundColor: _parseColor(properties['backgroundColor']),
      appBar: _buildAppBarFromJson(properties['appBar']),
      body: properties['body'] != null
          ? fromJson(properties['body'] as Map<String, dynamic>)
          : (children.isNotEmpty ? children.first : Container()),
      bottomNavigationBar:
          _buildBottomNavBarFromJson(properties['bottomNavigationBar']),
    );
  }

  /// Build AppBar from nested JSON
  static PreferredSizeWidget? _buildAppBarFromJson(dynamic appBarJson) {
    if (appBarJson == null || appBarJson is! Map<String, dynamic>) return null;
    final props = appBarJson['properties'] as Map<String, dynamic>? ?? {};

    Widget? titleWidget;
    if (props['title'] is Map<String, dynamic>) {
      titleWidget = fromJson(props['title'] as Map<String, dynamic>);
    } else if (props['title'] is String) {
      titleWidget = Text(props['title'] as String);
    }

    return AppBar(
      title: titleWidget,
      backgroundColor: _parseColor(props['backgroundColor']),
      foregroundColor: _parseColor(props['foregroundColor']),
      centerTitle: props['centerTitle'] as bool?,
    );
  }

  /// Build BottomNavigationBar from nested JSON
  static Widget? _buildBottomNavBarFromJson(dynamic navJson) {
    if (navJson == null || navJson is! Map<String, dynamic>) return null;
    final props = navJson['properties'] as Map<String, dynamic>? ?? {};
    final items = (props['items'] as List<dynamic>?) ??
        (navJson['children'] as List<dynamic>?) ??
        [];

    if (items.isEmpty) return null;

    final navItems = items.map<BottomNavigationBarItem>((item) {
      final itemProps =
          (item as Map<String, dynamic>)['properties'] as Map<String, dynamic>? ?? {};
      Widget icon = Icon(Icons.circle);
      if (itemProps['icon'] is Map<String, dynamic>) {
        icon = fromJson(itemProps['icon'] as Map<String, dynamic>);
      }
      return BottomNavigationBarItem(
        icon: icon,
        label: itemProps['label']?.toString() ?? '',
      );
    }).toList();

    return BottomNavigationBar(
      items: navItems,
      backgroundColor: _parseColor(props['backgroundColor']),
      selectedItemColor: _parseColor(props['selectedItemColor']),
      unselectedItemColor: _parseColor(props['unselectedItemColor']),
      type: BottomNavigationBarType.fixed,
    );
  }

  // ========== Helper Methods ==========

  static Color? _parseColor(dynamic colorValue) {
    if (colorValue == null) return null;
    final String color = colorValue.toString().toLowerCase();
    
    switch (color) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'white': return Colors.white;
      case 'black': return Colors.black;
      case 'grey': case 'gray': return Colors.grey;
      case 'yellow': return Colors.yellow;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'transparent': return Colors.transparent;
      case 'lightblue': return Colors.lightBlue;
      case 'darkblue': return Color(0xFF0D47A1);
      case 'darkgrey': case 'darkgray': return Colors.grey.shade700;
      case 'lightgrey': case 'lightgray': return Colors.grey.shade300;
      case 'teal': return Colors.teal;
      case 'cyan': return Colors.cyan;
      case 'amber': return Colors.amber;
      case 'indigo': return Colors.indigo;
      case 'brown': return Colors.brown;
      default:
        // Try parsing hex color
        if (color.startsWith('#')) {
          try {
            return Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);
          } catch (e) {
            return null;
          }
        }
        return null;
    }
  }

  static EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return EdgeInsets.all(value.toDouble());
    }
    if (value is Map) {
      final map = value as Map<String, dynamic>;
      if (map.containsKey('all')) {
        return EdgeInsets.all((map['all'] as num).toDouble());
      }
      if (map.containsKey('horizontal') || map.containsKey('vertical')) {
        return EdgeInsets.symmetric(
          horizontal: (map['horizontal'] as num?)?.toDouble() ?? 0,
          vertical: (map['vertical'] as num?)?.toDouble() ?? 0,
        );
      }
      return EdgeInsets.only(
        left: (map['left'] as num?)?.toDouble() ?? 0,
        top: (map['top'] as num?)?.toDouble() ?? 0,
        right: (map['right'] as num?)?.toDouble() ?? 0,
        bottom: (map['bottom'] as num?)?.toDouble() ?? 0,
      );
    }
    return EdgeInsets.all(8.0);
  }

  static Alignment? _parseAlignment(dynamic value) {
    if (value == null) return null;
    final String alignment = value.toString().toLowerCase();
    
    switch (alignment) {
      case 'center': return Alignment.center;
      case 'topleft': return Alignment.topLeft;
      case 'topright': return Alignment.topRight;
      case 'bottomleft': return Alignment.bottomLeft;
      case 'bottomright': return Alignment.bottomRight;
      case 'centerleft': return Alignment.centerLeft;
      case 'centerright': return Alignment.centerRight;
      case 'topcenter': return Alignment.topCenter;
      case 'bottomcenter': return Alignment.bottomCenter;
      default: return null;
    }
  }

  static MainAxisAlignment _getMainAxisAlignment(Map<String, dynamic> properties) {
    final String? value = properties['mainAxisAlignment']?.toString().toLowerCase();
    switch (value) {
      case 'start': return MainAxisAlignment.start;
      case 'end': return MainAxisAlignment.end;
      case 'center': return MainAxisAlignment.center;
      case 'spacebetween': return MainAxisAlignment.spaceBetween;
      case 'spacearound': return MainAxisAlignment.spaceAround;
      case 'spaceevenly': return MainAxisAlignment.spaceEvenly;
      default: return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment _getCrossAxisAlignment(Map<String, dynamic> properties) {
    final String? value = properties['crossAxisAlignment']?.toString().toLowerCase();
    switch (value) {
      case 'start': return CrossAxisAlignment.start;
      case 'end': return CrossAxisAlignment.end;
      case 'center': return CrossAxisAlignment.center;
      case 'stretch': return CrossAxisAlignment.stretch;
      default: return CrossAxisAlignment.center;
    }
  }

  static TextAlign? _parseTextAlign(dynamic value) {
    if (value == null) return null;
    final String align = value.toString().toLowerCase();
    
    switch (align) {
      case 'left': return TextAlign.left;
      case 'right': return TextAlign.right;
      case 'center': return TextAlign.center;
      case 'justify': return TextAlign.justify;
      default: return null;
    }
  }

  static FontWeight? _parseFontWeight(dynamic value) {
    if (value == null) return null;
    final String weight = value.toString().toLowerCase();
    
    switch (weight) {
      case 'bold': return FontWeight.bold;
      case 'normal': return FontWeight.normal;
      case 'light': return FontWeight.w300;
      default: return null;
    }
  }

  static BoxDecoration? _parseDecoration(dynamic value, [dynamic bgColor]) {
    if (value is! Map) return null;
    final Map<String, dynamic> decoration = value as Map<String, dynamic>;

    Border? border;
    if (decoration['border'] is Map) {
      final b = decoration['border'] as Map<String, dynamic>;
      border = Border.all(
        color: _parseColor(b['color']) ?? Colors.grey,
        width: _toDouble(b['width']) ?? 1.0,
      );
    }

    return BoxDecoration(
      color: _parseColor(decoration['color'] ?? bgColor),
      borderRadius: decoration['borderRadius'] != null
          ? BorderRadius.circular(_toDouble(decoration['borderRadius']) ?? 0)
          : null,
      border: border,
    );
  }

  static IconData _parseIconData(dynamic value) {
    if (value == null) return Icons.star;
    final String icon = value.toString().toLowerCase();
    
    switch (icon) {
      case 'home': return Icons.home;
      case 'person': return Icons.person;
      case 'settings': return Icons.settings;
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      case 'search': return Icons.search;
      case 'menu': return Icons.menu;
      case 'close': return Icons.close;
      case 'check': return Icons.check;
      case 'public': return Icons.public;
      case 'pie_chart': return Icons.pie_chart;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'show_chart': return Icons.show_chart;
      case 'add_shopping_cart': return Icons.add_shopping_cart;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'build': return Icons.build;
      case 'lightbulb': return Icons.lightbulb;
      case 'notifications': return Icons.notifications;
      case 'email': return Icons.email;
      case 'phone': return Icons.phone;
      case 'camera': return Icons.camera;
      case 'delete': return Icons.delete;
      case 'edit': return Icons.edit;
      case 'add': return Icons.add;
      case 'remove': return Icons.remove;
      case 'arrow_back': return Icons.arrow_back;
      case 'arrow_forward': return Icons.arrow_forward;
      case 'info': return Icons.info;
      case 'warning': return Icons.warning;
      case 'error': return Icons.error;
      case 'lock': return Icons.lock;
      case 'visibility': return Icons.visibility;
      case 'dashboard': return Icons.dashboard;
      case 'list': return Icons.list;
      case 'cloud': return Icons.cloud;
      case 'download': return Icons.download;
      case 'upload': return Icons.upload;
      case 'share': return Icons.share;
      case 'map': return Icons.map;
      case 'location_on': return Icons.location_on;
      case 'calendar_today': return Icons.calendar_today;
      case 'access_time': return Icons.access_time;
      default: return Icons.widgets;
    }
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Example usage widget
class JsonUIDemo extends StatefulWidget {
  @override
  _JsonUIDemoState createState() => _JsonUIDemoState();
}

class _JsonUIDemoState extends State<JsonUIDemo> {
  Widget? _dynamicWidget;

  @override
  void initState() {
    super.initState();
    _loadJsonUI();
  }

  Future<void> _loadJsonUI() async {
    // Load JSON from assets or API
    final String jsonString = '''
    {
      "type": "Container",
      "properties": {
        "padding": 16,
        "color": "white"
      },
      "children": [
        {
          "type": "Column",
          "properties": {
            "mainAxisAlignment": "center"
          },
          "children": [
            {
              "type": "Text",
              "properties": {
                "text": "Dynamic UI from JSON",
                "fontSize": 24,
                "fontWeight": "bold"
              },
              "children": []
            },
            {
              "type": "SizedBox",
              "properties": {"height": 20},
              "children": []
            },
            {
              "type": "ElevatedButton",
              "properties": {
                "text": "Click Me",
                "color": "blue"
              },
              "children": []
            }
          ]
        }
      ]
    }
    ''';

    final Map<String, dynamic> jsonData = json.decode(jsonString);
    setState(() {
      _dynamicWidget = DynamicWidgetBuilder.fromJson(jsonData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dynamic UI from JSON')),
      body: _dynamicWidget ?? Center(child: CircularProgressIndicator()),
    );
  }
}
