import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final _categories = ['Tops', 'Bottoms', 'Outerwear', 'Shoes', 'Accessories'];
  final _colors = ['Black', 'White', 'Gray', 'Blue', 'Red', 'Green'];
  final _formalities = ['Casual', 'Smart Casual', 'Business', 'Formal'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Garment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mock Image Picker Area
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 48, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 12),
                  const Text('Tap to take photo or choose from gallery', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Form Fields
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedColor,
              decoration: const InputDecoration(labelText: 'Primary Color', border: OutlineInputBorder()),
              items: _colors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedColor = val!),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _formality,
              decoration: const InputDecoration(labelText: 'Formality', border: OutlineInputBorder()),
              items: _formalities.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (val) => setState(() => _formality = val!),
            ),
            const SizedBox(height: 24),
            
            // Toggle Switch
            SwitchListTile(
              title: const Text('Remove Background (AI)'),
              subtitle: const Text('Automatically isolate the garment'),
              activeColor: Theme.of(context).primaryColor,
              value: _removeBackground,
              onChanged: (val) => setState(() => _removeBackground = val),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  final newGarment = Garment(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    // Still using a mock image until we implement real camera picking
                    imageUrl: 'https://images.unsplash.com/photo-1572804013309-8c98e2527218?w=500', 
                    category: _selectedCategory,
                    color: _selectedColor,
                    styleTags: [_formality],
                  );

                  await ref.read(apiServiceProvider).uploadGarment(newGarment, _removeBackground);
                  
                  // Refresh dashboard
                  ref.invalidate(wardrobeProvider);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Garment added successfully!')),
                    );
                    context.pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to upload: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Upload Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
