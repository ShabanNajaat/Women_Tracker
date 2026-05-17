class AmaExpert {
  const AmaExpert({
    required this.id,
    required this.slug,
    required this.name,
    required this.title,
    required this.bio,
    required this.credentials,
  });

  final String id;
  final String slug;
  final String name;
  final String title;
  final String bio;
  final String credentials;

  factory AmaExpert.fromJson(Map<String, dynamic> m) {
    return AmaExpert(
      id: m['id']?.toString() ?? '',
      slug: m['slug']?.toString() ?? '',
      name: m['name']?.toString() ?? 'Expert',
      title: m['title']?.toString() ?? '',
      bio: m['bio']?.toString() ?? '',
      credentials: m['credentials']?.toString() ?? '',
    );
  }
}

class AmaSession {
  const AmaSession({
    required this.id,
    required this.expertSlug,
    required this.title,
    required this.description,
    required this.topics,
    required this.status,
    required this.startsAtMs,
    required this.endsAtMs,
    required this.questionCount,
    required this.answeredCount,
  });

  final String id;
  final String expertSlug;
  final String title;
  final String description;
  final List<String> topics;
  final String status;
  final int startsAtMs;
  final int endsAtMs;
  final int questionCount;
  final int answeredCount;

  bool get isLive => status == 'live';
  bool get isEnded => status == 'ended';

  factory AmaSession.fromJson(Map<String, dynamic> m) {
    List<String> topics = [];
    final raw = m['topics'];
    if (raw is List) topics = raw.map((e) => e.toString()).toList();

    return AmaSession(
      id: m['id']?.toString() ?? '',
      expertSlug: m['expertSlug']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      description: m['description']?.toString() ?? '',
      topics: topics,
      status: m['status']?.toString() ?? 'scheduled',
      startsAtMs: _parseMs(m['startsAt']),
      endsAtMs: _parseMs(m['endsAt']),
      questionCount: (m['questionCount'] as num?)?.toInt() ?? 0,
      answeredCount: (m['answeredCount'] as num?)?.toInt() ?? 0,
    );
  }

  static int _parseMs(dynamic v) {
    if (v == null) return 0;
    if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
    return 0;
  }
}

class AmaQuestion {
  const AmaQuestion({
    required this.id,
    required this.sessionId,
    required this.authorName,
    required this.body,
    required this.status,
    required this.answer,
    required this.upvoteCount,
    required this.createdAtMs,
  });

  final String id;
  final String sessionId;
  final String authorName;
  final String body;
  final String status;
  final String answer;
  final int upvoteCount;
  final int createdAtMs;

  bool get isAnswered => status == 'answered' && answer.isNotEmpty;

  factory AmaQuestion.fromJson(Map<String, dynamic> m) {
    return AmaQuestion(
      id: m['id']?.toString() ?? '',
      sessionId: m['sessionId']?.toString() ?? '',
      authorName: m['authorName']?.toString() ?? 'Member',
      body: m['body']?.toString() ?? '',
      status: m['status']?.toString() ?? 'pending',
      answer: m['answer']?.toString() ?? '',
      upvoteCount: (m['upvoteCount'] as num?)?.toInt() ?? 0,
      createdAtMs: AmaSession._parseMs(m['createdAt']),
    );
  }
}

class AmaSessionDetail {
  const AmaSessionDetail({required this.session, this.expert});

  final AmaSession session;
  final AmaExpert? expert;

  factory AmaSessionDetail.fromJson(Map<String, dynamic> m) {
    final sessionMap = m['session'];
    final expertMap = m['expert'];
    return AmaSessionDetail(
      session: sessionMap is Map
          ? AmaSession.fromJson(Map<String, dynamic>.from(sessionMap))
          : AmaSession.fromJson(Map<String, dynamic>.from(m)),
      expert: expertMap is Map ? AmaExpert.fromJson(Map<String, dynamic>.from(expertMap)) : null,
    );
  }
}
