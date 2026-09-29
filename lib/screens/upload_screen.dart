import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../providers/wardrobe_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  bool _isLoading = false;
  File? _imageFile;
  Uint8List? _webImage;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 60,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (kIsWeb) {
        setState(() => _webImage = bytes);
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImage = bytes;
        });
      }
    }
  }

  Future<void> _analyzeGarment() async {
    if (_webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image first')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final base64String = base64Encode(_webImage!);
      final dataUri = 'data:image/jpeg;base64,$base64String';
      
      final suggestion = await ref.read(apiServiceProvider).analyzeGarment(dataUri);
      
      if (mounted) {
        _showResultSheet(suggestion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResultSheet(String markdownText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'AI Styling Suggestions',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Markdown(
                    controller: scrollController,
                    data: markdownText,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                      h2: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 20),
                      h3: const TextStyle(color: Color(0xFFB026FF), fontWeight: FontWeight.bold, fontSize: 18),
                      p: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                      listBullet: const TextStyle(color: Color(0xFFB026FF)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Awesome!'),
                    ),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _imageFile != null || _webImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Stylist', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload a piece of clothing and our AI will suggest exactly what to wear with it.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Image Picker Area
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: hasImage ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha: 0.3), 
                    width: hasImage ? 4 : 2
                  ),
                  boxShadow: hasImage ? [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.4), blurRadius: 20)] : [],
                  image: hasImage ? DecorationImage(
                    fit: BoxFit.cover,
                    image: kIsWeb ? MemoryImage(_webImage!) as ImageProvider : FileImage(_imageFile!),
                  ) : null,
                ),
                child: hasImage ? null : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_a_photo_rounded, size: 48, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 24),
                    const Text('Tap to upload a photo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeGarment,
              icon: _isLoading ? const SizedBox() : const Icon(Icons.auto_awesome, size: 28),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              label: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Style This Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
