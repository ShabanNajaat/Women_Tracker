import 'dart:convert';

import 'api_service.dart';
import '../models/ama_models.dart';

class AmaService {
  AmaService._();
  static final AmaService instance = AmaService._();

  final ApiService _api = ApiService();

  Future<List<AmaExpert>?> fetchExperts() async {
    final res = await _api.get('/ama/experts');
    if (res.statusCode != 200) return null;
    try {
      final data = jsonDecode(res.body);
      if (data is! List) return null;
      return data
          .map((e) => AmaExpert.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<AmaSession>?> fetchSessions({String? status}) async {
    final path = status != null ? '/ama/sessions?status=$status' : '/ama/sessions';
    final res = await _api.get(path);
    if (res.statusCode != 200) return null;
    try {
      final data = jsonDecode(res.body);
      if (data is! List) return null;
      return data
          .map((e) => AmaSession.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<AmaSessionDetail?> fetchSession(String id) async {
    final res = await _api.get('/ama/sessions/$id');
    if (res.statusCode != 200) return null;
    try {
      final m = jsonDecode(res.body);
      if (m is! Map) return null;
      return AmaSessionDetail.fromJson(Map<String, dynamic>.from(m));
    } catch (_) {
      return null;
    }
  }

  Future<List<AmaQuestion>?> fetchQuestions(String sessionId, {bool recent = false}) async {
    final sort = recent ? 'recent' : 'top';
    final res = await _api.get('/ama/sessions/$sessionId/questions?sort=$sort');
    if (res.statusCode != 200) return null;
    try {
      final data = jsonDecode(res.body);
      if (data is! List) return null;
      return data
          .map((e) => AmaQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<AmaQuestion?> askQuestion({
    required String sessionId,
    required String body,
    bool anonymous = false,
  }) async {
    final res = await _api.post('/ama/sessions/$sessionId/questions', body: {
      'body': body,
      if (anonymous) 'anonymous': true,
    });
    if (res.statusCode != 201 && res.statusCode != 200) return null;
    try {
      final m = jsonDecode(res.body);
      if (m is! Map) return null;
      return AmaQuestion.fromJson(Map<String, dynamic>.from(m));
    } catch (_) {
      return null;
    }
  }

  Future<AmaQuestion?> upvote(String questionId) async {
    final res = await _api.post('/ama/questions/$questionId/upvote', body: {});
    if (res.statusCode != 200) return null;
    try {
      final m = jsonDecode(res.body);
      if (m is! Map) return null;
      return AmaQuestion.fromJson(Map<String, dynamic>.from(m));
    } catch (_) {
      return null;
    }
  }
}
