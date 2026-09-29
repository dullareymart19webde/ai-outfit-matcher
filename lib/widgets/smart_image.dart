import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SmartImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        fit: fit,
        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.white24),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24),
    );
  }
}
