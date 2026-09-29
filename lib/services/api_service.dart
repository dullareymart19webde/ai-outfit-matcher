import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/garment.dart';

class ApiService {
  // If running on an Android emulator, change this to http://10.0.2.2:8000
  final String baseUrl = 'http://127.0.0.1:8000';

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
}
