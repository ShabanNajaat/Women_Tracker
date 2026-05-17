/// Partner accountability streak snapshot from `/api/partner/streak`.
class PartnerStreakSnapshot {
  const PartnerStreakSnapshot({
    required this.linked,
    this.inviteCode,
    this.partnerName,
    required this.myStreak,
    required this.myLongest,
    required this.myCheckedInToday,
    this.partnerStreak = 0,
    this.partnerLongest = 0,
    this.partnerCheckedInToday = false,
    this.bothCheckedInToday = false,
    this.pendingNudgeFrom,
    this.pendingNudgeMessage,
  });

  final bool linked;
  final String? inviteCode;
  final String? partnerName;
  final int myStreak;
  final int myLongest;
  final bool myCheckedInToday;
  final int partnerStreak;
  final int partnerLongest;
  final bool partnerCheckedInToday;
  final bool bothCheckedInToday;
  final String? pendingNudgeFrom;
  final String? pendingNudgeMessage;

  factory PartnerStreakSnapshot.fromJson(Map<String, dynamic> json) {
    final me = json['me'];
    final partner = json['partner'];
    final nudge = json['pendingNudge'];

    Map<String, dynamic>? meMap;
    Map<String, dynamic>? partnerMap;
    Map<String, dynamic>? nudgeMap;
    if (me is Map) meMap = Map<String, dynamic>.from(me);
    if (partner is Map) partnerMap = Map<String, dynamic>.from(partner);
    if (nudge is Map) nudgeMap = Map<String, dynamic>.from(nudge);

    return PartnerStreakSnapshot(
      linked: json['linked'] == true,
      inviteCode: json['inviteCode']?.toString(),
      partnerName: json['partnerName']?.toString(),
      myStreak: (meMap?['streak'] as num?)?.toInt() ?? 0,
      myLongest: (meMap?['longest'] as num?)?.toInt() ?? 0,
      myCheckedInToday: meMap?['checkedInToday'] == true,
      partnerStreak: (partnerMap?['streak'] as num?)?.toInt() ?? 0,
      partnerLongest: (partnerMap?['longest'] as num?)?.toInt() ?? 0,
      partnerCheckedInToday: partnerMap?['checkedInToday'] == true,
      bothCheckedInToday: json['bothCheckedInToday'] == true,
      pendingNudgeFrom: nudgeMap?['fromName']?.toString(),
      pendingNudgeMessage: nudgeMap?['message']?.toString(),
    );
  }
}
