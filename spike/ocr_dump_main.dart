// MyReciBook spike — ML Kit OCR dump (T1 arm B). Throwaway tool, not the app.
//
// Build (~10 min, Claude Code session on the Flutter host, S21 via USB):
//   flutter create ocr_dump && cd ocr_dump
//   flutter pub add google_mlkit_text_recognition image_picker path_provider
//   cp ../spike/ocr_dump_main.dart lib/main.dart      (adjust path as needed)
//   flutter run
//
// Use: tap the button, multi-select the 10 spike screenshots.
// Output: one <name>.txt per image in the app's external files dir.
// Pull them next to the screenshots:
//   adb pull /storage/emulated/0/Android/data/com.example.ocr_dump/files/ ./dumps
//   mv dumps/*.txt spike/screenshots/   (names must be <image-filename>.txt)
// Then: python3 harness.py --mode text
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MaterialApp(home: OcrDumpScreen()));

class OcrDumpScreen extends StatefulWidget {
  const OcrDumpScreen({super.key});
  @override
  State<OcrDumpScreen> createState() => _OcrDumpScreenState();
}

class _OcrDumpScreenState extends State<OcrDumpScreen> {
  final List<String> _log = [];

  Future<void> _run() async {
    final picks = await ImagePicker().pickMultiImage();
    if (picks.isEmpty) return;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final dir = await getExternalStorageDirectory();
    for (final pick in picks) {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(pick.path));
      // Keep block/line structure — the structuring model benefits from grouping.
      final buf = StringBuffer();
      for (final block in result.blocks) {
        for (final line in block.lines) {
          buf.writeln(line.text);
        }
        buf.writeln();
      }
      final file = File('${dir!.path}/${pick.name}.txt');
      await file.writeAsString(buf.toString());
      setState(() => _log.add(
          '${pick.name} → ${result.blocks.length} blocks → ${file.path}'));
    }
    await recognizer.close();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ML Kit OCR dump — T1 arm B')),
        floatingActionButton: FloatingActionButton(
            onPressed: _run, child: const Icon(Icons.image_search)),
        body: _log.isEmpty
            ? const Center(child: Text('Tap the button, pick the 10 screenshots.'))
            : ListView(children: [
                for (final line in _log)
                  ListTile(dense: true, title: Text(line)),
              ]),
      );
}
