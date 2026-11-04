import 'package:dio/dio.dart';

import '../../domain/enums.dart';

/// Writes words. Never computes numbers; callers pass computed facts in.
abstract interface class AiProvider {
  Future<String> run(AiJobKind kind, Map<String, dynamic> input);
}

/// Pro only. Calls our `ai` Edge Function, which checks Pro status,
/// rate-limits, and holds the Claude API key. Prompts forbid emojis.
class ClaudeProxyProvider implements AiProvider {
  ClaudeProxyProvider({required this.functionsUrl, required this.accessToken, Dio? http})
    : http = http ?? Dio();

  final String functionsUrl;
  final Future<String?> Function() accessToken;
  final Dio http;

  @override
  Future<String> run(AiJobKind kind, Map<String, dynamic> input) async {
    final token = await accessToken();
    if (token == null) throw StateError('Not signed in');
    final res = await http.post<Map<String, dynamic>>(
      '$functionsUrl/ai',
      data: {'kind': kind.name, 'input': input},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return res.data!['text'] as String;
  }
}

/// Free tier and offline fallback: fill-in-the-blank templates on device.
class LocalTemplateProvider implements AiProvider {
  const LocalTemplateProvider();

  @override
  Future<String> run(AiJobKind kind, Map<String, dynamic> input) async {
    final name = input['product'] ?? 'our newest piece';
    final price = input['price'] ?? '';
    final booth = input['booth'] ?? 'our booth';
    return switch (kind) {
      AiJobKind.caption => '$name is here. $price at $booth. Come say hi.',
      AiJobKind.hashtags => '#artistalley #smallbusiness #handmade',
      AiJobKind.eventSummary => input['ruleSummary'] as String? ?? '',
      AiJobKind.restockIdeas => '',
    };
  }
}
