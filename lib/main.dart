import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';  // Import the services package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio File Picker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AudioFilePicker(),
    );
  }
}

class AudioFilePicker extends StatefulWidget {
  @override
  _AudioFilePickerState createState() => _AudioFilePickerState();
}

class _AudioFilePickerState extends State<AudioFilePicker> {
  List<FileSystemEntity> _audioFiles = [];
  String _selectedDirectory = '/storage/AA40-DD04/RECORD'; // Default fixed directory path

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      print('Manage External Storage permission granted');
    } else {
      print('Manage External Storage permission denied');
    }
  }

  Future<void> _pickDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      setState(() {
        print('::::::::::::::::::::::::::::::Directory: $_selectedDirectory');
        _selectedDirectory = directory;
      });
    }
  }

  Future<void> _fetchAudioFiles() async {
    final directory = Directory(_selectedDirectory);
    if (directory.existsSync()) {
      final files = directory.listSync();
      print('Files in directory:');
      for (var file in files) {
        print('File: ${file.path}');  // Log the file path
      }

      final audioFiles = files.where((file) {
        final extension = file.path.split('.').last.toLowerCase();
        return ['mp3', 'wav', 'aac'].contains(extension);
      }).toList();

      print('Audio Files: ${audioFiles.length}');
      setState(() {
        _audioFiles = audioFiles;
      });
    } else {
      print('Directory does not exist');
    }
  }

  // Function to copy the selected directory to clipboard
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _selectedDirectory));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Directory path copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Directory Picker'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickDirectory,
            child: Text('Pick Directory'),
          ),
          SizedBox(height: 20),
          // Display the selected directory
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected Directory: $_selectedDirectory',
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: _copyToClipboard,  // Copy path to clipboard
                ),
              ],
            ),
          ),
          // Button to fetch audio files from the selected directory
          ElevatedButton(
            onPressed: _fetchAudioFiles,
            child: Text('Fetch Audio Files'),
          ),
          Expanded(
            child: _audioFiles.isEmpty
                ? Center(child: Text('No audio files found.'))
                : ListView.builder(
              itemCount: _audioFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_audioFiles[index].path.split('/').last),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
