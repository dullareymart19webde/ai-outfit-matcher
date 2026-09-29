import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/wardrobe_provider.dart';
import '../models/garment.dart';

class AIStylistScreen extends ConsumerStatefulWidget {
  const AIStylistScreen({super.key});

  @override
  ConsumerState<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends ConsumerState<AIStylistScreen> {
  Garment? _selectedBaseItem;

  @override
  Widget build(BuildContext context) {
    final wardrobeAsync = ref.watch(wardrobeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Stylist ✨'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF121212), Color(0xFF2A004F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Select base item horizontal list
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            height: 140,
            child: wardrobeAsync.when(
              data: (garments) => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: garments.length,
                itemBuilder: (context, index) {
                  final item = garments[index];
                  final isSelected = _selectedBaseItem?.id == item.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBaseItem = item),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(item.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Center(child: Text('Failed to load wardrobe')),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          
          // AI Results Area
          Expanded(
            child: _selectedBaseItem == null
                ? const Center(
                    child: Text(
                      'Select an item above to get AI matches',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : _BuildMatchesArea(baseItem: _selectedBaseItem!),
          ),
        ],
      ),
    );
  }
}

class _BuildMatchesArea extends ConsumerWidget {
  final Garment baseItem;
  
  const _BuildMatchesArea({required this.baseItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(aiRecommendationsProvider(baseItem));

    return recommendationsAsync.when(
      data: (recommendations) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Perfect Matches',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((item) => Card(
              color: Theme.of(context).colorScheme.surface,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Color: ${item.color}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: item.styleTags.map((t) => Chip(
                              label: Text(t, style: const TextStyle(fontSize: 10)),
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            )).toList(),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.favorite),
                label: const Text('Save Outfit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          ],
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('AI is analyzing your style...', style: TextStyle(color: Theme.of(context).primaryColor)),
          ],
        ),
      ),
      error: (e, s) => const Center(child: Text('Failed to generate matches')),
    );
  }
}
