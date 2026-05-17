import 'dart:convert';
import 'api_service.dart';

/// Result of a Dr. Najaat chat request to `POST /api/chat`.
class LlmReply {
  final String text;
  final bool isError;
  /// Non-fatal notice from the server (e.g. offline/snippets mode).
  final String? infoNotice;

  const LlmReply(this.text, {this.isError = false, this.infoNotice});
}

class ServerLLMService {
  final ApiService _api = ApiService();

  Future<LlmReply> getResponse(String prompt) async {
    try {
      final res = await _api.post('/chat', body: {'role': 'user', 'text': prompt});
      if (res.statusCode == 401) {
        return const LlmReply(
          'Your session expired. Sign out and sign in again to keep chatting.',
          isError: true,
        );
      }
      if (res.statusCode == 200) {
        try {
          final data = jsonDecode(res.body);
          if (data is Map) {
            final ai = data['aiResponse'];
            if (ai != null && ai.toString().trim().isNotEmpty) {
              final notice = data['aiNotice']?.toString();
              final warn = data['aiWarning']?.toString();
              final bits = <String>[
                if (notice != null && notice.isNotEmpty) notice,
                if (warn != null && warn.isNotEmpty) warn,
              ];
              return LlmReply(
                ai.toString().trim(),
                infoNotice: bits.isEmpty ? null : bits.join(' '),
              );
            }
          }
        } on FormatException {
          return const LlmReply('The server sent an unreadable response.', isError: true);
        }
        return const LlmReply('No reply from Dr. Najaat. Try again in a moment.', isError: true);
      }
      return LlmReply(
        'Chat returned HTTP ${res.statusCode}. '
        'Confirm the API is reachable at ${_api.baseUrl} (CORS for web, correct API_BASE_URL on device).',
        isError: true,
      );
    } catch (_) {
      return const LlmReply(
        'Could not reach the wellness server. Check that the API is running and API_BASE_URL is correct for this device.',
        isError: true,
      );
    }
  }
}
