import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:google_ml_kit/google_ml_kit.dart';

class ScanReceiptScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanReceiptScreen({super.key, required this.cameras});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _controller!.initialize();
    } else {
      _initializeControllerFuture = Future.error('No cameras available');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_controller == null) return;
    try {
      await _initializeControllerFuture;
      final XFile image = await _controller!.takePicture();
      final directory = await getTemporaryDirectory();
      final filePath = path.join(directory.path, '${DateTime.now()}.jpg');
      await image.saveTo(filePath);
      setState(() {
        _imagePath = filePath;
      });
      await _processReceiptImage(filePath);
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<void> _processReceiptImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    String text = recognizedText.text;
    print('Extracted text from receipt: $text');
    List<String> items = _parseReceiptText(text);
    print('Detected grocery items: $items');
    await textRecognizer.close();
  }

  List<String> _parseReceiptText(String text) {
    List<String> items = [];
    List<String> lines = text.split('\n');
    for (String line in lines) {
      if (RegExp(r'\d+\.\d{2}').hasMatch(line)) {
        String item = line.replaceAll(RegExp(r'\s*\d+\.\d{2}'), '').trim();
        if (item.isNotEmpty && !item.toLowerCase().contains('total')) {
          items.add(item);
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          widget.cameras.isEmpty
              ? const Center(
                child: Text(
                  'No camera available on this device',
                  style: TextStyle(color: Color(0xFF333333)),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            !snapshot.hasError) {
                          return CameraPreview(_controller!);
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Color(0xFF333333)),
                            ),
                          );
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  ),
                  if (_imagePath != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        File(_imagePath!),
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _captureImage,
                      child: const Text('Capture Receipt'),
                    ),
                  ),
                ],
              ),
    );
  }
}
