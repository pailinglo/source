import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:camera/camera.dart';
import '../models/inventory_model.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';
import 'scan_receipt_screen.dart';
import 'speech_input_screen.dart';

class AddGroceryScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String userId;

  const AddGroceryScreen({
    super.key,
    required this.cameras,
    required this.userId,
  });

  @override
  _AddGroceryScreenState createState() => _AddGroceryScreenState();
}

class _AddGroceryScreenState extends State<AddGroceryScreen> {
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';
  String _lastAdded = '';
  late ApiService _apiService;
  // scroll
  final Map<int, bool> _highlightedItems = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _apiService = ApiService(DatabaseHelper.instance);
    _loadItems();
    _cacheIngredients();
    _scrollController = ScrollController();
  }

  void _loadItems() {
    final inventory = Provider.of<InventoryModel>(context, listen: false);
    inventory.loadItems();
  }

  void _cacheIngredients() async {
    try {
      await _apiService.cacheIngredients();
    } catch (e) {
      print('Failed to cache ingredients: $e');
    }
  }

  void _addItem(InventoryModel inventory) async {
    if (_controller.text.isEmpty) return;

    final item = _controller.text.trim();
    await inventory.addItem(item);

    _lastAdded = item;
    _voiceInput = '';

    // Highlight new item
    final newItem = inventory.items.last;
    _highlightedItems[newItem['id']] = true;

    // Auto-scroll and remove highlight after 3 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _highlightedItems.remove(newItem['id']));
        }
      });
    });
    _controller.clear();
  }

  Widget _buildSortSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text('Sort by:'),
          SizedBox(width: 8),
          DropdownButton<int>(
            value: Provider.of<InventoryModel>(context).sortMode,
            items: [
              DropdownMenuItem(value: 1, child: Text('Recent')),
              DropdownMenuItem(value: 2, child: Text('A-Z')),
              DropdownMenuItem(value: 0, child: Text('Category')),
            ],
            onChanged: (value) {
              Provider.of<InventoryModel>(context, listen: false).sortMode =
                  value!;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(InventoryModel inventory) {
    final items = inventory.sortedItems;

    if (inventory.sortMode == 0) {
      // Category mode
      final categorized = _groupByCategory(items);
      return ListView.builder(
        controller: _scrollController,
        itemCount: categorized.keys.length,
        itemBuilder: (ctx, index) {
          final category = categorized.keys.elementAt(index);
          final categoryItems = categorized[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  category,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...categoryItems.map((item) => _buildItemTile(item)).toList(),
            ],
          );
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: items.length,
        itemBuilder: (ctx, index) => _buildItemTile(items[index]),
      );
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory(
    List<Map<String, dynamic>> items,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    final inventory = Provider.of<InventoryModel>(context, listen: false);

    for (final item in items) {
      final category = inventory.getCategory(item['mapped_name']);
      map.putIfAbsent(category, () => []).add(item);
    }

    // Sort categories alphabetically
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final inventory = Provider.of<InventoryModel>(context, listen: false);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color:
          _highlightedItems.containsKey(item['id'])
              ? Colors.green.withOpacity(0.2)
              : const Color(0xFFEDEDED),
      child: ListTile(
        title: Text(
          item['name']?.toString() ?? 'Unknown Item',
          style: const TextStyle(color: Color(0xFF333333)),
        ),
        subtitle: Text(
          item['synced'] == 1 ? 'Synced' : 'Pending sync',
          style: TextStyle(
            color: item['synced'] == 1 ? Colors.green : Colors.orange,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Color(0xFFD32323)),
          onPressed: () => inventory.removeItem(item['id'] ?? -1),
        ),
      ),
    );
  }

  void _navigateToScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanReceiptScreen(cameras: widget.cameras),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_isListening) {
      _speech.stop();
    }
    _speech.cancel();
    super.dispose();
  }

  Widget _buildInputRow(InventoryModel inventory) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter grocery item (e.g., Tomato)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFEDEDED),
              ),
              onSubmitted: (_) => _addItem(inventory),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _addItem(inventory),
            child: const Text('Add'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.mic_none, color: Colors.grey),
            onPressed: () => _launchSpeechInput(),
            tooltip: 'Voice Input',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.grey),
            onPressed: _navigateToScan,
            tooltip: 'Scan Receipt',
          ),
        ],
      ),
    );
  }

  void _launchSpeechInput() async {
    final List<String>? items = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => SpeechInputScreen(
              onItemsConfirmed: (items) => items, //This can be removed?
            ),
      ),
    );

    print('Received items from speech screen: $items');

    if (items != null && items.isNotEmpty) {
      print('Processing ${items.length} items');
      final inventory = Provider.of<InventoryModel>(context, listen: false);
      for (final item in items) {
        if (item.trim().isNotEmpty) {
          await inventory.addItem(item.trim());

          // Highlight each new item
          final newItem = inventory.items.last;
          _highlightedItems[newItem['id']] = true;

          // Auto-scroll and remove highlight after 3 seconds
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // _scrollController.animateTo(
            //   _scrollController.position.maxScrollExtent,
            //   duration: Duration(milliseconds: 300),
            //   curve: Curves.easeOut,
            // );

            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _highlightedItems.remove(newItem['id']));
              }
            });
          });
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${items.length} item(s)'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Refresh the item list
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Restore the save button
  Widget _buildSaveButton(InventoryModel inventory) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            inventory.hasUnsyncedItems || inventory.hasDeletion
                ? Theme.of(context).primaryColor
                : Colors.grey[400],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed:
            inventory.hasUnsyncedItems || inventory.hasDeletion
                ? () async {
                  try {
                    await inventory.syncItems();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Groceries saved successfully!'),
                      ),
                    );
                    _loadItems();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save groceries: $e')),
                    );
                  }
                }
                : null,
        child: Text(
          'SAVE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                inventory.hasUnsyncedItems || inventory.hasDeletion
                    ? Colors.white
                    : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed:
                () => showModalBottomSheet(
                  context: context,
                  builder:
                      (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'Sort Options',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('Recently Added First'),
                            onTap: () {
                              inventory.sortMode = 1;
                              Navigator.pop(ctx);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.sort_by_alpha),
                            title: const Text('Alphabetical Order'),
                            onTap: () {
                              inventory.sortMode = 2;
                              Navigator.pop(ctx);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.category),
                            title: const Text('Group by Category'),
                            onTap: () {
                              inventory.sortMode = 0;
                              Navigator.pop(ctx);
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Restored input row
          _buildInputRow(inventory),

          // Sort selector (if needed)
          _buildSortSelector(),

          // Item list
          Expanded(
            child:
                inventory.items.isEmpty
                    ? const Center(
                      child: Text(
                        'No items in inventory yet',
                        style: TextStyle(color: Color(0xFF333333)),
                      ),
                    )
                    : _buildItemList(inventory),
          ),

          // Restored save button
          _buildSaveButton(inventory),
        ],
      ),
    );
  }
}
