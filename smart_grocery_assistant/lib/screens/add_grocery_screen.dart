import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:camera/camera.dart';
import '../models/inventory_model.dart';
import 'scan_receipt_screen.dart';

class AddGroceryScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AddGroceryScreen({super.key, required this.cameras});

  @override
  _AddGroceryScreenState createState() => _AddGroceryScreenState();
}

class _AddGroceryScreenState extends State<AddGroceryScreen> {
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';
  String _lastAdded = ''; // Track last added item to filter new input

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _addItem(InventoryModel inventory) {
    if (_controller.text.isNotEmpty) {
      String item = _controller.text.trim();
      print('Adding item: $item');
      inventory.addItem(item);
      _lastAdded = item; // Store for filtering next input
      _voiceInput = '';
      _controller.clear();
      setState(() {});
      print('Cleared input, last added: $_lastAdded');
    }
  }

  void _startListening() async {
    if (_isListening) {
      // Already listening, no need to restart
      return;
    }

    print('Starting speech recognition');
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition failed: $error')),
        );
      },
    );
    if (available) {
      setState(() => _isListening = true);
      _voiceInput = '';
      _lastAdded = '';
      _controller.clear();
      _speech.listen(
        onResult: (result) {
          setState(() {
            String recognized = result.recognizedWords;
            // Show only new words since last added item
            if (_lastAdded.isNotEmpty && recognized.startsWith(_lastAdded)) {
              _voiceInput = recognized.substring(_lastAdded.length).trim();
            } else {
              _voiceInput = recognized;
            }
            _controller.text = _voiceInput;
            print('Recognized: $recognized, Displayed: $_voiceInput');
          });
        },
        listenFor: Duration(seconds: 60), // Longer session for multiple items
        pauseFor: Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
      );
    } else {
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition not available. Please enable microphone and speech permissions.',
          ),
        ),
      );
    }
  }

  void _stopListening() {
    print('Stopping speech recognition, current input: $_voiceInput');
    _speech.stop();
    _speech.cancel();
    setState(() => _isListening = false);
    if (_voiceInput.isNotEmpty) {
      final inventory = Provider.of<InventoryModel>(context, listen: false);
      inventory.addItem(_voiceInput.trim());
      _lastAdded = _voiceInput.trim();
      _voiceInput = '';
      _controller.clear();
      print('Added item on stop: $_lastAdded');
    }
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
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Groceries',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Padding(
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
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                  tooltip: _isListening ? 'Stop Listening' : 'Voice Input',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.grey),
                  onPressed: _navigateToScan,
                  tooltip: 'Scan Receipt',
                ),
              ],
            ),
          ),
          Expanded(
            child:
                inventory.items.isEmpty
                    ? const Center(
                      child: Text(
                        'No items in inventory yet',
                        style: TextStyle(color: Color(0xFF333333)),
                      ),
                    )
                    : ListView.builder(
                      itemCount: inventory.items.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          color: const Color(0xFFEDEDED),
                          child: ListTile(
                            title: Text(
                              inventory.items[index],
                              style: const TextStyle(color: Color(0xFF333333)),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color(0xFFD32323),
                              ),
                              onPressed: () => inventory.removeItem(index),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
