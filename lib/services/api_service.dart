import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/garment.dart';

class ApiService {
  // Pointing to your live production backend on Render!
  final String baseUrl = 'https://ai-outfit-matcher.onrender.com';

  Future<List<Garment>> fetchWardrobe() async {
    final response = await http.get(Uri.parse('$baseUrl/wardrobe'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Garment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load wardrobe');
    }
  }

  Future<List<Garment>> getAiRecommendations(Garment baseItem) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommendations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(baseItem.toJson()),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Garment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get AI recommendations: ${response.statusCode}');
    }
  }

  Future<void> uploadGarment(Garment garment, bool removeBackground) async {
    final response = await http.post(
      Uri.parse('$baseUrl/upload'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(garment.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload garment');
    }
  }

  Future<String> analyzeGarment(String imageBase64) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_base64': imageBase64}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['suggestion'];
    } else {
      throw Exception('Failed to get AI analysis: ${response.body}');
    }
  }
}
