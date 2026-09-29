import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../models/garment.dart';
import '../providers/wardrobe_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  String _selectedCategory = 'Tops';
  String _selectedColor = 'Black';
  String _formality = 'Casual';
  bool _removeBackground = true;
  bool _isLoading = false;
  
  File? _imageFile;
  Uint8List? _webImage;
  final _picker = ImagePicker();

  // TODO: Replace with your actual Cloudinary Cloud Name!
  final String _cloudName = 'YOUR_CLOUD_NAME'; 

  final _categories = ['Tops', 'Bottoms', 'Outerwear', 'Shoes', 'Accessories'];
  final _colors = ['Black', 'White', 'Gray', 'Blue', 'Red', 'Green'];
  final _formalities = ['Casual', 'Smart Casual', 'Business', 'Formal'];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _imageFile = File(pickedFile.path));
      }
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_imageFile == null && _webImage == null) return null;
    
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    var request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = 'outfit_uploads';
    
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('file', _webImage!, filename: 'upload.jpg'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
    }
    
    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return json.decode(resBody)['secure_url'];
    } else {
      throw Exception('Cloudinary Error: $resBody');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _imageFile != null || _webImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Garment', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Area
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasImage ? Colors.transparent : Theme.of(context).primaryColor.withValues(alpha: 0.3), 
                    width: 2
                  ),
                  image: hasImage ? DecorationImage(
                    fit: BoxFit.cover,
                    image: kIsWeb ? MemoryImage(_webImage!) as ImageProvider : FileImage(_imageFile!),
                  ) : null,
                ),
                child: hasImage ? null : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt_rounded, size: 40, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tap to upload a photo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('PNG or JPG (max. 5MB)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildDropdown('Category', _categories, _selectedCategory, (val) => setState(() => _selectedCategory = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Primary Color', _colors, _selectedColor, (val) => setState(() => _selectedColor = val!)),
            const SizedBox(height: 16),
            _buildDropdown('Style', _formalities, _formality, (val) => setState(() => _formality = val!)),
            
            const SizedBox(height: 24),
            
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text('Remove Background ✨', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('AI will automatically isolate the garment', style: TextStyle(fontSize: 12)),
                activeColor: Theme.of(context).primaryColor,
                value: _removeBackground,
                onChanged: (val) => setState(() => _removeBackground = val),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadGarment,
              child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Garment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(labelText: label),
      dropdownColor: Theme.of(context).colorScheme.surface,
      items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _uploadGarment() async {
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image first')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final imageUrl = await _uploadToCloudinary();
      if (imageUrl == null) throw Exception("Failed to upload image to Cloudinary");

      final newGarment = Garment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: imageUrl, 
        category: _selectedCategory,
        color: _selectedColor,
        styleTags: [_formality],
      );

      await ref.read(apiServiceProvider).uploadGarment(newGarment, _removeBackground);
      ref.invalidate(wardrobeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Garment added successfully!'),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
