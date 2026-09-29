class Garment {
  final String id;
  final String imageUrl;
  final String category; // Tops, Bottoms, Outerwear, Shoes
  final String color;
  final List<String> styleTags;

  const Garment({
    required this.id,
    required this.imageUrl,
    required this.category,
    required this.color,
    required this.styleTags,
  });

  factory Garment.fromJson(Map<String, dynamic> json) {
    return Garment(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      color: json['color'] as String,
      styleTags: List<String>.from(json['styleTags'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'category': category,
      'color': color,
      'styleTags': styleTags,
    };
  }
}
