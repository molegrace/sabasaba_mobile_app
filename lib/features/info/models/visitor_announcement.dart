part of '../../../main.dart';

class VisitorAnnouncement {
  final String id;
  final String title;
  final String content;
  final String audience;
  final String priority;
  final DateTime createdAt;
  final bool isRead;

  const VisitorAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.audience,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
  });

  VisitorAnnouncement copyWith({bool? isRead}) {
    return VisitorAnnouncement(
      id: id,
      title: title,
      content: content,
      audience: audience,
      priority: priority,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory VisitorAnnouncement.fromJson(
    Map<String, dynamic> json, {
    Set<String>? readIds,
  }) {
    final id = json['id']?.toString() ?? '';
    final title = json['title']?.toString() ?? 'Announcement';
    final content = json['content']?.toString() ?? '';
    final audience = json['audience']?.toString() ?? 'all_users';
    final priority = json['priority']?.toString() ?? 'normal';
    final createdAtStr = json['created_at']?.toString();
    DateTime dt;
    if (createdAtStr != null) {
      dt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }
    return VisitorAnnouncement(
      id: id,
      title: title,
      content: content,
      audience: audience,
      priority: priority,
      createdAt: dt,
      isRead: readIds?.contains(id) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'audience': audience,
    'priority': priority,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isCritical => priority.toLowerCase() == 'critical';
}

class VisitorAnnouncementManager {
  static const String _readIdsKey = 'sabasaba_read_announcement_ids';
  static const String _cachedAnnouncementsKey =
      'sabasaba_cached_announcements';
  static const String _publicApiUrl =
      'https://sabasaba.alphabeti.co.tz/api/v1/announcements/public';

  static Future<Set<String>> getReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_readIdsKey) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readSet = (prefs.getStringList(_readIdsKey) ?? []).toSet();
      readSet.add(id);
      await prefs.setStringList(_readIdsKey, readSet.toList());
    } catch (_) {}
  }

  static Future<void> markAllAsRead(
    List<VisitorAnnouncement> announcements,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readSet = (prefs.getStringList(_readIdsKey) ?? []).toSet();
      for (final a in announcements) {
        readSet.add(a.id);
      }
      await prefs.setStringList(_readIdsKey, readSet.toList());
    } catch (_) {}
  }

  static Future<List<VisitorAnnouncement>> fetchAnnouncements() async {
    final readIds = await getReadIds();
    final prefs = await SharedPreferences.getInstance();

    try {
      final uri = Uri.parse(_publicApiUrl);
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['announcements'] is List) {
          final list =
              (decoded['announcements'] as List)
                  .map(
                    (item) => VisitorAnnouncement.fromJson(
                      item as Map<String, dynamic>,
                      readIds: readIds,
                    ),
                  )
                  .toList();
          await prefs.setString(_cachedAnnouncementsKey, response.body);
          return list;
        }
      }
    } catch (e) {
      // Offline fallback
    }

    final cached = prefs.getString(_cachedAnnouncementsKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = json.decode(cached);
        if (decoded is Map && decoded['announcements'] is List) {
          return (decoded['announcements'] as List)
              .map(
                (item) => VisitorAnnouncement.fromJson(
                  item as Map<String, dynamic>,
                  readIds: readIds,
                ),
              )
              .toList();
        }
      } catch (_) {}
    }

    return const [];
  }
}
