import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/garment.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final wardrobeProvider = FutureProvider<List<Garment>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchWardrobe();
});

final aiRecommendationsProvider = FutureProvider.family<List<Garment>, Garment>((ref, baseItem) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getAiRecommendations(baseItem);
});
