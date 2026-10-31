import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends Groq chat-completion requests through the `groq-proxy` edge function,
/// so the Groq API key stays on the server. Returns an [http.Response] shaped like
/// Groq's own response, so callers keep their existing parsing.
class GroqProxy {
  static Future<http.Response> chatCompletions(Map<String, dynamic> body) async {
    final response = await Supabase.instance.client.functions.invoke('groq-proxy', body: body);
    final data = response.data is String ? response.data as String : jsonEncode(response.data);
    return http.Response(data, response.status, headers: {'content-type': 'application/json'});
  }
}
