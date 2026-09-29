import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/wardrobe_provider.dart';
import '../models/garment.dart';
import '../widgets/smart_image.dart';

final selectedBaseItemProvider = StateProvider<Garment?>((ref) => null);

class AIStylistScreen extends ConsumerStatefulWidget {
  const AIStylistScreen({super.key});

  @override
  ConsumerState<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends ConsumerState<AIStylistScreen> {
  @override
  Widget build(BuildContext context) {
    final wardrobeAsync = ref.watch(wardrobeProvider);
    final selectedBaseItem = ref.watch(selectedBaseItemProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AI Stylist', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E0B33), Color(0xFF0D0D14)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text('Select a base item to build your outfit:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              // Base item selector
              SizedBox(
                height: 100,
                child: wardrobeAsync.when(
                  data: (garments) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: garments.length,
                    itemBuilder: (context, index) {
                      final item = garments[index];
                      final isSelected = selectedBaseItem?.id == item.id;
                      return GestureDetector(
                        onTap: () => ref.read(selectedBaseItemProvider.notifier).state = item,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), blurRadius: 10)
                            ] : [],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SmartImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error loading wardrobe: $e')),
                ),
              ),
              const SizedBox(height: 24),
              
              // AI Results Area
              Expanded(
                child: selectedBaseItem == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 64, color: Colors.white24),
                            SizedBox(height: 16),
                            Text(
                              'Waiting for your selection...',
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : _BuildMatchesArea(baseItem: selectedBaseItem),
              ),
            ],
          ),
        ),
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
        if (recommendations.isEmpty) {
          return const Center(child: Text("No perfect matches found in your wardrobe."));
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                const Text(
                  'Perfect Matches',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                    child: SizedBox(
                      width: 120,
                      height: 140,
                      child: SmartImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.category.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('Color: ${item.color}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: item.styleTags.map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(t, style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
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
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.favorite_rounded),
              label: const Text('Save This Outfit'),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 2,
                  ),
                ),
                Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 32),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Gemini is analyzing your style...', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }
}
