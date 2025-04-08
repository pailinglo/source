import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ScanReceiptScreen extends StatefulWidget {
  @override
  _ScanReceiptScreenState createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() {});
  }

  Future<String> _takePicture() async {
    final XFile file = await _controller!.takePicture();
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: Text("Scan Receipt")),
      body: CameraPreview(_controller!),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String imagePath = await _takePicture();
          // Pass to OCR service (Phase 3)
        },
        child: Icon(Icons.camera),
      ),
    );
  }
}
