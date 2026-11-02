import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'groq_proxy.dart';

/// One day of a generated trip plan.
class TripPlanDay {
  final String title;
  final List<String> activities;

  const TripPlanDay({required this.title, required this.activities});
}

/// A traveller-facing trip plan, with picks from PassionRide's own listings.
class TripPlan {
  final String title;
  final String summary;
  final List<TripPlanDay> days;
  final List<String> tips;
  final String estimatedBudget;
  final List<Vehicle> vehicles;
  final List<Hotel> hotels;
  final List<Tour> tours;

  /// True when the plan came from the AI; false for the offline fallback.
  final bool fromAi;

  const TripPlan({
    required this.title,
    required this.summary,
    required this.days,
    required this.tips,
    required this.estimatedBudget,
    required this.vehicles,
    required this.hotels,
    required this.tours,
    required this.fromAi,
  });
}

/// Builds trip plans with Groq (via the `groq-proxy` edge function), grounded in
/// the listings currently loaded in the app. Falls back to a simple local plan.
class TripPlannerService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _maxPerType = 25;

  static Future<TripPlan> plan({
    required String destination,
    required int days,
    required String budget,
    required int travellers,
    required List<String> interests,
    required List<Vehicle> vehicles,
    required List<Hotel> hotels,
    required List<Tour> tours,
  }) async {
    final dest = destination.trim();
    final v = _rank(vehicles, dest, (x) => '${x.location} ${x.title}');
    final h = _rank(hotels, dest, (x) => '${x.location} ${x.address} ${x.name}');
    final t = _rank(tours, dest, (x) => '${x.location} ${x.title} ${x.waypoints.join(' ')}');

    try {
      final catalog = {
        'vehicles': v
            .map((x) => {
                  'id': x.id,
                  'name': x.title,
                  'type': x.category,
                  'location': x.location,
                  'pricePerDay': x.pricePerDay,
                })
            .toList(),
        'stays': h
            .map((x) => {
                  'id': x.id,
                  'name': x.name,
                  'location': x.location,
                  'pricePerNight': x.pricePerNight,
                  'maxGuests': x.maxGuests,
                })
            .toList(),
        'tours': t
            .map((x) => {
                  'id': x.id,
                  'name': x.title,
                  'location': x.location,
                  'duration': x.duration,
                  'price': x.price,
                })
            .toList(),
      };

      final userPrompt = '''
Plan a $days-day trip to "$dest" for $travellers traveller(s).
Budget: $budget. Interests: ${interests.isEmpty ? 'general sightseeing' : interests.join(', ')}.
Prices are in Indian Rupees (INR).

Available PassionRide listings (only recommend ids from this list, and only if they are near the destination or on the way):
${jsonEncode(catalog)}

Respond ONLY with JSON in this schema:
{
  "title": "short catchy trip title",
  "summary": "2-3 sentence overview",
  "days": [{"title": "Day 1: ...", "activities": ["Morning: ...", "Afternoon: ...", "Evening: ..."]}],
  "tips": ["practical local tip", "..."],
  "estimatedBudget": "e.g. ₹12,000 - ₹15,000 total for all travellers",
  "vehicleIds": ["id"],
  "stayIds": ["id"],
  "tourIds": ["id"]
}
Give exactly $days entries in "days". Keep each activity under 20 words.''';

      final response = await GroqProxy.chatCompletions({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are the PassionRide AI Trip Planner, an expert Indian travel guide for road trips, bike rentals, homestays and guided tours. Always reply with valid JSON only.',
          },
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
        'max_tokens': 2048,
        'response_format': {'type': 'json_object'},
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (body['choices'] as List).first['message']['content'] as String;
        final json = jsonDecode(content) as Map<String, dynamic>;

        List<String> strings(dynamic x) => (x is List) ? x.map((e) => e.toString()).toList() : <String>[];
        List<T> pick<T>(List<T> pool, dynamic ids, String Function(T) id) {
          final wanted = strings(ids).toSet();
          return pool.where((e) => wanted.contains(id(e))).toList();
        }

        final planDays = (json['days'] as List? ?? [])
            .whereType<Map>()
            .map((d) => TripPlanDay(
                  title: d['title']?.toString() ?? '',
                  activities: strings(d['activities']),
                ))
            .toList();

        if (planDays.isNotEmpty) {
          return TripPlan(
            title: json['title']?.toString() ?? '$days days in $dest',
            summary: json['summary']?.toString() ?? '',
            days: planDays,
            tips: strings(json['tips']),
            estimatedBudget: json['estimatedBudget']?.toString() ?? '',
            vehicles: pick(v, json['vehicleIds'], (x) => x.id),
            hotels: pick(h, json['stayIds'], (x) => x.id),
            tours: pick(t, json['tourIds'], (x) => x.id),
            fromAi: true,
          );
        }
      } else {
        debugPrint('Trip planner AI error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Trip planner AI failed: $e');
    }

    return _fallback(dest, days, budget, v, h, t);
  }

  /// Listings mentioning the destination first, then the rest; capped for the prompt.
  static List<T> _rank<T>(List<T> items, String dest, String Function(T) text) {
    final words = dest.toLowerCase().split(RegExp(r'[\s,]+')).where((w) => w.length > 2).toList();
    int score(T x) {
      final s = text(x).toLowerCase();
      return words.where(s.contains).length;
    }

    final sorted = [...items]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted.take(_maxPerType).toList();
  }

  static TripPlan _fallback(
    String dest,
    int days,
    String budget,
    List<Vehicle> v,
    List<Hotel> h,
    List<Tour> t,
  ) {
    final place = dest.isEmpty ? 'your destination' : dest;
    return TripPlan(
      title: '$days days in $place',
      summary:
          'A simple $budget-friendly outline for $place. Our AI planner is unavailable right now, so here is a starter plan with listings that match your destination.',
      days: List.generate(days, (i) {
        if (i == 0) {
          return TripPlanDay(title: 'Day 1: Arrive & settle in', activities: [
            'Pick up your ride and check in to your stay',
            'Explore the local market and try regional food',
          ]);
        }
        if (i == days - 1) {
          return TripPlanDay(title: 'Day ${i + 1}: Wrap up', activities: [
            'Relaxed breakfast and last-minute shopping',
            'Return your ride and head home',
          ]);
        }
        return TripPlanDay(title: 'Day ${i + 1}: Explore $place', activities: [
          'Morning ride to a nearby viewpoint or landmark',
          'Afternoon guided tour or local experience',
          'Sunset spot and dinner',
        ]);
      }),
      tips: const ['Carry your driving licence and Aadhaar for bike rentals', 'Book stays early on weekends'],
      estimatedBudget: '',
      vehicles: v.take(3).toList(),
      hotels: h.take(3).toList(),
      tours: t.take(3).toList(),
      fromAi: false,
    );
  }
}
