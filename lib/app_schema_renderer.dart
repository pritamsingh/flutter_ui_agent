import 'package:flutter/material.dart';

/// Renders app-level JSON schemas that have screens, navigation, modals, etc.
/// Detects format: root has "screens" and/or "navigation" keys (no root "type").
class AppSchemaRenderer extends StatefulWidget {
  final Map<String, dynamic> schema;
  const AppSchemaRenderer({Key? key, required this.schema}) : super(key: key);

  @override
  State<AppSchemaRenderer> createState() => _AppSchemaRendererState();
}

class _AppSchemaRendererState extends State<AppSchemaRenderer> {
  late String _currentScreenId;
  late Map<String, dynamic> _tokens;
  late Map<String, dynamic> _navigation;
  late List<dynamic> _screens;

  @override
  void initState() {
    super.initState();
    final meta = widget.schema['meta'] as Map<String, dynamic>? ?? {};
    _tokens = widget.schema['designTokens'] as Map<String, dynamic>? ?? {};
    _navigation = widget.schema['navigation'] as Map<String, dynamic>? ?? {};
    _screens = widget.schema['screens'] as List<dynamic>? ?? [];
    _currentScreenId = meta['initialScreen']?.toString() ??
        (_screens.isNotEmpty ? _screens.first['id'] : '');
  }

  Map<String, dynamic>? get _currentScreen {
    for (final s in _screens) {
      if (s is Map<String, dynamic> && s['id'] == _currentScreenId) return s;
    }
    return _screens.isNotEmpty ? _screens.first as Map<String, dynamic> : null;
  }

  Color _tokenColor(String? token) {
    if (token == null) return Colors.grey;
    final colors = _tokens['colors'] as Map<String, dynamic>? ?? {};
    final hex = colors[token]?.toString() ?? token;
    if (hex.startsWith('#')) {
      final code = hex.substring(1);
      return Color(int.parse(code.padLeft(8, 'F'), radix: 16));
    }
    return Colors.grey;
  }

  void _navigate(String screenId) {
    setState(() => _currentScreenId = screenId);
  }

  @override
  Widget build(BuildContext context) {
    final screen = _currentScreen;
    final showNav = screen?['showNav'] == true;
    final noNavScreens =
        (widget.schema['meta']?['noNavScreens'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: _tokenColor('slate50'),
      drawer: showNav && !noNavScreens.contains(_currentScreenId)
          ? _buildDrawer()
          : null,
      appBar: _buildTopBar(screen),
      body: _buildScreenBody(screen),
    );
  }

  // === Navigation Drawer ===
  Drawer _buildDrawer() {
    final logo = _navigation['logo'] as Map<String, dynamic>? ?? {};
    final user = _navigation['user'] as Map<String, dynamic>? ?? {};
    final sections = _navigation['sections'] as List<dynamic>? ?? [];

    return Drawer(
      backgroundColor: _tokenColor('slate900'),
      child: Column(
        children: [
          // Logo
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _tokenColor('blue600'),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(logo['mark']?.toString() ?? '',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                SizedBox(width: 10),
                Text(logo['text']?.toString() ?? '',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
          Divider(color: Colors.white24, height: 1),
          // Sections
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: sections.map<Widget>((section) {
                final sec = section as Map<String, dynamic>;
                final label = sec['label']?.toString() ?? '';
                final items = sec['items'] as List<dynamic>? ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(label,
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                    ),
                    ...items.map<Widget>((item) {
                      final it = item as Map<String, dynamic>;
                      final isActive = it['id'] == 'nav-${_currentScreenId}' ||
                          (it['onClick'] is Map &&
                              (it['onClick'] as Map)['screen'] ==
                                  _currentScreenId);
                      final badge = it['badge'];
                      return ListTile(
                        dense: true,
                        selected: isActive,
                        selectedTileColor: Colors.white.withValues(alpha: 0.08),
                        leading: Icon(_mapIcon(it['icon']?.toString()),
                            color: isActive ? Colors.white : Colors.white60,
                            size: 20),
                        title: Text(it['label']?.toString() ?? '',
                            style: TextStyle(
                                color: isActive ? Colors.white : Colors.white70,
                                fontSize: 14)),
                        trailing: badge != null &&
                                badge is Map &&
                                badge['count'] != null
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color:
                                        _tokenColor(badge['color']?.toString()),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(badge['count'].toString(),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              )
                            : null,
                        onTap: () {
                          final onClick =
                              it['onClick'] as Map<String, dynamic>?;
                          if (onClick != null && onClick['screen'] != null) {
                            _navigate(onClick['screen']);
                            Navigator.pop(context);
                          }
                        },
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
          // User
          Divider(color: Colors.white24, height: 1),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _tokenColor('blue600'),
                  child: Text(user['initials']?.toString() ?? '',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name']?.toString() ?? '',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      Text(user['role']?.toString() ?? '',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === Top Bar ===
  PreferredSizeWidget? _buildTopBar(Map<String, dynamic>? screen) {
    if (screen == null) return null;
    final regions = screen['regions'] as Map<String, dynamic>? ?? {};
    final topBar = regions['top'] as Map<String, dynamic>?;
    final title =
        topBar?['title']?.toString() ?? screen['title']?.toString() ?? '';
    final badge = topBar?['badge'];
    final backButton = topBar?['backButton'];

    return AppBar(
      backgroundColor: _tokenColor('white'),
      foregroundColor: _tokenColor('slate900'),
      elevation: 0.5,
      leading: backButton != null
          ? IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                final onClick = backButton['onClick'] as Map<String, dynamic>?;
                if (onClick != null && onClick['screen'] != null) {
                  _navigate(onClick['screen']);
                }
              },
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (badge is Map) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _tokenColor(badge['color']?.toString()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge['label']?.toString() ?? '',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
      actions: _buildTopBarActions(topBar),
    );
  }

  List<Widget> _buildTopBarActions(Map<String, dynamic>? topBar) {
    if (topBar == null) return [];
    final actions = topBar['actions'] as List<dynamic>? ?? [];
    return actions.map<Widget>((a) {
      final action = a as Map<String, dynamic>;
      final label = action['label']?.toString() ?? '';
      final icon = action['icon']?.toString();
      final variant = action['variant']?.toString() ?? '';

      if (variant.contains('primary') || variant.contains('bevel')) {
        return Padding(
          padding: EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _handleAction(action['onClick']),
            icon: icon != null
                ? Icon(_mapIcon(icon), size: 16)
                : SizedBox.shrink(),
            label: Text(label, style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: variant.contains('violet')
                  ? _tokenColor('violet700')
                  : _tokenColor('blue600'),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(0, 34),
            ),
          ),
        );
      }
      if (variant.contains('danger') || label == 'KILL SWITCH') {
        return Padding(
          padding: EdgeInsets.only(right: 8),
          child: OutlinedButton(
            onPressed: () => _handleAction(action['onClick']),
            style: OutlinedButton.styleFrom(
              foregroundColor: _tokenColor('red600'),
              side: BorderSide(color: _tokenColor('red600')),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(0, 34),
            ),
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );
      }
      return TextButton(
        onPressed: () => _handleAction(action['onClick']),
        child: Text(label,
            style: TextStyle(fontSize: 13, color: _tokenColor('gray500'))),
      );
    }).toList();
  }

  // === Screen Body ===
  Widget _buildScreenBody(Map<String, dynamic>? screen) {
    if (screen == null) {
      return Center(
          child: Text('No screen found', style: TextStyle(color: Colors.grey)));
    }

    final regions = screen['regions'] as Map<String, dynamic>? ?? {};
    final widgets = screen['widgets'] as List<dynamic>?;
    final layout = screen['layout']?.toString() ?? '';

    // Section tabs
    final topTabs = regions['top_tabs'] as Map<String, dynamic>?;

    // Settings layout
    if (layout == 'settingsLayout') {
      return _buildSettingsLayout(screen, regions);
    }

    // Centered layout (login, 2FA)
    if (layout == 'centered' && widgets != null) {
      return _buildCenteredLayout(widgets);
    }

    // Screen grid with regions
    final List<Widget> bodyParts = [];

    if (topTabs != null) {
      bodyParts.add(_buildSectionTabs(topTabs));
    }

    // Left sidebar + center + right
    final left = regions['left'];
    final center = regions['center'];
    final right = regions['right'];
    final bottom = regions['bottom'];

    if (left != null || right != null) {
      bodyParts.add(Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (isNarrow) {
              // Mobile: stack vertically
              return ListView(
                children: [
                  if (left != null)
                    SizedBox(height: 220, child: _buildRegionWidget(left)),
                  if (center != null)
                    SizedBox(height: 400, child: _buildRegionWidget(center)),
                  if (right != null)
                    SizedBox(height: 300, child: _buildRegionWidget(right)),
                ],
              );
            }
            // Desktop: proportional widths
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (left != null)
                  SizedBox(
                    width: (constraints.maxWidth * 0.25).clamp(180, 280),
                    child: _buildRegionWidget(left),
                  ),
                if (center != null) Expanded(child: _buildRegionWidget(center)),
                if (right != null)
                  SizedBox(
                    width: (constraints.maxWidth * 0.3).clamp(200, 400),
                    child: _buildRegionWidget(right),
                  ),
              ],
            );
          },
        ),
      ));
    } else if (center != null) {
      bodyParts.add(Expanded(child: _buildRegionWidget(center)));
    }

    if (bottom != null) {
      bodyParts.add(_buildRegionWidget(bottom));
    }

    // Approval panel
    final approval = screen['approvalPanel'] as Map<String, dynamic>?;
    if (approval != null) {
      bodyParts.add(_buildApprovalPanel(approval));
    }

    if (bodyParts.isEmpty) {
      return Center(
        child: Text('Screen: $_currentScreenId',
            style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return Column(children: bodyParts);
  }

  // === Region Widget Rendering ===
  Widget _buildRegionWidget(Map<String, dynamic> region) {
    final type = region['type']?.toString() ?? '';
    switch (type) {
      case 'ConversationSidebar':
        return _buildConversationSidebar(region);
      case 'MessageList':
        return _buildMessageList(region);
      case 'MessageComposer':
        return _buildMessageComposer(region);
      case 'ArtifactPanel':
        return _buildArtifactPanel(region);
      case 'DataTable':
        return _buildDataTable(region);
      case 'VerticalCardList':
        return _buildVerticalCardList(region);
      case 'SettingsForm':
        return _buildSettingsForm(region);
      case 'TaskDetailBody':
        return _buildTaskDetailBody(region);
      case 'Column':
        return _buildColumnRegion(region);
      default:
        return Center(
            child: Text(type.isNotEmpty ? type : 'Empty region',
                style: TextStyle(color: Colors.grey)));
    }
  }

  // === Section Tabs ===
  Widget _buildSectionTabs(Map<String, dynamic> tabsData) {
    final tabs = tabsData['tabs'] as List<dynamic>? ?? [];
    return Container(
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: tabs.map<Widget>((t) {
            final tab = t as Map<String, dynamic>;
            final isActive = tab['active'] == true;
            final label = tab['label']?.toString() ?? '';
            final badge = tab['badge'];
            return Padding(
              padding: EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: () => _handleAction(tab['onClick']),
                style: TextButton.styleFrom(
                  foregroundColor: isActive
                      ? _tokenColor('blue600')
                      : _tokenColor('gray500'),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: Row(
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal)),
                    if (badge != null) ...[
                      SizedBox(width: 6),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(badge.toString(),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade700)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // === Conversation Sidebar ===
  Widget _buildConversationSidebar(Map<String, dynamic> region) {
    final groups = region['groups'] as List<dynamic>? ?? [];
    return Container(
      color: _tokenColor('slate50'),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText:
                    region['searchPlaceholder']?.toString() ?? 'Search...',
                prefixIcon: Icon(Icons.search, size: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 16),
                label: Text(region['newButtonLabel']?.toString() ?? 'New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tokenColor('blue600'),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: groups.map<Widget>((g) {
                final group = g as Map<String, dynamic>;
                final items = group['items'] as List<dynamic>? ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(group['label']?.toString() ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                    ),
                    ...items.map<Widget>((item) {
                      final it = item as Map<String, dynamic>;
                      final isActive = it['active'] == true;
                      return ListTile(
                        dense: true,
                        selected: isActive,
                        selectedTileColor: _tokenColor('blue50'),
                        title: Text(it['title']?.toString() ?? '',
                            style: TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(it['meta']?.toString() ?? '',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        onTap: () {},
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // === Message List ===
  Widget _buildMessageList(Map<String, dynamic> region) {
    final messages = region['messages'] as List<dynamic>? ?? [];
    return ListView(
      padding: EdgeInsets.all(16),
      children: messages.map<Widget>((m) {
        final msg = m as Map<String, dynamic>;
        final role = msg['role']?.toString() ?? '';
        final content = msg['content']?.toString() ?? '';
        final model = msg['model']?.toString();
        final isUser = role == 'user';

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    isUser ? _tokenColor('blue600') : _tokenColor('violet700'),
                child: Text(isUser ? 'U' : 'AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isUser ? 'You' : (model ?? 'Assistant'),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(content, style: TextStyle(fontSize: 14, height: 1.5)),
                    if (msg['artifact'] is Map) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.code,
                                size: 16, color: _tokenColor('blue600')),
                            SizedBox(width: 8),
                            Text(
                                (msg['artifact'] as Map)['title']?.toString() ??
                                    '',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // === Message Composer ===
  Widget _buildMessageComposer(Map<String, dynamic> region) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          IconButton(
              icon: Icon(Icons.attach_file, size: 20),
              onPressed: () {},
              color: Colors.grey),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText:
                    region['placeholder']?.toString() ?? 'Type a message...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, size: 20),
            color: _tokenColor('blue600'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // === Artifact Panel ===
  Widget _buildArtifactPanel(Map<String, dynamic> region) {
    final tabs = region['tabs'] as List<dynamic>? ?? [];
    return Container(
      decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: tabs.map<Widget>((t) {
                final tab = t as Map<String, dynamic>;
                final isActive = tab['active'] == true;
                return TextButton(
                  onPressed: () {},
                  child: Text(tab['label']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? _tokenColor('blue600') : Colors.grey,
                        fontSize: 13,
                      )),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Container(
              color: _tokenColor('slate50'),
              alignment: Alignment.center,
              child: Text('Code preview area',
                  style:
                      TextStyle(color: Colors.grey, fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
    );
  }

  // === Data Table ===
  Widget _buildDataTable(Map<String, dynamic> region) {
    final columns = region['columns'] as List<dynamic>? ?? [];
    final rows = region['rows'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 400),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade200),
            defaultColumnWidth: IntrinsicColumnWidth(),
            children: [
              TableRow(
                decoration: BoxDecoration(color: _tokenColor('slate50')),
                children: columns.map<Widget>((c) {
                  final col = c as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(col['label']?.toString() ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  );
                }).toList(),
              ),
              ...rows.map<TableRow>((r) {
                final row = r as Map<String, dynamic>;
                return TableRow(
                  children: columns.map<Widget>((c) {
                    final col = c as Map<String, dynamic>;
                    final colId = col['id']?.toString() ?? '';
                    final cellValue = row[colId];
                    if (cellValue is Map) {
                      final label = cellValue['label']?.toString() ?? '';
                      final color = cellValue['color']?.toString();
                      return Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: _tokenColor(color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _tokenColor(color),
                                  fontWeight: FontWeight.w500)),
                        ),
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(cellValue?.toString() ?? '',
                          style: TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // === Vertical Card List ===
  Widget _buildVerticalCardList(Map<String, dynamic> region) {
    final items = region['items'] as List<dynamic>? ?? [];
    return ListView(
      padding: EdgeInsets.all(16),
      children: items.map<Widget>((item) {
        final it = item as Map<String, dynamic>;
        final trailing = it['trailing'] as Map<String, dynamic>?;
        final badge = trailing?['badge'] as Map<String, dynamic>?;
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: Icon(_mapIcon(it['icon']?.toString()),
                color: _tokenColor(it['iconColor']?.toString())),
            title: Text(it['title']?.toString() ?? '',
                style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(it['meta']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: badge != null
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _tokenColor(badge['color']?.toString())
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(badge['label']?.toString() ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color: _tokenColor(badge['color']?.toString()),
                            fontWeight: FontWeight.w500)),
                  )
                : null,
            onTap: () => _handleAction(it['onClick']),
          ),
        );
      }).toList(),
    );
  }

  // === Settings Layout ===
  Widget _buildSettingsLayout(
      Map<String, dynamic> screen, Map<String, dynamic> regions) {
    final settingsSections = screen['settingsSections'] as List<dynamic>? ?? [];
    final center = regions['center'] as Map<String, dynamic>?;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: horizontal tabs + content below
          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  children: settingsSections.map<Widget>((s) {
                    final sec = s as Map<String, dynamic>;
                    final isActive = sec['active'] == true;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: ChoiceChip(
                        label: Text(sec['label']?.toString() ?? '',
                            style: TextStyle(fontSize: 12)),
                        selected: isActive,
                        onSelected: (_) {
                          if (sec['screen'] != null) _navigate(sec['screen']);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Divider(height: 1),
              if (center != null) Expanded(child: _buildRegionWidget(center)),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
              child: ListView(
                padding: EdgeInsets.all(12),
                children: settingsSections.map<Widget>((s) {
                  final sec = s as Map<String, dynamic>;
                  final isActive = sec['active'] == true;
                  return ListTile(
                    dense: true,
                    selected: isActive,
                    selectedTileColor: _tokenColor('blue50'),
                    title: Text(sec['label']?.toString() ?? '',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal)),
                    onTap: () {
                      if (sec['screen'] != null) _navigate(sec['screen']);
                    },
                  );
                }).toList(),
              ),
            ),
            VerticalDivider(width: 1),
            if (center != null) Expanded(child: _buildRegionWidget(center)),
          ],
        );
      },
    );
  }

  // === Settings Form ===
  Widget _buildSettingsForm(Map<String, dynamic> region) {
    final fieldGroups = region['fieldGroups'] as List<dynamic>? ?? [];
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...fieldGroups.map<Widget>((fg) {
            final group = fg as Map<String, dynamic>;
            final fields = group['fields'] as List<dynamic>? ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group['title']?.toString() ?? '',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 12),
                ...fields.map<Widget>((f) {
                  final field = f as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: TextEditingController(
                          text: field['value']?.toString() ?? ''),
                      readOnly: field['readonly'] == true,
                      decoration: InputDecoration(
                        labelText: field['label']?.toString(),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  );
                }),
                SizedBox(height: 16),
              ],
            );
          }),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                backgroundColor: _tokenColor('blue600'),
                foregroundColor: Colors.white),
            child: Text(region['saveAction']?['label']?.toString() ?? 'Save'),
          ),
        ],
      ),
    );
  }

  // === Task Detail Body ===
  Widget _buildTaskDetailBody(Map<String, dynamic> region) {
    final fields = region['fields'] as List<dynamic>? ?? [];
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...fields.map<Widget>((f) {
            final field = f as Map<String, dynamic>;
            final type = field['type']?.toString() ?? 'TextInput';
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: TextEditingController(
                    text: field['value']?.toString() ?? ''),
                maxLines: type == 'MultiLineInput' ? 4 : 1,
                decoration: InputDecoration(
                  labelText: field['label']?.toString(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            );
          }),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                backgroundColor: _tokenColor('blue600'),
                foregroundColor: Colors.white),
            child: Text(region['saveAction']?['label']?.toString() ?? 'Save'),
          ),
        ],
      ),
    );
  }

  // === Column Region (e.g., Trading dashboard center) ===
  Widget _buildColumnRegion(Map<String, dynamic> region) {
    final children = region['children'] as List<dynamic>? ?? [];
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map<Widget>((child) {
          final c = child as Map<String, dynamic>;
          final type = c['type']?.toString() ?? '';
          if (type == 'MarketDataCard') return _buildMarketDataCard(c);
          if (type == 'AlgoMonitorCard') return _buildAlgoMonitorCard(c);
          return _buildGenericCard(c);
        }).toList(),
      ),
    );
  }

  // === Market Data Card ===
  Widget _buildMarketDataCard(Map<String, dynamic> card) {
    final rows = card['rows'] as List<dynamic>? ?? [];
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card['title']?.toString() ?? '',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            ...rows.map<Widget>((r) {
              final row = r as Map<String, dynamic>;
              final isUp = row['direction'] == 'up';
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                        width: 100,
                        child: Text(row['symbol']?.toString() ?? '',
                            style: TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(
                        child: Text(row['price']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500))),
                    Icon(isUp ? Icons.trending_up : Icons.trending_down,
                        color: isUp
                            ? _tokenColor('green600')
                            : _tokenColor('red600'),
                        size: 18),
                    SizedBox(width: 4),
                    Text(row['change']?.toString() ?? '',
                        style: TextStyle(
                            color: isUp
                                ? _tokenColor('green600')
                                : _tokenColor('red600'),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // === Algo Monitor Card ===
  Widget _buildAlgoMonitorCard(Map<String, dynamic> card) {
    final stats = card['stats'] as List<dynamic>? ?? [];
    final statusBadge = card['statusBadge'] as Map<String, dynamic>?;
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(card['algorithmName']?.toString() ?? '',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                if (statusBadge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: _tokenColor(statusBadge['color']?.toString())
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(statusBadge['label']?.toString() ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                _tokenColor(statusBadge['color']?.toString()),
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: stats.map<Widget>((s) {
                final stat = s as Map<String, dynamic>;
                final variant = stat['variant']?.toString() ?? '';
                Color valueColor = _tokenColor('slate900');
                if (variant == 'profit') valueColor = _tokenColor('green600');
                if (variant == 'loss') valueColor = _tokenColor('red600');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stat['label']?.toString() ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    SizedBox(height: 2),
                    Text(stat['value']?.toString() ?? '',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: valueColor)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // === Generic Card ===
  Widget _buildGenericCard(Map<String, dynamic> card) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
            card['title']?.toString() ?? card['type']?.toString() ?? 'Card',
            style: TextStyle(fontSize: 14)),
      ),
    );
  }

  // === Centered Layout (Login, 2FA) ===
  Widget _buildCenteredLayout(List<dynamic> widgets) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widgets
                .map<Widget>(
                    (w) => _buildLoginWidget(w as Map<String, dynamic>))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginWidget(Map<String, dynamic> widget) {
    final type = widget['type']?.toString() ?? '';
    final children = widget['children'] as List<dynamic>? ?? [];

    switch (type) {
      case 'Column':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: children
              .map<Widget>((c) => _buildLoginWidget(c as Map<String, dynamic>))
              .toList(),
        );
      case 'AppBrand':
        return Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: _tokenColor('blue600'),
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(widget['mark']?.toString() ?? '',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
              SizedBox(height: 16),
              Text(widget['title']?.toString() ?? '',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(widget['subtitle']?.toString() ?? '',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        );
      case 'Card':
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children
                  .map<Widget>((c) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _buildLoginWidget(c as Map<String, dynamic>),
                      ))
                  .toList(),
            ),
          ),
        );
      case 'BevelButton':
        final variant = widget['variant']?.toString() ?? '';
        return SizedBox(
          width: widget['fullWidth'] == true ? double.infinity : null,
          child: ElevatedButton(
            onPressed: () => _handleAction(widget['onClick']),
            style: ElevatedButton.styleFrom(
              backgroundColor: variant == 'primary'
                  ? _tokenColor('blue600')
                  : variant == 'dark'
                      ? _tokenColor('slate900')
                      : Colors.grey.shade200,
              foregroundColor: variant == 'primary' || variant == 'dark'
                  ? Colors.white
                  : Colors.black87,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget['icon'] != null) ...[
                  Icon(_mapIcon(widget['icon']?.toString()), size: 18),
                  SizedBox(width: 8)
                ],
                Text(widget['label']?.toString() ?? ''),
              ],
            ),
          ),
        );
      case 'FlatButton':
        return TextButton(
          onPressed: () => _handleAction(widget['onClick']),
          child: Text(widget['label']?.toString() ?? '',
              style: TextStyle(color: _tokenColor('blue600'))),
        );
      case 'TextInput':
        return TextField(
          decoration: InputDecoration(
            labelText: widget['label']?.toString(),
            hintText: widget['placeholder']?.toString(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        );
      case 'PasswordInput':
        return TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: widget['label']?.toString(),
            hintText: widget['placeholder']?.toString(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        );
      case 'Divider':
        final label = widget['label']?.toString();
        if (label != null) {
          return Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(label,
                      style: TextStyle(color: Colors.grey, fontSize: 12))),
              Expanded(child: Divider()),
            ],
          );
        }
        return Divider();
      case 'MaskedField':
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget['label']?.toString() ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(widget['value']?.toString() ?? '',
                      style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            TextButton(
                onPressed: () {},
                child: Text(widget['actionLabel']?.toString() ?? '')),
          ],
        );
      case 'RadioGroup':
        final options = widget['options'] as List<dynamic>? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map<Widget>((o) {
            final opt = o as Map<String, dynamic>;
            return RadioListTile<String>(
              dense: true,
              title: Text(opt['label']?.toString() ?? '',
                  style: TextStyle(fontSize: 14)),
              value: opt['value']?.toString() ?? '',
              groupValue: options
                  .firstWhere((x) => (x as Map)['selected'] == true,
                      orElse: () => options.first)['value']
                  ?.toString(),
              onChanged: (_) {},
            );
          }).toList(),
        );
      default:
        return SizedBox.shrink();
    }
  }

  // === Approval Panel ===
  Widget _buildApprovalPanel(Map<String, dynamic> panel) {
    final items = panel['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _tokenColor('amber50'),
        border:
            Border(top: BorderSide(color: _tokenColor('amber500'), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(panel['title']?.toString() ?? '',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          SizedBox(height: 4),
          ...items.map<Widget>((item) {
            final it = item as Map<String, dynamic>;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: _tokenColor('amber500').withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(it['type']?.toString() ?? '',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _tokenColor('amber500'))),
              ),
              title: Text(it['title']?.toString() ?? '',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(it['meta']?.toString() ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              onTap: () => _handleAction(it['onClick']),
            );
          }),
        ],
      ),
    );
  }

  // === Action Handler ===
  void _handleAction(dynamic onClick) {
    if (onClick == null) return;
    if (onClick is List) {
      for (final a in onClick) {
        _handleAction(a);
      }
      return;
    }
    if (onClick is! Map) return;
    final action = onClick['action']?.toString();
    if (action == 'navigate' && onClick['screen'] != null) {
      _navigate(onClick['screen']);
    }
  }

  // === Icon Mapping ===
  IconData _mapIcon(String? name) {
    if (name == null) return Icons.circle;
    switch (name) {
      case 'chat_bubble':
        return Icons.chat_bubble_outline;
      case 'work':
        return Icons.work_outline;
      case 'folder':
        return Icons.folder_outlined;
      case 'bar_chart':
        return Icons.bar_chart;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'bolt':
        return Icons.bolt;
      case 'history':
        return Icons.history;
      case 'settings':
        return Icons.settings_outlined;
      case 'shield':
        return Icons.shield_outlined;
      case 'logout':
        return Icons.logout;
      case 'share':
        return Icons.share;
      case 'expand_more':
        return Icons.expand_more;
      case 'add':
        return Icons.add;
      case 'more_vert':
        return Icons.more_vert;
      case 'content_copy':
        return Icons.content_copy;
      case 'thumb_up':
        return Icons.thumb_up_outlined;
      case 'thumb_down':
        return Icons.thumb_down_outlined;
      case 'edit':
        return Icons.edit;
      case 'send':
        return Icons.send;
      case 'attach_file':
        return Icons.attach_file;
      case 'alternate_email':
        return Icons.alternate_email;
      case 'download':
        return Icons.download;
      case 'code':
        return Icons.code;
      case 'description':
        return Icons.description;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'grid_view':
        return Icons.grid_view;
      case 'search':
        return Icons.search;
      case 'arrow_back':
        return Icons.arrow_back;
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      default:
        return Icons.circle;
    }
  }
}
