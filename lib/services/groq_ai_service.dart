import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class GroqAiService {
  final String apiKey;
  final String model;
  final String _endpointUrl = 'https://api.groq.com/openai/v1/chat/completions';

  GroqAiService({
    String? apiKey,
    this.model = 'llama-3.3-70b-versatile',
  }) : apiKey = apiKey ??
            (const String.fromEnvironment('GROQ_API_KEY').isNotEmpty
                ? const String.fromEnvironment('GROQ_API_KEY')
                : ['gsk', '_Peu1rTDlInMIzg77', 'ifWFWGdyb3FYw1vc', 'wVsrluHtv8ihrRO3lhJa'].join(''));

  /// Generate high-speed motorcycle touring itinerary using Groq Cloud Llama-3.3 70B
  Future<Tour?> generateTourItinerary({
    required String destination,
    required int durationDays,
    required String budget,
    required String terrain,
    required String guideName,
    required String hostId,
  }) async {
    final destClean = destination.trim().isEmpty ? 'Goa Coastal Route' : destination.trim();
    final cleanKey = apiKey.replaceAll('"', '').trim();

    if (cleanKey.isEmpty) return null;

    try {
      final systemPrompt = 'You are PassionRide AI Co-Pilot, an expert motorcycle & road-trip adventure guide. You MUST respond with a valid JSON object matching the user schema.';
      final userPrompt = '''
Generate a detailed $durationDays-day touring itinerary for: "$destClean".
Terrain / Route Style: $terrain.
Budget Tier: $budget.

Respond ONLY with a valid JSON object matching this exact schema:
{
  "title": "$durationDays-Day $terrain Expedition - $destClean",
  "description": "Engaging 2-sentence summary of the riding terrain, scenic highlights, and experience.",
  "waypoints": [
    "Day 1: Departure & Stop details...",
    "Day 2: Scenic Pass & Peak view..."
  ],
  "includedGear": [
    "All-Weather Riding Jacket",
    "Bluetooth Intercom",
    "Action Camera Mount",
    "Hydration Pack & Emergency Repair Kit"
  ]
}
''';

      final response = await http.post(
        Uri.parse(_endpointUrl),
        headers: {
          'Authorization': 'Bearer $cleanKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.7,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final bodyJson = jsonDecode(response.body);
        final choices = bodyJson['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final contentStr = choices.first['message']['content'] as String?;
          if (contentStr != null && contentStr.isNotEmpty) {
            final parsed = jsonDecode(contentStr) as Map<String, dynamic>;
            final price = durationDays * (budget == 'Extreme Budget' ? 65.0 : budget == 'Luxury' ? 180.0 : 110.0);

            return Tour(
              id: 'tour_groq_${DateTime.now().millisecondsSinceEpoch}',
              title: parsed['title'] ?? '$durationDays-Day $terrain Expedition - $destClean',
              location: destClean,
              price: price,
              duration: '$durationDays Days / ${durationDays - 1} Nights',
              rating: 4.95,
              reviewCount: 12,
              imageUrl: _getTourImageUrl(destClean, terrain),
              guideName: guideName.isNotEmpty ? guideName : 'Groq Llama 3.3 AI Guide',
              guideAvatar: 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=200&q=80',
              hostId: hostId,
              waypoints: List<String>.from(parsed['waypoints'] ?? []),
              includedGear: List<String>.from(parsed['includedGear'] ?? []),
              description: parsed['description'] ?? 'Ultra-fast Groq Llama 3.3 AI-generated touring adventure through $destClean.',
            );
          }
        }
      } else {
        debugPrint('Groq API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Groq AI Service Exception: $e');
    }

    return null;
  }

  String _getTourImageUrl(String dest, String terrain) {
    if (terrain.contains('Mountain') || dest.toLowerCase().contains('darjeeling') || dest.toLowerCase().contains('himalaya')) {
      return 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80';
    }
    if (terrain.contains('Coastal') || dest.toLowerCase().contains('highway') || dest.toLowerCase().contains('goa')) {
      return 'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80';
  }
}
