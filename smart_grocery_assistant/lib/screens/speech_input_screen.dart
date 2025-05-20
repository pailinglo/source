import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechInputScreen extends StatefulWidget {
  final Function(List<String>) onItemsConfirmed;

  const SpeechInputScreen({super.key, required this.onItemsConfirmed});

  @override
  _SpeechInputScreenState createState() => _SpeechInputScreenState();
}

class _SpeechInputScreenState extends State<SpeechInputScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final List<String> _recognizedItems = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  void _startListening() async {
    if (_isListening) return;

    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (mounted) {
          setState(() {
            _isListening = status == 'listening';
          });
          if (status == 'done' ||
              status == 'notListening' ||
              status == 'noSpeech') {
            setState(() => _isListening = false);
            if (status == 'noSpeech') {
              _showNoSpeechDetectedWarning();
            }
          }
        }
      },
      onError: (errorNotification) {
        _handleSpeechError(errorNotification.errorMsg);
      },
    );

    if (!available) {
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available.')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isListening = true;
        _textController.clear();
      });
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _textController.text = result.recognizedWords;
            // Reset listening state based on actual recognition
            _isListening = !result.finalResult;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        localeId: 'en_US',
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        _handleSpeechError(e.toString());
      }
    }
  }

  void _handleSpeechStatus(String status) {
    print('Speech status: $status');
    if (mounted) {
      setState(() {
        _isListening = status == 'listening';
      });

      if (status == 'done' || status == 'notListening') {
        _stopListening();
      } else if (status == 'noSpeech') {
        _showNoSpeechDetectedWarning();
      }
    }
  }

  void _handleSpeechError(String errorMsg) {
    if (mounted) {
      setState(() => _isListening = false);
      if (errorMsg.contains('203') || errorMsg.contains('noSpeech')) {
        _showNoSpeechDetectedWarning();
      } else if (errorMsg.contains('permission')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $errorMsg')));
      }
    }
  }

  void _showNoSpeechDetectedWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No speech detected. Tap the mic to try again.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
        if (_textController.text.trim().isNotEmpty) {
          _recognizedItems.add(_textController.text.trim());
          _textController.clear();
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error stopping speech: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping speech: ${e.toString()}')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _confirmAndAddItems() {
    Navigator.pop(context, _recognizedItems);
  }

  void _editItem(int index) {
    final controller = TextEditingController(text: _recognizedItems[index]);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Item'),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(
                    () => _recognizedItems[index] = controller.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _removeItem(int index) {
    setState(() => _recognizedItems.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Items by Voice'),
        actions: [
          if (_recognizedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmAndAddItems,
              tooltip: 'Add Items',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _recognizedItems.length + 1,
              itemBuilder: (context, index) {
                if (index < _recognizedItems.length) {
                  return Dismissible(
                    key: ValueKey('$index-${_recognizedItems[index]}'),
                    background: Container(color: Colors.red),
                    onDismissed: (_) => _removeItem(index),
                    child: ListTile(
                      title: Text(
                        _recognizedItems[index],
                        style: const TextStyle(fontSize: 20),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editItem(index),
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText:
                            _isListening
                                ? 'Listening... (say "done" when finished)'
                                : 'Tap mic to speak',
                        border: const OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 20),
                      maxLines: 3,
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: FloatingActionButton(
              backgroundColor:
                  _isListening ? Colors.red : Theme.of(context).primaryColor,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic, size: 36),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose(); // Only call this once
  }
}
