import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

final geminiServiceProvider = Provider((_) => GeminiService());

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are CrisisSync AI — the emergency coordination assistant for hospitality venues. '
        'You help hotel staff manage crises, coordinate responses, and protect guests. '
        'Be concise, calm, and action-oriented. Always prioritise life safety.',
      ),
    );
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    return response.text ?? 'No response from AI.';
  }

  Future<Map<String, dynamic>> triageIncident({
    required String description,
    required String location,
    required String reporterType,
  }) async {
    const schema = '''Respond ONLY with JSON:
{
  "severity": "P0|P1|P2|P3",
  "pa_draft": "short PA announcement",
  "immediate_actions": ["action1"],
  "staff_needed": ["role1"],
  "emergency_services": []
}''';

    final prompt = '''
Incident: $description
Location: $location
Reporter: $reporterType
$schema''';

    final response = await _model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(temperature: 0.1, maxOutputTokens: 400),
    );

    final text = response.text ?? '{}';
    final clean = text.replaceAll(RegExp(r'```json\n?|\n?```'), '').trim();
    return jsonDecode(clean) as Map<String, dynamic>;
  }

  Future<Map<String, String>> translatePA(String text, List<String> langs) async {
    final prompt = '''Translate this emergency PA to: ${langs.join(', ')}.
Keep calm, clear, under 25 words per language.
Original: $text
Respond ONLY with JSON: {"lang_code": "translation"}''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final clean = (response.text ?? '{}').replaceAll(RegExp(r'```json\n?|\n?```'), '').trim();
    return Map<String, String>.from(jsonDecode(clean));
  }
}
