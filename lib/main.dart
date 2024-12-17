import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USB Drive Picker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UsbFilePicker(),
    );
  }
}

class UsbFilePicker extends StatefulWidget {
  @override
  _UsbFilePickerState createState() => _UsbFilePickerState();
}

class _UsbFilePickerState extends State<UsbFilePicker> {
  String? _selectedPath;
  List<String> _audioFiles = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isDenied) {
      print("Storage permission denied!");
    }

    if (Platform.isAndroid && await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        print('Selected Path: $result');
        setState(() {
          _selectedPath = result;
        });
        _listAudioFiles(result);
      } else {
        print('No directory selected');
      }
    } catch (e) {
      print("Error picking directory: $e");
    }
  }

  void _listAudioFiles(String path) async {
    try {
      final directory = Directory(path);
      if (directory.existsSync()) {
        final files = directory.listSync(recursive: true, followLinks: false);
        final audioFiles = files.where((file) {
          final extension = file.path.split('.').last.toLowerCase();
          return ['mp3', 'wav', 'aac'].contains(extension);
        }).map((file) => file.path).toList();

        setState(() {
          _audioFiles = audioFiles;
        });

        print('Audio Files Found: ${audioFiles.length}');
      } else {
        print('Directory does not exist!');
      }
    } catch (e) {
      print('Error listing files: $e');
    }
  }

  void _copyPathToClipboard() {
    if (_selectedPath != null) {
      Clipboard.setData(ClipboardData(text: _selectedPath!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Path copied to clipboard: $_selectedPath')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('USB Drive Picker')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickDirectory,
            child: Text('Pick USB Drive Directory'),
          ),
          if (_selectedPath != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Selected Path: $_selectedPath',
                        style: TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: _copyPathToClipboard,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _listAudioFiles(_selectedPath!),
              child: Text('Fetch Audio Files'),
            ),
          ],
          Expanded(
            child: _audioFiles.isEmpty
                ? Center(child: Text('No audio files found.'))
                : ListView.builder(
              itemCount: _audioFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_audioFiles[index].split('/').last),
                  subtitle: Text(_audioFiles[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
