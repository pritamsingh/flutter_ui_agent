import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, Clipboard, ClipboardData;
import 'dart:convert';
import 'lib/dynamic_widget_builder.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter UI Agent Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget? _currentWidget;
  String _currentExample = 'None';
  Map<String, dynamic>? _schemaData;

  Future<void> _loadFromSchema() async {
    try {
      final jsonString = await rootBundle.loadString('ui_schema.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _currentExample = 'ui_schema.json';
        _schemaData = jsonData;
        _currentWidget = DynamicWidgetBuilder.fromJson(jsonData);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading schema: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter UI Agent'),
        elevation: 2,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.widgets, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'UI Examples',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.file_open),
              title: Text('Load ui_schema.json'),
              selected: _currentExample == 'ui_schema.json',
              onTap: () {
                Navigator.pop(context);
                _loadFromSchema();
              },
            ),
            // Divider(),
            // ListTile(
            //   leading: Icon(Icons.info),
            //   title: Text('About'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _showAboutDialog(context);
            //   },
            // ),
          ],
        ),
      ),
      body: _currentWidget != null
          ? SingleChildScrollView(
              child: _currentWidget!,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Select an example from the menu',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showJsonDialog(context);
        },
        child: Icon(Icons.code),
        tooltip: 'View JSON Schema',
      ),
    );
  }

  void _showJsonDialog(BuildContext context) {
    if (_currentExample == 'None') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an example first')),
      );
      return;
    }

    final jsonString = JsonEncoder.withIndent('  ').convert(_schemaData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('JSON Schema: $_currentExample'),
        content: SingleChildScrollView(
          child: SelectableText(
            jsonString,
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('JSON copied to clipboard')),
              );
            },
            child: Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Flutter UI Agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dynamic UI from JSON',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'This app demonstrates how to generate Flutter widgets dynamically from JSON schemas using an AI agent.',
            ),
            SizedBox(height: 12),
            Text('Features:'),
            Text('• AI-powered UI generation'),
            Text('• JSON import/export'),
            Text('• Runtime widget rendering'),
            Text('• LangChain integration'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
