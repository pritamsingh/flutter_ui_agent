import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, Clipboard, ClipboardData;
import 'package:flutter_ui_agent/dynamic_widget_builder.dart';
import 'package:flutter_ui_agent/app_schema_renderer.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _loadFromSchema();
  }

  bool _isAppSchema = false;

  Future<void> _loadFromSchema() async {
    try {
      final jsonString = await rootBundle.loadString('ui_schema.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final isApp = jsonData.containsKey('screens') || jsonData.containsKey('navigation');
      setState(() {
        _currentExample = 'ui_schema.json';
        _schemaData = jsonData;
        _isAppSchema = isApp;
        _currentWidget = isApp
            ? AppSchemaRenderer(schema: jsonData)
            : DynamicWidgetBuilder.fromJson(jsonData);
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
    if (_currentWidget == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading ui_schema.json...',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // App-level schemas and Scaffold/ListView/ScrollView render directly
    if (_isAppSchema) {
      return _currentWidget!;
    }

    final rootType = _schemaData?['type']?.toString().toLowerCase() ?? '';
    const directRenderTypes = {'scaffold', 'listview', 'singlechildscrollview'};
    if (directRenderTypes.contains(rootType)) {
      return _currentWidget!;
    }

    return Scaffold(
      body: SafeArea(child: _currentWidget!),
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
